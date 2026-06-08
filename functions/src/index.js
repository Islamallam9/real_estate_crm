const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();
const FieldValue = admin.firestore.FieldValue;


exports.getServerTime = onCall(() => {
  const now = new Date();
  return {
    now: now.toISOString(),
    nowMillis: now.getTime(),
  };
});

exports.getAndroidReleasePolicy = onCall(async (request) => {
  const data = request.data || {};
  const platform = optionalString(data.platform).toLowerCase();
  if (platform !== 'android') {
    return androidReleasePolicyResponse({
      currentBuildNumber: parseBuildNumber(data.buildNumber),
      policy: {},
      serverNow: new Date(),
    });
  }

  const policySnapshot = await db.doc('platform_config/android_release_policy').get();
  const policy = policySnapshot.exists ? policySnapshot.data() || {} : {};
  return androidReleasePolicyResponse({
    currentBuildNumber: parseBuildNumber(data.buildNumber),
    policy,
    serverNow: new Date(),
  });
});

exports.updateAndroidReleasePolicy = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);

  const data = request.data || {};
  const minimumSupportedBuildNumber = parseBuildNumber(
    data.minimumSupportedBuildNumber ?? data.minSupportedBuildNumber,
  );
  const latestBuildNumber = parseBuildNumber(data.latestBuildNumber);
  const updateUrl = optionalString(data.updateUrl);
  const appVersion = sanitizeShortString(data.appVersion, 40);

  if (minimumSupportedBuildNumber <= 0 || latestBuildNumber <= 0) {
    throw new HttpsError('invalid-argument', 'Build numbers must be positive whole numbers.');
  }
  if (latestBuildNumber < minimumSupportedBuildNumber) {
    throw new HttpsError('invalid-argument', 'Latest build must be equal to or higher than the minimum supported build.');
  }
  if (data.releaseReady === true && updateUrl.length === 0) {
    throw new HttpsError('invalid-argument', 'An update URL is required before marking the release as ready.');
  }

  const policyPayload = {
    enabled: data.enabled === true,
    releaseReady: data.releaseReady === true,
    minimumSupportedBuildNumber,
    latestBuildNumber,
    appVersion,
    updateUrl,
    titleEn: sanitizeShortString(data.titleEn, 120),
    titleAr: sanitizeShortString(data.titleAr, 120),
    bodyEn: sanitizeShortString(data.bodyEn, 500),
    bodyAr: sanitizeShortString(data.bodyAr, 500),
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  };

  await db.doc('platform_config/android_release_policy').set(policyPayload, { merge: true });

  await upsertPlatformReleaseRecord({
    actorUid,
    platform: 'android',
    appVersion,
    buildNumber: latestBuildNumber,
    channel: sanitizeReleaseChannel(data.channel),
    releaseType: sanitizeReleaseType(data.releaseType),
    status: data.enabled === false ? 'disabled' : (data.releaseReady === true ? 'ready' : 'draft'),
    releaseReady: data.releaseReady === true,
    enabled: data.enabled === true,
    minimumSupportedBuildNumber,
    latestBuildNumber,
    updateUrl,
    titleEn: policyPayload.titleEn,
    titleAr: policyPayload.titleAr,
    notesEn: sanitizeShortString(data.notesEn || data.bodyEn, 1000),
    notesAr: sanitizeShortString(data.notesAr || data.bodyAr, 1000),
    apkFileName: releaseApkFileName(updateUrl),
    metadata: {
      source: 'updateAndroidReleasePolicy',
      policyPath: 'platform_config/android_release_policy',
    },
  });

  return { ok: true };
});

exports.registerDeviceInstall = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const data = request.data || {};
  const uid = request.auth.uid;
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const installId = sanitizeInstallId(requiredString(data.installId, 'installId'));
  const platform = sanitizeClientPlatform(data.platform);
  const appVersion = sanitizeShortString(data.appVersion, 40);
  const buildNumber = parseBuildNumber(data.buildNumber);
  if (!appVersion || buildNumber <= 0) {
    throw new HttpsError('invalid-argument', 'A valid app version and build number are required.');
  }

  const [companySnapshot, companyUserSnapshot] = await Promise.all([
    db.doc(`companies/${companyId}`).get(),
    db.doc(`companies/${companyId}/users/${uid}`).get(),
  ]);
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  if (company.isActive !== true || company.status === 'inactive') {
    throw new HttpsError('failed-precondition', 'Company is inactive.');
  }
  if (!companyUserSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Company user was not found.');
  }
  const companyUser = companyUserSnapshot.data() || {};
  if (companyUser.companyId !== companyId || companyUser.isActive !== true) {
    throw new HttpsError('permission-denied', 'Company user is inactive.');
  }

  const installRef = db.doc(`companies/${companyId}/device_installs/${installId}`);
  const existingSnapshot = await installRef.get();
  const existing = existingSnapshot.exists ? existingSnapshot.data() || {} : {};
  const previousAppVersion = optionalString(existing.appVersion);
  const previousBuildNumber = parseBuildNumber(existing.buildNumber);
  const versionChanged = existingSnapshot.exists &&
    (previousAppVersion !== appVersion || previousBuildNumber !== buildNumber);
  const tokenHash = sanitizeHashPrefix(data.tokenHash);
  const now = FieldValue.serverTimestamp();
  const payload = {
    installId,
    uid,
    companyId,
    companyName: sanitizePlainString(optionalString(company.displayName) || optionalString(company.name), 180),
    role: sanitizePlainString(optionalString(companyUser.role), 40),
    fullName: sanitizePlainString(optionalString(companyUser.fullName), 160),
    email: sanitizePlainString(optionalString(companyUser.email), 180),
    platform,
    appVersion,
    buildNumber,
    previousAppVersion: versionChanged ? previousAppVersion : optionalString(existing.previousAppVersion),
    previousBuildNumber: versionChanged ? previousBuildNumber : parseBuildNumber(existing.previousBuildNumber),
    deviceIdHash: installStableHash(installId),
    tokenHash,
    tokenHashPrefix: tokenHash ? tokenHash.slice(0, 12) : '',
    webOrigin: sanitizeShortString(data.webOrigin, 240),
    webHref: sanitizeShortString(data.webHref, 500),
    browser: sanitizeShortString(data.browser, 120),
    os: sanitizeShortString(data.os, 120),
    deviceModel: sanitizeShortString(data.deviceModel, 160),
    locale: sanitizeNotificationTokenLocale(data.locale),
    timezone: sanitizeShortString(data.timezone, 80),
    notificationPermission: sanitizeNotificationPermission(data.notificationPermission),
    notificationTokenStatus: sanitizeNotificationTokenStatus(data.notificationTokenStatus),
    isActive: true,
    updatedAt: now,
    lastSeenAt: now,
    lastSessionAt: now,
    deactivatedAt: null,
    deactivatedReason: '',
  };
  if (!existingSnapshot.exists) {
    payload.createdAt = now;
    payload.firstSeenAt = now;
  }
  if (versionChanged) {
    payload.lastVersionChangeAt = now;
  }

  const batch = db.batch();
  batch.set(installRef, payload, { merge: true });
  if (versionChanged) {
    const eventRef = db.collection(`companies/${companyId}/device_version_events`).doc();
    batch.set(eventRef, {
      eventId: eventRef.id,
      uid,
      companyId,
      companyName: payload.companyName,
      role: payload.role,
      platform,
      installId,
      deviceIdHash: payload.deviceIdHash,
      tokenHash,
      tokenHashPrefix: payload.tokenHashPrefix,
      webOrigin: payload.webOrigin,
      oldVersion: previousAppVersion,
      oldBuildNumber: previousBuildNumber,
      newVersion: appVersion,
      newBuildNumber: buildNumber,
      source: sanitizeVersionEventSource(data.source),
      createdAt: now,
    });
  }
  await batch.commit();

  return { ok: true, installId, versionChanged };
});

exports.recordAppSessionHeartbeat = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }
  const data = request.data || {};
  const uid = request.auth.uid;
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);
  const installId = sanitizeInstallId(requiredString(data.installId, 'installId'));
  const userSnapshot = await db.doc(`companies/${companyId}/users/${uid}`).get();
  if (!userSnapshot.exists || userSnapshot.get('isActive') !== true) {
    throw new HttpsError('permission-denied', 'Company user was not found.');
  }
  await db.doc(`companies/${companyId}/device_installs/${installId}`).set({
    uid,
    companyId,
    installId,
    platform: sanitizeClientPlatform(data.platform),
    appVersion: sanitizeShortString(data.appVersion, 40),
    buildNumber: parseBuildNumber(data.buildNumber),
    lastSeenAt: FieldValue.serverTimestamp(),
    lastSessionAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    isActive: true,
  }, { merge: true });
  return { ok: true };
});

exports.getReleaseIntelligenceSummary = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const activeWithinDays = clampInt(parseBuildNumber((request.data || {}).activeWithinDays), 1, 120, 30);
  const [releases, adoption, devices] = await Promise.all([
    loadPlatformReleases(80),
    buildVersionAdoption({ platform: 'all', companyId: '', activeWithinDays, includeInactive: false }),
    loadDeviceRows({ platform: 'all', companyId: '', activeWithinDays, limit: 5000, includeInactive: false }),
  ]);
  const latestWebRelease = latestReleaseForPlatform(releases, 'web');
  const latestAndroidRelease = latestReleaseForPlatform(releases, 'android');
  const latestWebBuild = Math.max(parseBuildNumber(latestWebRelease && latestWebRelease.latestBuildNumber), parseBuildNumber(latestWebRelease && latestWebRelease.buildNumber));
  const latestAndroidBuild = Math.max(parseBuildNumber(latestAndroidRelease && latestAndroidRelease.latestBuildNumber), parseBuildNumber(latestAndroidRelease && latestAndroidRelease.buildNumber));
  const minimumWebBuild = parseBuildNumber(latestWebRelease && latestWebRelease.minimumSupportedBuildNumber);
  const minimumAndroidBuild = parseBuildNumber(latestAndroidRelease && latestAndroidRelease.minimumSupportedBuildNumber);
  const userKeys = new Set();
  const webUserKeys = new Set();
  const androidUserKeys = new Set();
  let webDevices = 0;
  let androidDevices = 0;
  let oldDevices = 0;
  let belowMinimumDevices = 0;
  let pushConnected = 0;
  let pushBlocked = 0;
  let pushMissing = 0;
  let pushInvalidFailed = 0;
  let pushUnknown = 0;
  devices.forEach((row) => {
    const userKey = `${row.companyId}:${row.uid}`;
    if (row.uid) userKeys.add(userKey);
    const rowBuild = parseBuildNumber(row.buildNumber);
    const latestBuild = row.platform === 'web' ? latestWebBuild : latestAndroidBuild;
    const minimumBuild = row.platform === 'web' ? minimumWebBuild : minimumAndroidBuild;
    if (row.platform === 'web') {
      webDevices += 1;
      if (row.uid) webUserKeys.add(userKey);
    }
    if (row.platform === 'android') {
      androidDevices += 1;
      if (row.uid) androidUserKeys.add(userKey);
    }
    if (latestBuild > 0 && rowBuild > 0 && rowBuild < latestBuild) oldDevices += 1;
    if (minimumBuild > 0 && rowBuild > 0 && rowBuild < minimumBuild) belowMinimumDevices += 1;
    const tokenStatus = optionalString(row.notificationTokenStatus).toLowerCase();
    if (tokenStatus === 'active' || tokenStatus === 'connected') {
      pushConnected += 1;
    } else if (row.notificationPermission === 'denied' || tokenStatus === 'blocked') {
      pushBlocked += 1;
    } else if (tokenStatus === 'missing') {
      pushMissing += 1;
    } else if (tokenStatus === 'invalid' || tokenStatus === 'failed') {
      pushInvalidFailed += 1;
    } else {
      pushUnknown += 1;
    }
  });
  return {
    latestWebRelease,
    latestAndroidRelease,
    activeUsers: userKeys.size,
    activeDevices: devices.length,
    activeWebUsers: webUserKeys.size,
    activeWebDevices: webDevices,
    activeAndroidUsers: androidUserKeys.size,
    activeAndroidDevices: androidDevices,
    usersBelowLatestBuild: adoption.usersBelowLatest,
    devicesBelowLatestBuild: oldDevices,
    usersBelowMinimumBuild: adoption.usersBelowMinimum,
    devicesBelowMinimumBuild: belowMinimumDevices,
    pushHealth: {
      connected: pushConnected,
      blocked: pushBlocked,
      missing: pushMissing,
      invalidFailed: pushInvalidFailed,
      unknown: pushUnknown,
    },
    adoptionRows: adoption.rows,
    recentVersionChanges: await loadVersionEvents({ companyId: '', platform: 'all', limit: 8 }),
    releases,
    lastUpdated: new Date().toISOString(),
  };
});

exports.getPlatformVersionAdoption = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  return buildVersionAdoption({
    platform: sanitizeOptionalPlatformFilter(data.platform),
    companyId: optionalString(data.companyId),
    activeWithinDays: clampInt(parseBuildNumber(data.activeWithinDays), 1, 120, 30),
    includeInactive: data.includeInactive === true,
  });
});

exports.getPlatformDeviceList = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const rows = await loadDeviceRows({
    platform: sanitizeOptionalPlatformFilter(data.platform),
    companyId: optionalString(data.companyId),
    activeWithinDays: clampInt(parseBuildNumber(data.activeWithinDays), 1, 120, 30),
    limit: clampInt(parseBuildNumber(data.limit), 20, 300, 120),
    includeInactive: data.includeInactive === true,
  });
  const version = optionalString(data.version).toLowerCase();
  const role = optionalString(data.role).toLowerCase();
  const notificationStatus = optionalString(data.notificationStatus).toLowerCase();
  const buildNumber = parseBuildNumber(data.buildNumber);
  const filtered = rows.filter((row) => {
    if (version && optionalString(row.appVersion).toLowerCase() !== version) return false;
    if (buildNumber > 0 && parseBuildNumber(row.buildNumber) !== buildNumber) return false;
    if (role && optionalString(row.role).toLowerCase() !== role) return false;
    if (notificationStatus && optionalString(row.notificationTokenStatus).toLowerCase() !== notificationStatus) return false;
    return true;
  });
  return { rows: filtered, hasMore: rows.length > filtered.length, lastUpdated: new Date().toISOString() };
});

exports.createPlatformReleaseRecord = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const platform = sanitizeClientPlatform(data.platform);
  const buildNumber = parseBuildNumber(data.buildNumber);
  if (buildNumber <= 0) {
    throw new HttpsError('invalid-argument', 'Build number must be a positive whole number.');
  }
  const record = await upsertPlatformReleaseRecord({
    actorUid,
    platform,
    appVersion: sanitizeShortString(data.appVersion, 40),
    buildNumber,
    channel: sanitizeReleaseChannel(data.channel),
    releaseType: sanitizeReleaseType(data.releaseType),
    status: sanitizeReleaseStatus(data.status),
    releaseReady: data.releaseReady === true,
    enabled: data.enabled !== false,
    minimumSupportedBuildNumber: parseBuildNumber(data.minimumSupportedBuildNumber),
    latestBuildNumber: parseBuildNumber(data.latestBuildNumber) || buildNumber,
    updateUrl: optionalString(data.updateUrl),
    apkFileName: sanitizeShortString(data.apkFileName, 180),
    notesEn: sanitizeShortString(data.notesEn, 1000),
    notesAr: sanitizeShortString(data.notesAr, 1000),
    metadata: { source: 'createPlatformReleaseRecord' },
  });
  return { ok: true, release: record };
});

exports.getPlatformVersionHistory = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  return {
    rows: await loadVersionEvents({
      companyId: optionalString(data.companyId),
      platform: sanitizeOptionalPlatformFilter(data.platform),
      limit: clampInt(parseBuildNumber(data.limit), 20, 300, 120),
    }),
  };
});


exports.getAndroidVersionAdoption = onCall(async (request) => {
  await requireActivePlatformAdmin(request);

  const data = request.data || {};
  const requestedCompanyId = optionalString(data.companyId);

  try {
    const adoption = await buildVersionAdoption({
      platform: 'android',
      companyId: requestedCompanyId,
      activeWithinDays: clampInt(parseBuildNumber(data.activeWithinDays), 1, 120, 30),
      includeInactive: data.includeInactive === true,
    });
    const rows = adoption.rows.map((row) => ({
      ...row,
      userCount: row.activeUsers,
      deviceCount: row.activeDevices,
      companyCount: row.activeCompanies,
    }));
    return {
      rows,
      versions: rows,
      totalActiveUsers: adoption.totalActiveUsers,
      totalActiveDevices: adoption.totalActiveDevices,
      companyId: requestedCompanyId,
      scannedCompanyCount: 0,
    };
  } catch (error) {
    console.error('getAndroidVersionAdoption failed; returning empty optional dashboard.', {
      code: error && error.code ? error.code : '',
      message: error && error.message ? error.message : String(error),
      companyId: requestedCompanyId,
    });
    return {
      rows: [],
      versions: [],
      totalActiveUsers: 0,
      totalActiveDevices: 0,
      companyId: requestedCompanyId,
      errorCode: error && error.code ? String(error.code) : '',
      errorMessage: error && error.message ? String(error.message) : String(error),
    };
  }
});

function androidReleasePolicyResponse({ currentBuildNumber, policy, serverNow }) {
  const enabled = policy.enabled === true;
  const releaseReady = policy.releaseReady === true;
  const updateUrl = optionalString(policy.updateUrl);
  const hasUpdateUrl = updateUrl.length > 0;
  const updateGateEnabled = enabled && releaseReady && hasUpdateUrl;
  const minimumSupportedBuildNumber = parseBuildNumber(
    policy.minimumSupportedBuildNumber ?? policy.minSupportedBuildNumber,
  );
  const latestBuildNumber = parseBuildNumber(policy.latestBuildNumber);
  const effectiveLatestBuildNumber = Math.max(
    latestBuildNumber,
    minimumSupportedBuildNumber,
  );
  const updateRequired = updateGateEnabled &&
    minimumSupportedBuildNumber > 0 &&
    currentBuildNumber > 0 &&
    currentBuildNumber < minimumSupportedBuildNumber;
  const updateAvailable = updateGateEnabled &&
    effectiveLatestBuildNumber > 0 &&
    currentBuildNumber > 0 &&
    currentBuildNumber < effectiveLatestBuildNumber;

  return {
    enabled,
    releaseReady,
    updateRequired,
    updateAvailable,
    currentBuildNumber,
    minimumSupportedBuildNumber,
    latestBuildNumber: effectiveLatestBuildNumber,
    latestVersionName: sanitizeShortString(policy.appVersion, 40) || versionNameFromUpdateUrl(updateUrl, effectiveLatestBuildNumber),
    updateUrl,
    serverTime: serverNow.toISOString(),
    gracePeriodStartedAt: timestampToIsoString(policy.gracePeriodStartedAt),
    gracePeriodEndsAt: timestampToIsoString(policy.gracePeriodEndsAt),
    titleEn: sanitizeShortString(policy.titleEn, 120),
    titleAr: sanitizeShortString(policy.titleAr, 120),
    bodyEn: sanitizeShortString(policy.bodyEn, 500),
    bodyAr: sanitizeShortString(policy.bodyAr, 500),
  };
}

async function upsertPlatformReleaseRecord({
  actorUid,
  platform,
  appVersion,
  buildNumber,
  channel,
  releaseType,
  status,
  releaseReady,
  enabled,
  minimumSupportedBuildNumber,
  latestBuildNumber,
  updateUrl,
  apkFileName,
  titleEn,
  titleAr,
  notesEn,
  notesAr,
  metadata,
}) {
  const actor = await platformActorSummary(actorUid).catch(() => ({ fullName: '', email: '' }));
  const version = sanitizeShortString(appVersion, 40) || '';
  const releaseId = `${platform}_${version || 'unknown'}_${buildNumber || latestBuildNumber || 0}_${channel}`;
  const ref = db.collection('platform_releases').doc(releaseId);
  const snapshot = await ref.get();
  const now = FieldValue.serverTimestamp();
  const payload = {
    id: releaseId,
    platform,
    appVersion: version,
    buildNumber: parseBuildNumber(buildNumber),
    channel,
    releaseType,
    status,
    releaseReady: releaseReady === true,
    enabled: enabled === true,
    minimumSupportedBuildNumber: parseBuildNumber(minimumSupportedBuildNumber),
    latestBuildNumber: parseBuildNumber(latestBuildNumber),
    updateUrl: optionalString(updateUrl),
    apkFileName: sanitizeShortString(apkFileName, 180),
    titleEn: sanitizeShortString(titleEn, 120),
    titleAr: sanitizeShortString(titleAr, 120),
    notesEn: sanitizeShortString(notesEn, 1000),
    notesAr: sanitizeShortString(notesAr, 1000),
    createdBy: snapshot.exists ? optionalString(snapshot.get('createdBy')) || actorUid : actorUid,
    createdByName: snapshot.exists
      ? optionalString(snapshot.get('createdByName')) || optionalString(actor.fullName) || optionalString(actor.email)
      : optionalString(actor.fullName) || optionalString(actor.email),
    updatedBy: actorUid,
    updatedByName: optionalString(actor.fullName) || optionalString(actor.email),
    updatedAt: now,
    metadata: metadata || {},
  };
  if (!snapshot.exists) {
    payload.createdAt = now;
  }
  if (status === 'released' || releaseReady === true) {
    payload.releasedAt = snapshot.exists && snapshot.get('releasedAt')
      ? snapshot.get('releasedAt')
      : now;
  }
  if (status === 'disabled' || status === 'rolledBack') {
    payload.disabledAt = now;
  }
  await ref.set(payload, { merge: true });
  return { ...payload, id: releaseId, updatedAt: new Date().toISOString() };
}

async function loadPlatformReleases(limit) {
  const snapshot = await db.collection('platform_releases')
    .orderBy('updatedAt', 'desc')
    .limit(limit)
    .get()
    .catch(async () => db.collection('platform_releases').limit(limit).get());
  return snapshot.docs.map((doc) => releaseRecordFromDoc(doc));
}

function releaseRecordFromDoc(doc) {
  const data = doc.data() || {};
  return {
    id: optionalString(data.id) || doc.id,
    platform: optionalString(data.platform),
    appVersion: optionalString(data.appVersion),
    buildNumber: parseBuildNumber(data.buildNumber),
    channel: optionalString(data.channel),
    releaseType: optionalString(data.releaseType),
    status: optionalString(data.status),
    releaseReady: data.releaseReady === true,
    enabled: data.enabled === true,
    minimumSupportedBuildNumber: parseBuildNumber(data.minimumSupportedBuildNumber),
    latestBuildNumber: parseBuildNumber(data.latestBuildNumber),
    updateUrl: optionalString(data.updateUrl),
    apkFileName: optionalString(data.apkFileName),
    notesEn: optionalString(data.notesEn),
    notesAr: optionalString(data.notesAr),
    createdByName: optionalString(data.createdByName),
    createdAt: timestampToIsoString(data.createdAt),
    updatedAt: timestampToIsoString(data.updatedAt),
    releasedAt: timestampToIsoString(data.releasedAt),
    disabledAt: timestampToIsoString(data.disabledAt),
  };
}

function latestReleaseForPlatform(releases, platform) {
  return releases
    .filter((release) => release.platform === platform && release.enabled !== false)
    .sort((a, b) => {
      const buildDiff = parseBuildNumber(b.latestBuildNumber || b.buildNumber) -
        parseBuildNumber(a.latestBuildNumber || a.buildNumber);
      if (buildDiff !== 0) return buildDiff;
      return optionalString(b.updatedAt).localeCompare(optionalString(a.updatedAt));
    })[0] || null;
}

async function buildVersionAdoption({ platform, companyId, activeWithinDays, includeInactive }) {
  const rows = await loadDeviceRows({
    platform,
    companyId,
    activeWithinDays,
    limit: 5000,
    includeInactive,
  });
  const releases = await loadPlatformReleases(80);
  const latestByPlatform = {
    web: latestReleaseForPlatform(releases, 'web'),
    android: latestReleaseForPlatform(releases, 'android'),
  };
  const groups = new Map();
  const usersBelowLatestSet = new Set();
  const usersBelowMinimumSet = new Set();
  let devicesBelowLatest = 0;
  let devicesBelowMinimum = 0;
  rows.forEach((row) => {
    const key = `${row.platform}|${row.appVersion || 'unknown'}|${parseBuildNumber(row.buildNumber)}`;
    const group = groups.get(key) || {
      platform: row.platform,
      appVersion: row.appVersion || '',
      buildNumber: parseBuildNumber(row.buildNumber),
      userIds: new Set(),
      companyIds: new Set(),
      activeDevices: 0,
      latestSeenMillis: 0,
    };
    group.activeDevices += 1;
    if (row.uid) group.userIds.add(`${row.companyId}:${row.uid}`);
    if (row.companyId) group.companyIds.add(row.companyId);
    const seenMillis = Date.parse(optionalString(row.lastSeenAt));
    if (!Number.isNaN(seenMillis)) {
      group.latestSeenMillis = Math.max(group.latestSeenMillis, seenMillis);
    }
    groups.set(key, group);

    const latest = latestByPlatform[row.platform] || null;
    const latestBuild = parseBuildNumber(latest && (latest.latestBuildNumber || latest.buildNumber));
    const minimumBuild = parseBuildNumber(latest && latest.minimumSupportedBuildNumber);
    const currentBuild = parseBuildNumber(row.buildNumber);
    const userKey = `${row.companyId}:${row.uid}`;
    if (latestBuild > 0 && currentBuild > 0 && currentBuild < latestBuild) {
      devicesBelowLatest += 1;
      if (row.uid) usersBelowLatestSet.add(userKey);
    }
    if (minimumBuild > 0 && currentBuild > 0 && currentBuild < minimumBuild) {
      devicesBelowMinimum += 1;
      if (row.uid) usersBelowMinimumSet.add(userKey);
    }
  });
  const adoptionRows = Array.from(groups.values())
    .sort((a, b) => {
      if (a.platform !== b.platform) return a.platform.localeCompare(b.platform);
      return b.buildNumber - a.buildNumber;
    })
    .map((group) => {
      const latest = latestByPlatform[group.platform] || null;
      const latestBuild = parseBuildNumber(latest && (latest.latestBuildNumber || latest.buildNumber));
      const minimumBuild = parseBuildNumber(latest && latest.minimumSupportedBuildNumber);
      const belowMinimum = minimumBuild > 0 && group.buildNumber > 0 && group.buildNumber < minimumBuild;
      const old = latestBuild > 0 && group.buildNumber > 0 && group.buildNumber < latestBuild;
      return {
        platform: group.platform,
        appVersion: group.appVersion === 'unknown' ? '' : group.appVersion,
        buildNumber: group.buildNumber,
        activeUsers: group.userIds.size,
        activeDevices: group.activeDevices,
        activeCompanies: group.companyIds.size,
        latestSeenAt: group.latestSeenMillis > 0 ? new Date(group.latestSeenMillis).toISOString() : null,
        status: belowMinimum ? 'belowMinimum' : (old ? 'old' : 'latest'),
        usersBelowMinimum: belowMinimum ? group.userIds.size : 0,
        devicesBelowMinimum: belowMinimum ? group.activeDevices : 0,
      };
    });
  return {
    rows: adoptionRows,
    versions: adoptionRows,
    totalActiveUsers: new Set(rows.map((row) => `${row.companyId}:${row.uid}`).filter((value) => !value.endsWith(':'))).size,
    totalActiveDevices: rows.length,
    usersBelowLatest: usersBelowLatestSet.size,
    devicesBelowLatest,
    usersBelowMinimum: usersBelowMinimumSet.size,
    devicesBelowMinimum,
    activeWithinDays,
    companyId,
    platform,
    lastUpdated: new Date().toISOString(),
  };
}

async function loadDeviceRows({ platform, companyId, activeWithinDays, limit, includeInactive }) {
  const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - activeWithinDays * 24 * 60 * 60 * 1000);
  let query = companyId
    ? db.collection(`companies/${companyId}/device_installs`)
    : db.collectionGroup('device_installs');
  if (platform === 'web' || platform === 'android') {
    query = query.where('platform', '==', platform);
  }
  const snapshot = await query.limit(limit).get().catch(async () => {
    let fallback = companyId
      ? db.collection(`companies/${companyId}/notification_tokens`)
      : db.collectionGroup('notification_tokens');
    if (platform === 'web' || platform === 'android') {
      fallback = fallback.where('platform', '==', platform);
    }
    return fallback.limit(limit).get();
  });
  return snapshot.docs
    .map((doc) => deviceRowFromDoc(doc))
    .filter((row) => {
      if (!includeInactive && row.isActive !== true) return false;
      if (!includeInactive) {
        const seenMillis = Date.parse(optionalString(row.lastSeenAt));
        if (Number.isNaN(seenMillis) || seenMillis < cutoff.toMillis()) return false;
      }
      if (companyId && row.companyId !== companyId) return false;
      if ((platform === 'web' || platform === 'android') && row.platform !== platform) return false;
      return true;
    })
    .sort((a, b) => optionalString(b.lastSeenAt).localeCompare(optionalString(a.lastSeenAt)))
    .slice(0, limit);
}

function deviceRowFromDoc(doc) {
  const data = doc.data() || {};
  return {
    installId: optionalString(data.installId) || doc.id,
    uid: optionalString(data.uid),
    companyId: optionalString(data.companyId),
    companyName: optionalString(data.companyName),
    fullName: optionalString(data.fullName),
    email: optionalString(data.email),
    role: optionalString(data.role),
    platform: optionalString(data.platform),
    appVersion: optionalString(data.appVersion),
    buildNumber: parseBuildNumber(data.buildNumber),
    lastSeenAt: timestampToIsoString(data.lastSeenAt || data.updatedAt || data.createdAt),
    notificationPermission: optionalString(data.notificationPermission) || 'unknown',
    notificationTokenStatus: optionalString(data.notificationTokenStatus) || (data.tokenHash || data.token ? 'active' : 'missing'),
    browser: optionalString(data.browser),
    os: optionalString(data.os),
    deviceModel: optionalString(data.deviceModel),
    tokenHashPrefix: optionalString(data.tokenHashPrefix) || optionalString(data.tokenHash).slice(0, 12),
    webOrigin: optionalString(data.webOrigin),
    isActive: data.isActive === true,
  };
}

async function loadVersionEvents({ companyId, platform, limit }) {
  let query = companyId
    ? db.collection(`companies/${companyId}/device_version_events`)
    : db.collectionGroup('device_version_events');
  if (platform === 'web' || platform === 'android') {
    query = query.where('platform', '==', platform);
  }
  const snapshot = await query.orderBy('createdAt', 'desc').limit(limit).get()
    .catch(async () => query.limit(limit).get());
  return snapshot.docs.map((doc) => {
    const data = doc.data() || {};
    return {
      eventId: optionalString(data.eventId) || doc.id,
      uid: optionalString(data.uid),
      companyId: optionalString(data.companyId),
      companyName: optionalString(data.companyName),
      role: optionalString(data.role),
      platform: optionalString(data.platform),
      installId: optionalString(data.installId),
      userName: optionalString(data.fullName) || optionalString(data.userName),
      oldVersion: optionalString(data.oldVersion),
      oldBuildNumber: parseBuildNumber(data.oldBuildNumber),
      newVersion: optionalString(data.newVersion),
      newBuildNumber: parseBuildNumber(data.newBuildNumber),
      source: optionalString(data.source),
      createdAt: timestampToIsoString(data.createdAt),
    };
  });
}

function sanitizeClientPlatform(value) {
  const platform = optionalString(value).toLowerCase();
  if (platform === 'web' || platform === 'android') return platform;
  throw new HttpsError('invalid-argument', 'Platform must be web or android.');
}

function sanitizeOptionalPlatformFilter(value) {
  const platform = optionalString(value).toLowerCase();
  if (platform === 'web' || platform === 'android') return platform;
  return 'all';
}

function sanitizeInstallId(value) {
  const clean = optionalString(value).replace(/[^A-Za-z0-9_-]/g, '').slice(0, 120);
  if (clean.length < 12) {
    throw new HttpsError('invalid-argument', 'Install ID is invalid.');
  }
  return clean;
}

function sanitizeHashPrefix(value) {
  return optionalString(value).replace(/[^a-fA-F0-9]/g, '').slice(0, 128);
}

function installStableHash(value) {
  return crypto.createHash('sha256').update(optionalString(value)).digest('hex');
}

function sanitizeNotificationPermission(value) {
  const clean = optionalString(value).toLowerCase();
  if (['granted', 'denied', 'default', 'notsupported', 'unsupported', 'unknown'].includes(clean)) {
    return clean === 'unsupported' || clean === 'notsupported' ? 'notSupported' : clean;
  }
  return 'unknown';
}

function sanitizeNotificationTokenStatus(value) {
  const clean = optionalString(value).toLowerCase();
  if (['active', 'missing', 'invalid', 'blocked', 'failed', 'unknown'].includes(clean)) return clean;
  return 'unknown';
}

function sanitizeVersionEventSource(value) {
  const clean = optionalString(value);
  if (['appStart', 'login', 'resume', 'tokenRegister', 'forcedUpdateCheck', 'heartbeat'].includes(clean)) return clean;
  return 'appStart';
}

function sanitizeReleaseChannel(value) {
  const clean = optionalString(value).toLowerCase();
  if (['production', 'staging', 'internal'].includes(clean)) return clean;
  return 'production';
}

function sanitizeReleaseType(value) {
  const clean = optionalString(value).toLowerCase();
  if (['hotfix', 'patch', 'minor', 'major'].includes(clean)) return clean;
  return 'patch';
}

function sanitizeReleaseStatus(value) {
  const clean = optionalString(value).toLowerCase();
  if (['draft', 'ready', 'released', 'disabled', 'rolledback'].includes(clean)) {
    return clean === 'rolledback' ? 'rolledBack' : clean;
  }
  return 'draft';
}


function versionNameFromUpdateUrl(updateUrl, buildNumber) {
  const fileName = releaseApkFileName(updateUrl);
  const suffix = `-${parseBuildNumber(buildNumber)}.apk`;
  if (!fileName || !fileName.toLowerCase().endsWith(suffix.toLowerCase())) {
    return '';
  }
  const nameWithoutSuffix = fileName.substring(0, fileName.length - suffix.length);
  const prefix = 'masar-crm-';
  if (!nameWithoutSuffix.toLowerCase().startsWith(prefix)) {
    return '';
  }
  return sanitizeShortString(nameWithoutSuffix.substring(prefix.length), 40);
}

function releaseApkFileName(updateUrl) {
  try {
    const parsed = new URL(optionalString(updateUrl));
    const parts = parsed.pathname.split('/').filter(Boolean);
    return sanitizeShortString(parts[parts.length - 1] || '', 180);
  } catch (_) {
    return '';
  }
}

function clampInt(value, min, max, fallback) {
  const parsed = Number.isInteger(value) ? value : parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.max(min, Math.min(max, parsed));
}

function parseBuildNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.max(0, Math.floor(value));
  }
  const parsed = Number.parseInt(String(value || '').trim(), 10);
  return Number.isFinite(parsed) ? Math.max(0, parsed) : 0;
}

function timestampToIsoString(value) {
  if (!value) {
    return '';
  }
  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === 'string') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? '' : date.toISOString();
  }
  return '';
}


const ROLES = new Set(['admin', 'manager', 'salesAgent', 'marketing', 'viewer']);
const COMPANY_ID_PATTERN = /^[a-z0-9][a-z0-9_-]{2,48}[a-z0-9]$/;
const INVITATION_CODE_PATTERN = /^MASAR-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
const INVITATION_CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const INVITATION_STATUSES = new Set(['active', 'used', 'expired', 'revoked']);
const REGISTRATION_ERROR_KEYS = new Set([
  'invitation-invalid',
  'invitation-expired',
  'invitation-used',
  'invitation-revoked',
  'invitation-limit-reached',
  'admin-email-already-exists',
  'company-id-already-exists',
  'invalid-admin-email',
  'weak-password',
  'email-password-auth-disabled',
  'registration-conflict',
  'unable-to-create-admin',
  'unable-to-create-company',
  'unable-to-complete-registration',
]);
const LOCALES = new Set(['en', 'ar']);
const COMPANY_STATUSES = new Set(['active', 'inactive', 'trial', 'trialExpired']);
const PAYMENT_STATUSES = new Set([
  'paid',
  'dueSoon',
  'overdue',
  'gracePeriod',
  'suspended',
  'trial',
  'trialExpired',
  'inactive',
]);
const PAYMENT_CYCLES = new Set(['monthly', 'quarterly', 'semiAnnual', 'yearly', 'custom']);
const PAYMENT_HISTORY_ACTIONS = new Set([
  'markedPaid',
  'extended',
  'statusChanged',
  'suspended',
  'reactivated',
  'noteAdded',
]);
const FEATURE_KEYS = new Set([
  'leads',
  'clients',
  'properties',
  'tasks',
  'appointments',
  'deals',
  'reports',
  'exports',
  'auditLogs',
  'notifications',
  'userManagement',
]);
const OPERATIONAL_TEAM_ROLES = new Set(['salesAgent', 'marketing']);
const LEAD_ASSIGNABLE_ROLES = new Set(['salesAgent', 'marketing']);
const APPOINTMENT_ASSIGNABLE_ROLES = new Set(['admin', 'manager', 'salesAgent', 'marketing']);
const APPOINTMENT_TYPES = new Set([
  'call',
  'meeting',
  'propertyViewing',
  'siteVisit',
  'contractMeeting',
  'reservationMeeting',
  'followUp',
  'other',
]);
const APPOINTMENT_STATUSES = new Set([
  'scheduled',
  'completed',
  'cancelled',
  'missed',
  'rescheduled',
]);
const APPOINTMENT_OUTCOMES = new Set([
  'successfulMeeting',
  'noAnswer',
  'clientPostponed',
  'clientNotInterested',
  'followUpNeeded',
  'dealOpportunity',
  'other',
]);
const LEAD_SOURCES = new Set([
  'facebook',
  'website',
  'phoneCall',
  'whatsapp',
  'referral',
  'walkIn',
  'other',
]);
const LEAD_STATUSES = new Set([
  'new',
  'contacted',
  'interested',
  'visitScheduled',
  'negotiation',
  'won',
  'lost',
]);
const LEAD_PRIORITIES = new Set(['low', 'medium', 'high']);
const DATA_HEALTH_MODULE_POLICIES = {
  leads: { titleField: 'fullName', allowedRoles: new Set(['salesAgent', 'marketing']) },
  clients: { titleField: 'fullName', allowedRoles: new Set(['salesAgent']) },
  tasks: { titleField: 'title', allowedRoles: new Set(['salesAgent', 'marketing']) },
  deals: { titleField: 'clientName', fallbackTitleField: 'propertyTitle', allowedRoles: new Set(['salesAgent']) },
  properties: { titleField: 'title', allowedRoles: new Set(['salesAgent']), onlyWhenAssigned: true },
};
const CRM_ARCHIVE_MODULE_POLICIES = {
  leads: { titleField: 'fullName', fallbackTitle: 'Lead' },
  clients: { titleField: 'fullName', fallbackTitle: 'Client', usesIsActive: true },
  deals: { titleField: 'clientName', fallbackTitleField: 'propertyTitle', fallbackTitle: 'Deal', usesIsActive: true },
  properties: { titleField: 'title', fallbackTitle: 'Property' },
};
const NOTIFICATION_TYPES = new Set([
  'leadAssigned',
  'leadReassigned',
  'leadRemovedFromYou',
  'taskAssigned',
  'taskReassigned',
  'taskRemovedFromYou',
  'appointmentAssigned',
  'appointmentReassigned',
  'appointmentRemovedFromYou',
  'appointmentDueSoon',
  'appointmentDueNow',
  'appointmentRescheduled',
  'appointmentCancelled',
  'appointmentCompleted',
  'appointmentMissed',
  'teamAppointmentAssigned',
  'teamAppointmentReassigned',
  'teamAppointmentDueSoon',
  'teamAppointmentDueNow',
  'teamAppointmentRescheduled',
  'teamAppointmentCancelled',
  'teamAppointmentCompleted',
  'teamAppointmentMissed',
  'clientAssigned',
  'clientReassigned',
  'clientRemovedFromYou',
  'dealAssigned',
  'dealReassigned',
  'dealRemovedFromYou',
  'leadImportantStatusChanged',
  'dealStageChanged',
  'dealImportantStatusChanged',
  'dealWon',
  'dealLost',
  'taskStatusChanged',
  'teamMemberAssigned',
  'teamMemberReassigned',
  'teamMemberRemovedFromRecord',
  'teamLeadStatusChanged',
  'teamDealStageChanged',
  'teamTaskStatusChanged',
  'genericStatusChanged',
  'followUpDueToday',
  'followUpOverdue',
  'taskDueToday',
  'taskOverdue',
  'systemInfo',
  'dataHealthIssue',
]);
const NOTIFICATION_PRIORITIES = new Set(['low', 'normal', 'high', 'urgent']);
const NOTIFICATION_ACTION_STATES = new Set(['none', 'actionNeeded', 'resolved', 'dismissed']);
const NOTIFICATION_DELIVERY_MODES = new Set(['inAppOnly', 'pushEligible', 'attentionOnly', 'auditOnly']);
const NOTIFICATION_RECIPIENT_SCOPES = new Set(['user', 'managerTeam', 'admins', 'platformOwner']);
const PLATFORM_NOTIFICATION_TYPES = new Set([
  'companyRegistered',
  'companyCreated',
  'companyStatusChanged',
  'companySettingsChanged',
  'companyFeatureChanged',
  'companyLimitChanged',
  'companyUserCreated',
  'companyUserStatusChanged',
  'companyUserPasswordReset',
  'dealWon',
  'dealLost',
  'invitationCreated',
  'invitationAccepted',
  'invitationRevoked',
  'supportTicketCreated',
  'feedbackSubmitted',
  'urgentSupportTicketCreated',
  'supportTicketStatusChanged',
  'storageUsageRefreshed',
  'storageNearLimit',
  'platformFunctionFailed',
  'trialEndingSoon',
  'trialExpired',
  'paymentDueSoon',
  'paymentOverdue',
  'paymentGraceEnding',
  'paymentSuspended',
  'paymentReactivated',
  'paymentMarkedPaid',
]);
const PLATFORM_NOTIFICATION_SEVERITIES = new Set(['info', 'success', 'warning', 'urgent']);
const PLATFORM_NOTIFICATION_DELIVERY_MODES = new Set(['inAppOnly', 'pushEligible', 'attentionOnly', 'auditOnly']);
const PLATFORM_NOTIFICATION_RECIPIENT_SCOPES = new Set(['user', 'managerTeam', 'admins', 'platformOwner']);
const PLATFORM_NOTIFICATION_SOURCES = new Set([
  'platform',
  'support',
  'invitation',
  'company',
  'user',
  'storage',
  'system',
]);
const REPORT_EXPORT_TYPES = new Set([
  'reportsExport',
  'auditLogsExport',
  'platformCompanyExport',
]);
const REPORT_EXPORT_MODULES = new Set([
  'leads',
  'clients',
  'deals',
  'tasks',
  'appointments',
  'properties',
  'teamPerformance',
  'pipeline',
  'followUps',
  'auditSummary',
  'auditLogs',
]);
const REPORT_EXPORT_DATE_RANGES = new Set([
  'allTime',
  'today',
  'thisWeek',
  'thisMonth',
  'lastMonth',
  'custom',
]);
const REPORT_EXPORT_SCOPES = new Set([
  'companyWide',
  'teamOnly',
  'assignedOnly',
  'restricted',
]);
const PLATFORM_ERROR_SOURCES = new Set([
  'flutter_web',
  'flutter_mobile',
  'cloud_function',
  'firestore_rule',
  'storage',
  'unknown',
]);
const PLATFORM_ERROR_SEVERITIES = new Set(['info', 'warning', 'error', 'fatal']);
const IMPORTANT_ERROR_MODULES = new Set([
  'auth',
  'appointments',
  'platform',
  'invitations',
  'clients',
  'clients assignment',
  'support',
  'subscription',
  'payment',
]);
const IMPORTANT_LEAD_STATUSES = new Set([
  'hot',
  'qualified',
  'converted',
  'won',
  'lost',
  'closed',
  'closedWon',
  'closedLost',
  'interested',
  'negotiation',
]);
const IMPORTANT_DEAL_STAGES = new Set([
  'negotiation',
  'reservation',
  'reserved',
  'contract',
  'won',
  'lost',
  'closedWon',
  'closedLost',
  'closed',
]);
const IMPORTANT_TASK_STATUSES = new Set([
  'completed',
  'cancelled',
  'canceled',
]);
const MAJOR_DEAL_OUTCOMES = new Set([
  'won',
  'lost',
  'closedWon',
  'closedLost',
]);
const DEAL_STAGES = new Set([
  'new',
  'qualified',
  'proposal',
  'negotiation',
  'won',
  'lost',
]);

exports.createCompanyInvitation = onCall(async (request) => {
  const callerUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const planId = optionalString(data.planId);
  const planName = optionalString(data.planName) || 'Masar CRM';
  const userLimit = positiveInteger(data.userLimit, 'userLimit');
  const storageLimitMb = positiveInteger(data.storageLimitMb, 'storageLimitMb');
  const features = validateCompanyFeatures(requiredObject(data.features, 'features'));
  const locale = optionalString(data.locale) || 'en';
  const timezone = optionalString(data.timezone) || 'Africa/Cairo';
  const notes = sanitizeShortString(data.notes, 500);
  const trial = trialPayload(data);
  const expiresAt = parseFutureDate(data.expiresAt, 'expiresAt');

  validateLocale(locale);
  validateTimezone(timezone);
  const invitationRef = db.collection('platform_invitations').doc();
  const invitationCode = generateInvitationCode();
  const codeHash = hashInvitationCode(invitationCode);
  const codePreview = previewInvitationCode(invitationCode);
  const now = FieldValue.serverTimestamp();

  await invitationRef.set({
    id: invitationRef.id,
    codeHash,
    codePreview,
    invitationCode,
    type: 'companyAdmin',
    status: 'active',
    planId,
    planName,
    userLimit,
    storageLimitMb,
    features,
    locale,
    timezone,
    notes,
    trialDays: trial.trialDays,
    trialDurationValue: trial.trialDurationValue,
    trialDurationUnit: trial.trialDurationUnit,
    expiresAt,
    maxUses: 1,
    usedCount: 0,
    createdAt: now,
    createdBy: callerUid,
    updatedAt: now,
    updatedBy: callerUid,
  });
  const actor = await platformActorSummary(callerUid);
  await createPlatformNotificationSafely('create_company_invitation', {
    id: `invitation_created_${invitationRef.id}`,
    type: 'invitationCreated',
    title: 'Invitation created',
    message: `Invitation created for ${planName}.`,
    severity: 'info',
    source: 'invitation',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    metadata: {
      invitationId: invitationRef.id,
      planId,
      planName,
      userLimit,
      storageLimitMb,
      locale,
      timezone,
      trialDays: trial.trialDays,
      trialDurationValue: trial.trialDurationValue,
      trialDurationUnit: trial.trialDurationUnit,
    },
  });

  return {
    invitationId: invitationRef.id,
    invitationCode,
    invitationLink: invitationLink(invitationCode, data.origin),
    expiresAt: expiresAt.getTime(),
    codePreview,
  };
});

exports.validateCompanyInvitation = onCall(async (request) => {
  const invitationCode = requiredString(
    (request.data || {}).invitationCode,
    'invitationCode',
  );
  const invitation = await loadInvitationByCode(invitationCode);
  let status = invitation ? invitationPublicStatus(invitation.data) : 'invalid';
  if (invitation && status === 'active' && await invitationUseMarkerExists(invitation.id)) {
    status = 'used';
  }

  if (!invitation || status !== 'active') {
    return {
      valid: false,
      status,
      message: invitationStatusMessage(status),
    };
  }

  return {
    valid: true,
    status: 'active',
    planName: invitation.data.planName || '',
    userLimit: invitation.data.userLimit || 0,
    storageLimitMb: invitation.data.storageLimitMb || 0,
    features: publicFeatureSummary(invitation.data.features || {}),
    locale: invitation.data.locale || 'en',
    timezone: invitation.data.timezone || 'Africa/Cairo',
    trialDays: Number.isInteger(invitation.data.trialDays) ? invitation.data.trialDays : 0,
    trialDurationValue: Number.isInteger(invitation.data.trialDurationValue) ? invitation.data.trialDurationValue : (Number.isInteger(invitation.data.trialDays) ? invitation.data.trialDays : 0),
    trialDurationUnit: normalizeTrialUnit(invitation.data.trialDurationUnit),
    expiresAt: dateMillis(invitation.data.expiresAt),
  };
});

exports.acceptCompanyInvitation = onCall(async (request) => {
  let userRecord;
  let createdAuthUser = false;
  let currentStep = 'accept_invitation_start';
  const logContext = {
    companyId: '',
    adminEmail: '',
    invitationId: '',
  };

  logAcceptInvitationStep(currentStep, logContext);

  try {
    currentStep = 'validate_payload';
    logAcceptInvitationStep(currentStep, logContext);

    const data = request.data || {};
    const invitationCode = normalizeInvitationCode(data.invitationCode);
    const companyName = sanitizeCompanyText(data.companyName, 'companyName');
    const companyId = sanitizeCompanyId(slugFromName(companyName));
    const companyPhone = sanitizeShortString(data.companyPhone, 80);
    const companyCity = sanitizeShortString(data.companyCity || data.companyLocation, 120);
    const companyWebsite = sanitizeOptionalUrl(data.companyWebsite);
    const adminFullName = sanitizeProfileName(data.adminFullName);
    const adminPhone = sanitizeShortString(data.adminPhone, 80);
    const adminEmail = normalizeEmail(requiredString(data.adminEmail, 'adminEmail'));
    const password = requiredPassword(data.password, 'password');
    const confirmPassword = optionalPassword(data.confirmPassword);
    const locale = optionalString(data.locale) || 'en';
    const timezone = optionalString(data.timezone) || 'Africa/Cairo';

    logContext.companyId = companyId;
    logContext.adminEmail = adminEmail;

    validateCompanyId(companyId);
    validateEmail(adminEmail);
    validatePassword(password);
    validateLocale(locale);
    validateTimezone(timezone);
    if (confirmPassword && confirmPassword !== password) {
      throw registrationError(
        'invalid-argument',
        'unable-to-complete-registration',
      );
    }

    currentStep = 'validate_invitation';
    logAcceptInvitationStep(currentStep, logContext);
    const invitation = await loadInvitationByCode(invitationCode);
    logContext.invitationId = invitation ? invitation.id : '';
    assertInvitationActiveForRegistration(invitation);

    currentStep = 'check_company_id';
    logAcceptInvitationStep(currentStep, logContext);
    const companyRef = db.doc(`companies/${companyId}`);
    if ((await companyRef.get()).exists) {
      throw registrationError('already-exists', 'company-id-already-exists');
    }

    currentStep = 'check_admin_email_auth';
    logAcceptInvitationStep(currentStep, logContext);
    await assertAdminEmailNotUsedInAuth(adminEmail);

    currentStep = 'check_admin_email_global_user';
    logAcceptInvitationStep(currentStep, logContext);
    await assertEmailNotUsedInGlobalProfiles(adminEmail);

    currentStep = 'check_admin_email_company_users';
    logAcceptInvitationStep(currentStep, logContext);
    await assertEmailNotUsedInCompanyUserProfiles(adminEmail);

    currentStep = 'check_invitation_usage_marker';
    logAcceptInvitationStep(currentStep, logContext);
    if (await invitationUseMarkerExists(invitation.id)) {
      throw registrationError('failed-precondition', 'invitation-used');
    }

    currentStep = 'create_auth_user';
    logAcceptInvitationStep(currentStep, logContext);
    userRecord = await auth.createUser({
      email: adminEmail,
      password,
      displayName: adminFullName,
      emailVerified: false,
      disabled: false,
    }).catch((error) => {
      throw mapAuthUserCreationError(error);
    });
    createdAuthUser = true;

    await db.runTransaction(async (transaction) => {
      currentStep = 'validate_invitation';
      logAcceptInvitationStep(currentStep, logContext);
      const freshInvitationSnapshot = await transaction.get(invitation.ref);
      if (!freshInvitationSnapshot.exists) {
        throw registrationError('invalid-argument', 'invitation-invalid');
      }
      const freshInvitation = freshInvitationSnapshot.data() || {};
      const freshInvitationStatus = invitationPublicStatus(freshInvitation);
      if (freshInvitationStatus !== 'active') {
        throw registrationError(
          'failed-precondition',
          registrationKeyForInvitationStatus(freshInvitation, freshInvitationStatus),
        );
      }

      currentStep = 'check_invitation_usage_marker';
      logAcceptInvitationStep(currentStep, logContext);
      const invitationUseRef = invitationUsageRef(invitation.id);
      const invitationUseSnapshot = await transaction.get(invitationUseRef);
      if (invitationUseSnapshot.exists) {
        throw registrationError('failed-precondition', 'invitation-used');
      }

      currentStep = 'check_company_id';
      logAcceptInvitationStep(currentStep, logContext);
      const freshCompanySnapshot = await transaction.get(companyRef);
      if (freshCompanySnapshot.exists) {
        throw registrationError('aborted', 'registration-conflict');
      }

      const now = FieldValue.serverTimestamp();
      const planName = freshInvitation.planName || 'Masar CRM';
      const features = validateCompanyFeatures(freshInvitation.features || {});
      const userLimit = positiveInteger(freshInvitation.userLimit || 25, 'userLimit');
      const storageLimitMb = positiveInteger(
        freshInvitation.storageLimitMb || 1024,
        'storageLimitMb',
      );
      const trial = trialDatesFromDuration(
        Number.isInteger(freshInvitation.trialDurationValue) ? freshInvitation.trialDurationValue : freshInvitation.trialDays,
        freshInvitation.trialDurationUnit,
      );

      currentStep = 'create_company_docs';
      logAcceptInvitationStep(currentStep, logContext);
      transaction.set(companyRef, {
        id: companyId,
        name: companyName,
        displayName: companyName,
        status: trial.status,
        isActive: true,
        trialStartedAt: trial.trialStartedAt,
        trialEndsAt: trial.trialEndsAt,
        phone: companyPhone,
        city: companyCity,
        location: companyCity,
        website: companyWebsite,
        planId: freshInvitation.planId || '',
        planName,
        trialDays: trial.trialDays,
        trialDurationValue: trial.trialDurationValue,
        trialDurationUnit: trial.trialDurationUnit,
        paymentStatus: trial.status === 'trial' ? 'trial' : 'paid',
        paymentCycle: 'monthly',
        paymentCurrency: 'EGP',
        paymentAmount: 0,
        paymentNotes: '',
        paymentReminderState: {},
        createdAt: now,
        createdBy: userRecord.uid,
        updatedAt: now,
        updatedBy: userRecord.uid,
        settings: {
          locale,
          timezone,
        },
        limits: {
          users: userLimit,
          storageMb: storageLimitMb,
        },
        features,
      });

      currentStep = 'create_global_user';
      logAcceptInvitationStep(currentStep, logContext);
      transaction.set(db.doc(`users/${userRecord.uid}`), {
        uid: userRecord.uid,
        email: adminEmail,
        fullName: adminFullName,
        phone: adminPhone,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      }, { merge: true });

      currentStep = 'create_company_admin_profile';
      logAcceptInvitationStep(currentStep, logContext);
      transaction.set(db.doc(`companies/${companyId}/users/${userRecord.uid}`), {
        uid: userRecord.uid,
        companyId,
        fullName: adminFullName,
        email: adminEmail,
        phone: adminPhone,
        role: 'admin',
        isActive: true,
        createdAt: now,
        createdBy: userRecord.uid,
        updatedAt: now,
        updatedBy: userRecord.uid,
        teamId: '',
        teamName: '',
        managerId: '',
        managerName: '',
      }, { merge: true });

      currentStep = 'create_membership';
      logAcceptInvitationStep(currentStep, logContext);
      transaction.set(db.doc(`users/${userRecord.uid}/memberships/${companyId}`), {
        companyId,
        companyName,
        role: 'admin',
        isActive: true,
        status: trial.status,
        paymentStatus: trial.status === 'trial' ? 'trial' : 'paid',
        createdAt: now,
        updatedAt: now,
      }, { merge: true });

      currentStep = 'mark_invitation_used';
      logAcceptInvitationStep(currentStep, logContext);
      transaction.set(invitationUsageRef(invitation.id), {
        invitationId: invitation.id,
        codeHash: freshInvitation.codeHash || '',
        companyId,
        adminUid: userRecord.uid,
        adminEmail,
        usedAt: now,
        createdAt: now,
      });
      transaction.update(invitation.ref, {
        status: 'used',
        usedCount: FieldValue.increment(1),
        acceptedAt: now,
        acceptedBy: userRecord.uid,
        acceptedAdminEmail: adminEmail,
        companyId,
        adminUid: userRecord.uid,
        updatedAt: now,
        updatedBy: userRecord.uid,
      });
    });

    currentStep = 'accept_invitation_success';
    logAcceptInvitationStep(currentStep, logContext);
    await createPlatformNotificationSafely('accept_company_invitation_registered', {
      id: `company_registered_${companyId}`,
      type: 'companyRegistered',
      title: 'Company registered',
      message: `${companyName} registered through an invitation.`,
      severity: 'success',
      source: 'company',
      route: '/platform',
      actorId: userRecord.uid,
      actorName: adminFullName,
      actorEmail: adminEmail,
      companyId,
      companyName,
      metadata: {
        invitationId: invitation.id,
        adminUid: userRecord.uid,
        planName: invitation.data.planName || '',
      },
    });
    await createPlatformNotificationSafely('accept_company_invitation', {
      id: `invitation_accepted_${invitation.id}`,
      type: 'invitationAccepted',
      title: 'Invitation accepted',
      message: `${companyName} accepted an invitation.`,
      severity: 'success',
      source: 'invitation',
      route: '/platform',
      actorId: userRecord.uid,
      actorName: adminFullName,
      actorEmail: adminEmail,
      companyId,
      companyName,
      metadata: {
        invitationId: invitation.id,
        adminUid: userRecord.uid,
      },
    });
    return {
      success: true,
      companyId,
      adminUid: userRecord.uid,
    };
  } catch (error) {
    const mappedError = mapAcceptRegistrationError(error, currentStep);
    if (currentStep !== 'accept_invitation_failed') {
      logAcceptInvitationStep(currentStep, logContext, mappedError);
    }
    if (mappedError && mappedError.code === 'internal') {
      await logCloudFunctionError({
        functionName: 'acceptCompanyInvitation',
        module: 'invitations',
        companyId: logContext.companyId,
        error: mappedError,
        metadata: {
          step: currentStep,
          invitationId: logContext.invitationId,
        },
      });
    }
    if (createdAuthUser && userRecord) {
      await cleanupInvitationAuthUser(userRecord, logContext);
      createdAuthUser = false;
    }
    logAcceptInvitationStep('accept_invitation_failed', logContext, mappedError);
    throw mappedError;
  }
});

exports.revokeCompanyInvitation = onCall(async (request) => {
  const callerUid = await requireActivePlatformAdmin(request);
  const invitationId = requiredString((request.data || {}).invitationId, 'invitationId');
  const invitationRef = db.doc(`platform_invitations/${invitationId}`);
  const invitationSnapshot = await invitationRef.get();
  if (!invitationSnapshot.exists) {
    throw new HttpsError('not-found', 'Invitation was not found.');
  }

  const invitation = invitationSnapshot.data() || {};
  if (invitation.status === 'used') {
    throw new HttpsError('failed-precondition', 'Used invitations cannot be revoked.');
  }

  await invitationRef.update({
    status: 'revoked',
    revokedAt: FieldValue.serverTimestamp(),
    revokedBy: callerUid,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: callerUid,
  });
  const actor = await platformActorSummary(callerUid);
  await createPlatformNotificationSafely('revoke_company_invitation', {
    id: `invitation_revoked_${invitationId}`,
    type: 'invitationRevoked',
    title: 'Invitation revoked',
    message: 'A company invitation was revoked.',
    severity: 'warning',
    source: 'invitation',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    metadata: {
      invitationId,
      planName: invitation.planName || '',
      status: 'revoked',
    },
  });

  return { invitationId, status: 'revoked' };
});

exports.listCompanyInvitations = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const status = optionalString(data.status);
  if (status && !INVITATION_STATUSES.has(status)) {
    throw new HttpsError('invalid-argument', 'Invitation status is invalid.');
  }

  const snapshot = await db.collection('platform_invitations')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  const rawInvitations = snapshot.docs.map((doc) => ({
    id: doc.id,
    data: doc.data() || {},
  }));
  const usedCompanyIds = [
    ...new Set(
      rawInvitations
        .map((item) => item.data.companyId || '')
        .filter((companyId) => companyId),
    ),
  ];
  const companySnapshots = await Promise.all(
    usedCompanyIds.map((companyId) => db.doc(`companies/${companyId}`).get()),
  );
  const companiesById = {};
  companySnapshots.forEach((companySnapshot) => {
    if (companySnapshot.exists) {
      companiesById[companySnapshot.id] = companySnapshot.data() || {};
    }
  });
  const invitations = rawInvitations
    .map((item) => publicInvitationListItem(
      item.id,
      item.data,
      companiesById[item.data.companyId || ''] || null,
    ))
    .filter((invitation) => !status || invitation.status === status);
  return {
    invitations,
  };
});

exports.reportClientError = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const uid = request.auth.uid;
  const data = request.data || {};
  const source = enumValueOrDefault(data.source, PLATFORM_ERROR_SOURCES, 'unknown');
  const severity = enumValueOrDefault(data.severity, PLATFORM_ERROR_SEVERITIES, 'error');
  const message =
    sanitizeLogText(optionalString(data.message) || 'Unhandled client error', 500);
  const route = sanitizeLogText(optionalString(data.route), 180);
  const module = sanitizeLogText(optionalString(data.module), 100);
  const errorCode = sanitizeLogText(optionalString(data.errorCode), 100);
  const shortStack = sanitizeLogText(optionalString(data.shortStack), 1800);
  const providedStackHash = sanitizeHash(optionalString(data.stackHash));
  const stackHash = providedStackHash || hashText(`${message}\n${shortStack}`).slice(0, 32);
  const appVersion = sanitizeLogText(optionalString(data.appVersion), 40);
  const buildNumber = sanitizeLogText(optionalString(data.buildNumber), 24);
  const platform = sanitizeLogText(optionalString(data.platform), 80);
  const deviceType = sanitizeLogText(optionalString(data.deviceType), 80);
  const userAgent = sanitizeLogText(optionalString(data.userAgent), 600);
  const timezone = sanitizeLogText(optionalString(data.timezone), 80);
  const metadata = sanitizeLogMetadata(data.metadata || {});

  const resolvedContext = await resolveErrorReporterContext({
    uid,
    requestedCompanyId: optionalString(data.companyId),
  });
  const cleanCompanyId = resolvedContext.companyId;
  const cleanCompanyName = resolvedContext.companyName;
  const userEmail = resolvedContext.userEmail;
  const userRole = resolvedContext.userRole;
  const messageHash = hashText(`${message}|${errorCode}`).slice(0, 24);
  const dedupeId = safeDocumentId(
    `err_${hashText([
      cleanCompanyId,
      source,
      route,
      module,
      stackHash,
      messageHash,
    ].join('|')).slice(0, 36)}`,
  );
  const logRef = db.collection('platform_error_logs').doc(dedupeId);
  const now = FieldValue.serverTimestamp();

  const occurrenceCount = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(logRef);
    if (snapshot.exists) {
      const previousCount = Number(snapshot.get('occurrenceCount') || 0);
      const nextCount = previousCount + 1;
      transaction.set(logRef, {
        id: logRef.id,
        companyId: cleanCompanyId,
        companyName: cleanCompanyName,
        userId: uid,
        userEmail,
        userRole,
        route,
        module,
        source,
        severity,
        message,
        errorCode,
        stackHash,
        shortStack,
        occurrenceCount: nextCount,
        lastSeenAt: now,
        appVersion,
        buildNumber,
        platform,
        deviceType,
        userAgent,
        timezone,
        resolved: false,
        resolvedBy: '',
        resolvedByEmail: '',
        resolvedAt: null,
        metadata,
      }, { merge: true });
      return nextCount;
    }

    transaction.set(logRef, {
      id: logRef.id,
      companyId: cleanCompanyId,
      companyName: cleanCompanyName,
      userId: uid,
      userEmail,
      userRole,
      route,
      module,
      source,
      severity,
      message,
      errorCode,
      stackHash,
      shortStack,
      occurrenceCount: 1,
      firstSeenAt: now,
      lastSeenAt: now,
      createdAt: now,
      appVersion,
      buildNumber,
      platform,
      deviceType,
      userAgent,
      timezone,
      resolved: false,
      resolvedBy: '',
      resolvedByEmail: '',
      resolvedAt: null,
      ownerNotified: false,
      metadata,
    });
    return 1;
  });

  if (shouldNotifyOwnerForError({
    severity,
    module,
    occurrenceCount,
    errorCode,
  })) {
    const title = severity === 'fatal'
      ? 'Fatal error detected'
      : 'Repeated platform error detected';
    const companyPart = cleanCompanyName || cleanCompanyId || 'Masar CRM';
    await createPlatformNotificationSafely('report_client_error', {
      id: `platform_error_${logRef.id}`,
      type: 'platformFunctionFailed',
      title,
      message: `${companyPart}: ${message}`,
      severity: severity === 'fatal' ? 'urgent' : 'warning',
      source: 'system',
      route: '/platform/monitoring',
      actorId: uid,
      actorName: '',
      actorEmail: userEmail,
      companyId: cleanCompanyId,
      companyName: cleanCompanyName,
      metadata: {
        logId: logRef.id,
        source,
        module,
        route,
        severity,
        occurrenceCount,
        errorCode,
      },
    });
    await logRef.set({
      ownerNotified: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  return {
    logId: logRef.id,
    occurrenceCount,
  };
});

exports.markPlatformErrorResolved = onCall(async (request) => {
  const callerUid = await requireActivePlatformAdmin(request);
  const logId = requiredString((request.data || {}).logId, 'logId');
  const cleanLogId = safeDocumentId(logId);
  if (!cleanLogId) {
    throw new HttpsError('invalid-argument', 'Log ID is invalid.');
  }
  const logRef = db.collection('platform_error_logs').doc(cleanLogId);
  const logSnapshot = await logRef.get();
  if (!logSnapshot.exists) {
    throw new HttpsError('not-found', 'Error log was not found.');
  }
  const actor = await platformActorSummary(callerUid);
  await logRef.set({
    resolved: true,
    resolvedBy: callerUid,
    resolvedByEmail: actor.actorEmail,
    resolvedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  return { logId: cleanLogId, resolved: true };
});

exports.createCompanyWithAdmin = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const companyName = requiredString(data.companyName, 'companyName');
  const adminFullName = requiredString(data.adminFullName, 'adminFullName');
  const adminEmail = normalizeEmail(requiredString(data.adminEmail, 'adminEmail'));
  const adminPhone = optionalString(data.adminPhone);
  const locale = optionalString(data.locale) || 'en';
  const timezone = optionalString(data.timezone) || 'Africa/Cairo';
  const trial = trialPayload(data);

  validateCompanyId(companyId);
  validateLocale(locale);
  validateTimezone(timezone);

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (companySnapshot.exists) {
    throw new HttpsError('already-exists', 'Company ID already exists.');
  }

  const { userRecord, passwordResetLink } = await getOrCreateUserForInvitation({
    email: adminEmail,
    displayName: adminFullName,
  });

  const now = FieldValue.serverTimestamp();
  const batch = db.batch();
  writeGlobalUser(batch, userRecord.uid, {
    email: adminEmail,
    fullName: adminFullName,
    phone: adminPhone,
    isActive: true,
    now,
  });
  batch.set(companyRef, {
    id: companyId,
    name: companyName,
    displayName: companyName,
    status: trial.status,
    isActive: true,
    trialStartedAt: trial.trialStartedAt,
    trialEndsAt: trial.trialEndsAt,
    trialDays: trial.trialDays,
    trialDurationValue: trial.trialDurationValue,
    trialDurationUnit: trial.trialDurationUnit,
    paymentStatus: trial.status === 'trial' ? 'trial' : 'paid',
    paymentCycle: 'monthly',
    paymentCurrency: 'EGP',
    paymentAmount: 0,
    paymentNotes: '',
    paymentReminderState: {},
    createdAt: now,
    createdBy: request.auth.uid,
    updatedAt: now,
    updatedBy: request.auth.uid,
    settings: {
      locale,
      timezone,
    },
    limits: {
      users: 25,
      storageMb: 1024,
    },
    features: {
      leads: true,
      clients: true,
      properties: true,
      tasks: true,
      appointments: true,
      deals: true,
      reports: true,
      exports: true,
      auditLogs: true,
      notifications: true,
      userManagement: true,
    },
  });
  writeCompanyUser(batch, companyId, userRecord.uid, {
    fullName: adminFullName,
    email: adminEmail,
    phone: adminPhone,
    role: 'admin',
    isActive: true,
    actorUid,
    now,
  });
  writeMembership(batch, userRecord.uid, companyId, {
    companyName,
    role: 'admin',
    isActive: true,
    status: trial.status,
    paymentStatus: trial.status === 'trial' ? 'trial' : 'paid',
    now,
  });
  await batch.commit();
  const actor = await platformActorSummary(actorUid);
  await createPlatformNotificationSafely('create_company_with_admin', {
    id: `company_created_${companyId}`,
    type: 'companyCreated',
    title: 'Company created',
    message: `${companyName} was created by platform support.`,
    severity: 'success',
    source: 'company',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    companyId,
    companyName,
    metadata: {
      adminUid: userRecord.uid,
      adminEmail,
    },
  });

  return { uid: userRecord.uid, companyId, passwordResetLink };
});

exports.addUserToCompany = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const actorUid = await requirePlatformOrCompanyAdmin(request, companyId);
  const fullName = requiredString(data.fullName, 'fullName');
  const email = normalizeEmail(requiredString(data.email, 'email'));
  const phone = optionalString(data.phone);
  const role = requiredString(data.role, 'role');
  const temporaryPassword = optionalPassword(data.temporaryPassword);
  const usesTemporaryPassword = temporaryPassword.length > 0;

  validateCompanyId(companyId);
  validateRole(role);
  if (usesTemporaryPassword) {
    validatePassword(temporaryPassword);
  }
  const isPlatformActor = await isActivePlatformAdminUid(request.auth.uid);
  if (role === 'admin' && !isPlatformActor) {
    throw new HttpsError(
      'permission-denied',
      'Only platform owner support can create additional company admins.',
    );
  }

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data();
  if (company.isActive !== true || company.status === 'inactive') {
    throw new HttpsError('failed-precondition', 'Company is inactive.');
  }
  enforceUserManagementFeature(company, isPlatformActor);

  await enforceUserLimit(companyId, company);

  let userRecord;
  let passwordResetLink = '';
  let createdAuthUser = false;
  try {
    const createdUserResult = await getOrCreateUserForInvitation({
      email,
      displayName: fullName,
      temporaryPassword: usesTemporaryPassword ? temporaryPassword : '',
    });
    userRecord = createdUserResult.userRecord;
    passwordResetLink = createdUserResult.passwordResetLink;
    createdAuthUser = createdUserResult.created === true;

    const companyUserRef = db.doc(`companies/${companyId}/users/${userRecord.uid}`);
    const companyUserSnapshot = await companyUserRef.get();
    if (companyUserSnapshot.exists) {
      throw new HttpsError('already-exists', 'Company user already exists.');
    }

    const now = FieldValue.serverTimestamp();
    const batch = db.batch();
    writeGlobalUser(batch, userRecord.uid, {
      email,
      fullName,
      phone,
      isActive: true,
      mustChangePassword: usesTemporaryPassword,
      passwordSetupMethod: usesTemporaryPassword ? 'temporaryPassword' : 'setupLink',
      now,
    });
    writeCompanyUser(batch, companyId, userRecord.uid, {
      fullName,
      email,
      phone,
      role,
      isActive: true,
      mustChangePassword: usesTemporaryPassword,
      passwordSetupMethod: usesTemporaryPassword ? 'temporaryPassword' : 'setupLink',
      actorUid,
      now,
    });
    writeMembership(batch, userRecord.uid, companyId, {
      companyName: company.displayName || company.name || companyId,
      role,
      isActive: true,
      now,
    });
    await batch.commit();
  } catch (error) {
    if (createdAuthUser && userRecord && userRecord.uid) {
      await auth.deleteUser(userRecord.uid).catch((cleanupError) => {
        console.error('add_user_cleanup_auth_failed', {
          companyId,
          email,
          uid: userRecord.uid,
          code: cleanupError && cleanupError.code ? cleanupError.code : '',
          message: cleanupError && cleanupError.message ? cleanupError.message : '',
        });
      });
    }
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error('add_user_failed', {
      companyId,
      email,
      code: error && error.code ? error.code : '',
      message: error && error.message ? error.message : '',
    });
    throw new HttpsError('internal', 'Unable to create company user.');
  }
  {
    const actor = await notificationActorSummary(companyId, actorUid);
    const actorRole = isPlatformActor ? 'platformAdmin' : 'companyAdmin';
    await createPlatformNotificationSafely('add_user_to_company', {
      id: `company_user_created_${companyId}_${userRecord.uid}`,
      type: 'companyUserCreated',
      title: 'Company user created',
      message: `${fullName} was added to ${companyNotificationName(companyId, company)} by ${actor.actorName || actor.actorEmail || actorRole}.`,
      severity: 'success',
      source: 'user',
      route: '/platform',
      actorId: actor.actorId,
      actorName: actor.actorName,
      actorEmail: actor.actorEmail,
      companyId,
      companyName: companyNotificationName(companyId, company),
      metadata: {
        targetUid: userRecord.uid,
        targetEmail: email,
        role,
        actorRole,
        passwordSetupMethod: usesTemporaryPassword ? 'temporaryPassword' : 'setupLink',
      },
    });
  }

  return {
    uid: userRecord.uid,
    companyId,
    passwordResetLink,
    usedTemporaryPassword: usesTemporaryPassword,
  };
});


exports.completeRequiredPasswordChange = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const uid = request.auth.uid;
  const companyUserRef = db.doc(`companies/${companyId}/users/${uid}`);
  const globalUserRef = db.doc(`users/${uid}`);
  const membershipRef = db.doc(`users/${uid}/memberships/${companyId}`);

  const [companySnapshot, companyUserSnapshot, membershipSnapshot] =
    await Promise.all([
      db.doc(`companies/${companyId}`).get(),
      companyUserRef.get(),
      membershipRef.get(),
    ]);

  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  if (company.isActive !== true || company.status === 'inactive') {
    throw new HttpsError('failed-precondition', 'Company is inactive.');
  }
  if (!companyUserSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Company user was not found.');
  }
  const companyUser = companyUserSnapshot.data() || {};
  if (companyUser.companyId !== companyId || companyUser.isActive !== true) {
    throw new HttpsError('permission-denied', 'Company user is inactive.');
  }
  if (!membershipSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Company membership was not found.');
  }
  const membership = membershipSnapshot.data() || {};
  if (membership.isActive !== true || membership.status === 'inactive') {
    throw new HttpsError('permission-denied', 'Company membership is inactive.');
  }

  const now = FieldValue.serverTimestamp();
  const updates = {
    mustChangePassword: false,
    passwordSetupMethod: 'changed',
    passwordChangedAt: now,
    updatedAt: now,
  };

  const batch = db.batch();
  batch.set(companyUserRef, {
    ...updates,
    updatedBy: uid,
  }, { merge: true });
  batch.set(globalUserRef, updates, { merge: true });
  batch.set(membershipRef, { updatedAt: now }, { merge: true });
  await batch.commit();

  return { uid, companyId };
});

exports.assignUserToTeam = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const teamId = requiredString(data.teamId, 'teamId');
  const uid = requiredString(data.uid, 'uid');
  validateCompanyId(companyId);

  const actorUid = await requireActiveCompanyAdmin(request, companyId);
  const teamRef = db.doc(`companies/${companyId}/teams/${teamId}`);
  const targetUserRef = db.doc(`companies/${companyId}/users/${uid}`);
  const [teamSnapshot, targetUserSnapshot] = await Promise.all([
    teamRef.get(),
    targetUserRef.get(),
  ]);

  if (!teamSnapshot.exists) {
    throw new HttpsError('not-found', 'Team was not found.');
  }
  if (!targetUserSnapshot.exists) {
    throw new HttpsError('not-found', 'User was not found.');
  }

  const team = teamSnapshot.data() || {};
  if (team.companyId && team.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'Team does not belong to this company.');
  }
  if (team.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Team is inactive.');
  }

  const targetUser = targetUserSnapshot.data() || {};
  if (targetUser.companyId && targetUser.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'User does not belong to this company.');
  }
  if (targetUser.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Target user is inactive.');
  }
  if (!OPERATIONAL_TEAM_ROLES.has(targetUser.role)) {
    throw new HttpsError(
      'invalid-argument',
      'Only sales and marketing users can be team members.',
    );
  }

  const previousTeamId = optionalString(targetUser.teamId);
  const nextAssigneeSnapshot = {
    ...targetUser,
    teamId,
    teamName: optionalString(team.name),
    managerId: optionalString(team.managerId),
    managerName: optionalString(team.managerName),
  };
  await targetUserRef.update({
    teamId: nextAssigneeSnapshot.teamId,
    teamName: nextAssigneeSnapshot.teamName,
    managerId: nextAssigneeSnapshot.managerId,
    managerName: nextAssigneeSnapshot.managerName,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  });

  const repairedRecords = await backfillAssignedRecordsForUser({
    companyId,
    uid,
    assignee: nextAssigneeSnapshot,
    actorUid,
  });
  console.info('team_member_assignment_backfill_completed', {
    companyId,
    teamId,
    uid,
    repairedRecords: repairedRecords.total,
    byModule: repairedRecords.byModule,
  });

  await Promise.all([
    refreshTeamMemberCount({ companyId, teamId, actorUid }),
    previousTeamId && previousTeamId !== teamId
      ? refreshTeamMemberCount({ companyId, teamId: previousTeamId, actorUid })
      : Promise.resolve(),
  ]);

  return { companyId, teamId, uid, repairedRecords };
});

exports.removeUserFromTeam = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  validateCompanyId(companyId);

  const actorUid = await requireActiveCompanyAdmin(request, companyId);
  const targetUserRef = db.doc(`companies/${companyId}/users/${uid}`);
  const targetUserSnapshot = await targetUserRef.get();

  if (!targetUserSnapshot.exists) {
    throw new HttpsError('not-found', 'User was not found.');
  }

  const targetUser = targetUserSnapshot.data() || {};
  if (targetUser.companyId && targetUser.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'User does not belong to this company.');
  }
  if (!OPERATIONAL_TEAM_ROLES.has(targetUser.role)) {
    throw new HttpsError(
      'invalid-argument',
      'Only sales and marketing users can be team members.',
    );
  }

  const previousTeamId = optionalString(targetUser.teamId);
  const nextAssigneeSnapshot = {
    ...targetUser,
    teamId: '',
    teamName: '',
    managerId: '',
    managerName: '',
  };
  await targetUserRef.update({
    teamId: '',
    teamName: '',
    managerId: '',
    managerName: '',
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  });

  const repairedRecords = await backfillAssignedRecordsForUser({
    companyId,
    uid,
    assignee: nextAssigneeSnapshot,
    actorUid,
  });
  console.info('team_member_removal_backfill_completed', {
    companyId,
    previousTeamId,
    uid,
    repairedRecords: repairedRecords.total,
    byModule: repairedRecords.byModule,
  });

  if (previousTeamId) {
    await refreshTeamMemberCount({ companyId, teamId: previousTeamId, actorUid });
  }

  return { companyId, uid, repairedRecords };
});


exports.backfillTeamAssignedRecordSnapshots = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const teamId = requiredString(data.teamId, 'teamId');
  validateCompanyId(companyId);

  const actorUid = await requireActiveCompanyAdmin(request, companyId);
  const teamSnapshot = await db.doc(`companies/${companyId}/teams/${teamId}`).get();
  if (!teamSnapshot.exists) {
    throw new HttpsError('not-found', 'Team was not found.');
  }

  const team = teamSnapshot.data() || {};
  if (team.companyId && team.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'Team does not belong to this company.');
  }
  if (team.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Team is inactive.');
  }

  const usersSnapshot = await db.collection(`companies/${companyId}/users`)
    .where('teamId', '==', teamId)
    .get();

  const totals = {};
  let repairedRecords = 0;
  let repairedUsers = 0;
  let repairedUserProfiles = 0;
  const teamSnapshotPatch = {
    teamId,
    teamName: optionalString(team.name),
    managerId: optionalString(team.managerId),
    managerName: optionalString(team.managerName),
  };

  for (const userDoc of usersSnapshot.docs) {
    const user = userDoc.data() || {};
    if (!OPERATIONAL_TEAM_ROLES.has(user.role)) {
      continue;
    }

    const nextAssigneeSnapshot = {
      ...user,
      ...teamSnapshotPatch,
    };

    const userNeedsRepair =
      optionalString(user.teamName) !== teamSnapshotPatch.teamName ||
      optionalString(user.managerId) !== teamSnapshotPatch.managerId ||
      optionalString(user.managerName) !== teamSnapshotPatch.managerName;

    if (userNeedsRepair) {
      await userDoc.ref.set({
        ...teamSnapshotPatch,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: actorUid,
      }, { merge: true });
      repairedUserProfiles += 1;
    }

    const result = await backfillAssignedRecordsForUser({
      companyId,
      uid: userDoc.id,
      assignee: nextAssigneeSnapshot,
      actorUid,
    });
    repairedUsers += 1;
    repairedRecords += result.total;
    for (const [module, count] of Object.entries(result.byModule)) {
      totals[module] = (totals[module] || 0) + count;
    }
  }

  console.info('team_record_snapshot_backfill_completed', {
    companyId,
    teamId,
    repairedUsers,
    repairedUserProfiles,
    repairedRecords,
    totals,
  });

  return { companyId, teamId, repairedUsers, repairedUserProfiles, repairedRecords, totals };
});

exports.getCompanyDataHealthReport = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }

  const usersSnapshot = await db.collection(`companies/${companyId}/users`).get();
  const users = new Map();
  usersSnapshot.docs.forEach((doc) => {
    users.set(doc.id, doc.data() || {});
  });

  const modulePolicies = Object.entries(DATA_HEALTH_MODULE_POLICIES).map(
    ([module, policy]) => ({ module, ...policy }),
  );

  const issues = [];
  const counts = {
    missingSnapshots: 0,
    invalidAssignees: 0,
    inactiveAssignees: 0,
    staleTeamSnapshots: 0,
  };

  for (const policy of modulePolicies) {
    const snapshot = await db.collection(`companies/${companyId}/${policy.module}`)
      .limit(500)
      .get();
    snapshot.docs.forEach((doc) => {
      inspectAssignedRecord({
        companyId,
        modulePolicy: policy,
        doc,
        users,
        issues,
        counts,
      });
    });
  }

  return {
    companyId,
    generatedAt: new Date().toISOString(),
    counts,
    issues: issues.slice(0, 200),
    scannedLimitPerModule: 500,
  };
});


exports.getOperationalDataHealthReport = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);
  const actor = await requireDataHealthActor({
    request,
    companyId,
    allowPlatform: false,
    allowCompanyAdmin: true,
    allowManager: false,
  });

  const usersSnapshot = await db.collection(`companies/${companyId}/users`).get();
  const users = new Map();
  usersSnapshot.docs.forEach((doc) => {
    users.set(doc.id, doc.data() || {});
  });

  const modulePolicies = Object.entries(DATA_HEALTH_MODULE_POLICIES).map(
    ([module, policy]) => ({ module, ...policy }),
  );

  const issues = [];
  const counts = {
    missingSnapshots: 0,
    invalidAssignees: 0,
    inactiveAssignees: 0,
    staleTeamSnapshots: 0,
  };

  for (const policy of modulePolicies) {
    const snapshot = await db.collection(`companies/${companyId}/${policy.module}`)
      .limit(500)
      .get();
    snapshot.docs.forEach((doc) => {
      const record = doc.data() || {};
      if (!canActorInspectDataHealthRecord({ actor, record })) {
        return;
      }
      inspectAssignedRecord({
        companyId,
        modulePolicy: policy,
        doc,
        users,
        issues,
        counts,
      });
    });
  }

  return {
    companyId,
    generatedAt: new Date().toISOString(),
    counts,
    issues: issues.slice(0, 200),
    scannedLimitPerModule: 500,
  };
});

exports.reassignDataHealthRecord = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const module = requiredString(data.module, 'module');
  const recordId = requiredString(data.recordId, 'recordId');
  const newAssigneeUid = requiredString(data.newAssigneeUid, 'newAssigneeUid');
  validateCompanyId(companyId);

  const actor = await requireDataHealthActor({
    request,
    companyId,
    allowPlatform: false,
    allowCompanyAdmin: true,
    allowManager: false,
  });
  const policy = dataHealthPolicyFor(module);
  const recordRef = db.doc(`companies/${companyId}/${module}/${recordId}`);
  const [recordSnapshot, assigneeSnapshot] = await Promise.all([
    recordRef.get(),
    db.doc(`companies/${companyId}/users/${newAssigneeUid}`).get(),
  ]);

  if (!recordSnapshot.exists) {
    throw new HttpsError('not-found', 'Record was not found.');
  }
  if (!assigneeSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Selected assignee was not found.');
  }

  const record = recordSnapshot.data() || {};
  const assignee = assigneeSnapshot.data() || {};
  if (assignee.companyId && assignee.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'Selected user does not belong to this company.');
  }
  if (assignee.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Selected assignee is inactive.');
  }
  if (!policy.allowedRoles.has(assignee.role)) {
    throw new HttpsError('failed-precondition', 'Selected assignee is not eligible for this record.');
  }
  if (!canActorRepairDataHealthRecord({ actor, record })) {
    throw new HttpsError('permission-denied', 'You can only repair records in your allowed scope.');
  }
  if (!canActorAssignDataHealthUser({ actor, assignee })) {
    throw new HttpsError('permission-denied', 'You can only reassign to eligible users in your team.');
  }

  const previousAssignedTo = optionalString(record.assignedTo);
  const previousAssignedToName = optionalString(record.assignedToName);
  const update = {
    ...assignmentSnapshotFromAssignee(newAssigneeUid, assignee),
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actor.uid,
  };
  await recordRef.set(update, { merge: true });

  const changedFields = changedSnapshotFields(record, update);
  await writeDataHealthAuditLog({
    companyId,
    actor,
    module,
    recordId,
    record,
    policy,
    update,
    metadata: {
      repairAction: 'reassignDataHealthRecord',
      previousAssignedTo,
      previousAssignedToName,
      newAssignedTo: newAssigneeUid,
      newAssignedToName: optionalString(assignee.fullName),
      changedFields,
    },
  });

  if (module === 'leads') {
    await writeLeadDataHealthReassignTimeline({
      companyId,
      leadId: recordId,
      actor,
      previousAssignedToName: previousAssignedToName || previousAssignedTo,
      nextAssignedToName: optionalString(assignee.fullName) || newAssigneeUid,
    });
  }

  return { companyId, module, recordId, assignedTo: newAssigneeUid };
});

exports.backfillAssignedRecordSnapshots = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);
  const actor = await requireDataHealthActor({
    request,
    companyId,
    allowPlatform: true,
    allowCompanyAdmin: true,
    allowManager: false,
  });
  const module = requiredString(data.module, 'module');
  const recordId = requiredString(data.recordId, 'recordId');

  const policy = dataHealthPolicyFor(module);
  const recordRef = db.doc(`companies/${companyId}/${module}/${recordId}`);
  const recordSnapshot = await recordRef.get();
  if (!recordSnapshot.exists) {
    throw new HttpsError('not-found', 'Record was not found.');
  }

  const record = recordSnapshot.data() || {};
  if (!canActorRepairDataHealthRecord({ actor, record })) {
    throw new HttpsError('permission-denied', 'You can only repair records in your allowed scope.');
  }
  const assignedTo = optionalString(record.assignedTo);
  if (!assignedTo) {
    throw new HttpsError('failed-precondition', 'Record has no assignee to backfill.');
  }

  const assigneeSnapshot = await db
    .doc(`companies/${companyId}/users/${assignedTo}`)
    .get();
  if (!assigneeSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Assigned user was not found.');
  }

  const assignee = assigneeSnapshot.data() || {};
  if (assignee.companyId && assignee.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'Assigned user does not belong to this company.');
  }
  if (assignee.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Assigned user is inactive.');
  }
  if (!policy.allowedRoles.has(assignee.role)) {
    throw new HttpsError('failed-precondition', 'Assigned user is not eligible for this record.');
  }

  const snapshotUpdate = assignmentSnapshotFromAssignee(assignedTo, assignee);
  const changedFields = changedSnapshotFields(record, snapshotUpdate);
  if (Object.keys(changedFields).length === 0) {
    return {
      companyId,
      module,
      recordId,
      repaired: false,
      changedFields: {},
    };
  }

  await recordRef.set(snapshotUpdate, { merge: true });

  await writeDataHealthAuditLog({
    companyId,
    actor,
    module,
    recordId,
    record,
    policy,
    update: snapshotUpdate,
    metadata: {
      repairAction: 'backfillAssignedRecordSnapshots',
      changedFields,
    },
  });

  return {
    companyId,
    module,
    recordId,
    repaired: true,
    changedFields,
  };
});

exports.notifyDataHealthManager = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const module = requiredString(data.module, 'module');
  const recordId = requiredString(data.recordId, 'recordId');
  const issueType = requiredString(data.issueType, 'issueType');
  validateCompanyId(companyId);

  const actor = await requireDataHealthActor({
    request,
    companyId,
    allowPlatform: false,
    allowCompanyAdmin: true,
    allowManager: false,
  });
  const policy = dataHealthPolicyFor(module);
  const recordSnapshot = await db.doc(`companies/${companyId}/${module}/${recordId}`).get();
  if (!recordSnapshot.exists) {
    throw new HttpsError('not-found', 'Record was not found.');
  }

  const record = recordSnapshot.data() || {};
  if (!canActorRepairDataHealthRecord({ actor, record })) {
    throw new HttpsError('permission-denied', 'You can only notify managers for records in your allowed scope.');
  }

  const assignedTo = optionalString(record.assignedTo);
  const assignee = assignedTo ? await loadCompanyUserSafe(companyId, assignedTo) : null;
  const managerId = optionalString(record.managerId) ||
    optionalString(assignee && assignee.managerId);
  if (!managerId) {
    throw new HttpsError('failed-precondition', 'No responsible manager was found for this issue.');
  }

  const manager = await loadCompanyUserSafe(companyId, managerId);
  if (!manager || manager.isActive !== true || optionalString(manager.role) !== 'manager') {
    throw new HttpsError('failed-precondition', 'Responsible manager is not available.');
  }

  const recordTitle = assignedRecordTitle(record, policy, recordId);
  const route = dataHealthManagerCanOpenRecord({ managerId, manager, record, assignee })
    ? dataHealthRecordRoute(module, recordId)
    : '/dashboard';
  const issueLabel = dataHealthIssueNotificationLabel(issueType);
  const actorName = optionalString(actor.user.fullName) ||
    optionalString(actor.user.email) ||
    'Admin';

  const notificationId = await createCompanyNotification({
    companyId,
    recipientUid: managerId,
    recipientRole: 'manager',
    type: 'dataHealthIssue',
    module,
    recordId,
    recordTitle,
    recordSubtitle: issueLabel,
    route,
    actorUid: actor.uid,
    actorName,
    teamId: optionalString(record.teamId) || optionalString(assignee && assignee.teamId),
    teamName: optionalString(record.teamName) || optionalString(assignee && assignee.teamName),
    managerId,
    priority: issueType === 'inactiveAssignee' || issueType === 'ineligibleAssignee'
      ? 'high'
      : 'normal',
    metadata: {
      issueType,
      issueLabel,
      assignedTo,
      assignedToName: optionalString(record.assignedToName) ||
        optionalString(assignee && assignee.fullName),
      repairContext: 'assignmentSnapshotIssue',
    },
    fallbackTitle: 'Data health needs attention',
    fallbackBody: `${recordTitle} has a ${issueLabel} data health issue.`,
    dedupeKey: `data_health_manager_${companyId}_${module}_${recordId}_${issueType}_${managerId}`,
  });

  if (!notificationId) {
    throw new HttpsError('failed-precondition', 'Manager notification could not be created.');
  }

  return { companyId, module, recordId, managerId, notificationId };
});

exports.setCompanyActiveStatus = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const isActive = requiredBoolean(data.isActive, 'isActive');
  validateCompanyId(companyId);

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  const affectedUserIds = await listCompanyUserIds(companyId);
  if (!isActive) {
    await revokeRefreshTokensForUids(affectedUserIds);
  }
  await companyRef.update({
    isActive,
    status: isActive ? 'active' : 'inactive',
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: request.auth.uid,
  });
  await syncGlobalUserActiveStatuses(affectedUserIds);
  const actor = await platformActorSummary(actorUid);
  await createPlatformNotificationSafely('set_company_active_status', {
    type: 'companyStatusChanged',
    title: 'Company status changed',
    message: `${companyNotificationName(companyId, company)} is now ${isActive ? 'active' : 'inactive'}.`,
    severity: isActive ? 'success' : 'warning',
    source: 'company',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    companyId,
    companyName: companyNotificationName(companyId, company),
    metadata: {
      isActive,
      status: isActive ? 'active' : 'inactive',
    },
  });

  return { companyId, isActive };
});

exports.refreshCompanyStorageUsage = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};

  const bucket = admin.storage().bucket();
  const prefix = `companies/${companyId}/`;
  let pageToken;
  let totalBytes = 0;

  do {
    const [files, nextQuery] = await bucket.getFiles({
      prefix,
      autoPaginate: false,
      maxResults: 1000,
      pageToken,
    });
    for (const file of files) {
      const size = Number(file.metadata && file.metadata.size ? file.metadata.size : 0);
      if (Number.isFinite(size) && size > 0) {
        totalBytes += size;
      }
    }
    pageToken = nextQuery && nextQuery.pageToken;
  } while (pageToken);

  await companyRef.update({
    storageUsedBytes: totalBytes,
    storageUsageUpdatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: request.auth.uid,
  });
  const actor = await platformActorSummary(actorUid);
  const companyName = companyNotificationName(companyId, company);
  const limitBytes = storageLimitBytes(company);
  const usagePercent = limitBytes > 0 ? Math.round((totalBytes / limitBytes) * 10000) / 100 : 0;
  if (limitBytes > 0 && usagePercent >= 80) {
    const level = usagePercent >= 95 ? 'urgent' : 'warning';
    await createPlatformNotificationSafely('storage_near_limit', {
      id: `storage_near_limit_${companyId}_${level}`,
      type: 'storageNearLimit',
      title: 'Storage near limit',
      message: `${companyName} storage is at ${usagePercent}%.`,
      severity: level,
      source: 'storage',
      route: '/platform',
      actorId: actor.actorId,
      actorName: actor.actorName,
      actorEmail: actor.actorEmail,
      companyId,
      companyName,
      metadata: {
        storageUsedBytes: totalBytes,
        storageLimitBytes: limitBytes,
        usagePercent,
        threshold: usagePercent >= 95 ? 95 : 80,
      },
    });
  }

  return { companyId, storageUsedBytes: totalBytes };
});

exports.updateCompanyPlatformSettings = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }

  const update = {
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: request.auth.uid,
  };
  const current = companySnapshot.data() || {};

  if (Object.prototype.hasOwnProperty.call(data, 'name')) {
    update.name = requiredString(data.name, 'name');
  }
  if (Object.prototype.hasOwnProperty.call(data, 'displayName')) {
    update.displayName = requiredString(data.displayName, 'displayName');
  }
  if (Object.prototype.hasOwnProperty.call(data, 'status')) {
    update.status = requiredString(data.status, 'status');
    validateCompanyStatus(update.status);
    if (update.status === 'active') {
      update.isActive = true;
      update.paymentStatus = 'paid';
      update.paymentUpdatedAt = FieldValue.serverTimestamp();
      update.paymentUpdatedBy = actorUid;
      update.trialEndsAt = FieldValue.delete();
      update.trialConvertedAt = FieldValue.serverTimestamp();
    }
  }
  if (Object.prototype.hasOwnProperty.call(data, 'isActive')) {
    update.isActive = requiredBoolean(data.isActive, 'isActive');
  }
  if (Object.prototype.hasOwnProperty.call(data, 'trialDurationValue')) {
    const duration = positiveInteger(data.trialDurationValue, 'trialDurationValue');
    const unit = normalizeTrialUnit(data.trialDurationUnit);
    const trial = trialDatesFromDuration(duration, unit);
    update.trialEndsAt = trial.trialEndsAt;
    update.trialStartedAt = trial.trialStartedAt;
    update.trialDurationValue = trial.trialDurationValue;
    update.trialDurationUnit = trial.trialDurationUnit;
    update.trialDays = trial.trialDays;
    update.status = 'trial';
    update.isActive = true;
    update.paymentStatus = 'trial';
  } else if (Object.prototype.hasOwnProperty.call(data, 'trialEndsAt')) {
    const trialEndsAt = parseFutureDate(data.trialEndsAt, 'trialEndsAt');
    update.trialEndsAt = trialEndsAt;
    update.trialStartedAt = FieldValue.serverTimestamp();
    if (!Object.prototype.hasOwnProperty.call(update, 'status')) {
      update.status = 'trial';
    }
    if (!Object.prototype.hasOwnProperty.call(update, 'isActive')) {
      update.isActive = true;
    }
    update.paymentStatus = 'trial';
  }

  if (Object.prototype.hasOwnProperty.call(data, 'settings')) {
    const settings = requiredObject(data.settings, 'settings');
    const validatedSettings = validateCompanySettings(settings);
    for (const [key, value] of Object.entries(validatedSettings)) {
      update[`settings.${key}`] = value;
    }
  }

  if (Object.prototype.hasOwnProperty.call(data, 'limits')) {
    const limits = requiredObject(data.limits, 'limits');
    const validatedLimits = validateCompanyLimits(limits);
    for (const [key, value] of Object.entries(validatedLimits)) {
      update[`limits.${key}`] = value;
    }
  }

  if (Object.prototype.hasOwnProperty.call(data, 'features')) {
    const features = requiredObject(data.features, 'features');
    const validatedFeatures = validateCompanyFeatures(features);
    for (const [key, value] of Object.entries(validatedFeatures)) {
      update[`features.${key}`] = value;
    }
  }

  if (update.status === 'inactive') {
    update.isActive = false;
  } else if (
    (update.status === 'active' || update.status === 'trial') &&
    !Object.prototype.hasOwnProperty.call(update, 'isActive')
  ) {
    update.isActive = true;
  } else if (update.isActive === false && !update.status) {
    update.status = 'inactive';
  } else if (update.isActive === true && current.status === 'inactive') {
    update.status = 'active';
  }

  const changedCompanyAccess =
    Object.prototype.hasOwnProperty.call(update, 'status') ||
    Object.prototype.hasOwnProperty.call(update, 'isActive');
  const affectedUserIds = changedCompanyAccess
    ? await listCompanyUserIds(companyId)
    : [];
  if (update.isActive === false || update.status === 'inactive') {
    await revokeRefreshTokensForUids(affectedUserIds);
  }

  await companyRef.update(update);
  if (changedCompanyAccess) {
    await syncGlobalUserActiveStatuses(affectedUserIds);
  }

  const nextCompanyName = update.displayName || update.name;
  if (nextCompanyName) {
    await updateMembershipCompanyNames(companyId, nextCompanyName);
  }
  const actor = await platformActorSummary(actorUid);
  const companyName = sanitizePlainString(
    optionalString(nextCompanyName) || companyNotificationName(companyId, current),
    240,
  );
  const changedFeatures = Object.keys(update).filter((key) => key.startsWith('features.'));
  const changedLimits = Object.keys(update).filter((key) => key.startsWith('limits.'));
  const changedSettings = Object.keys(update).filter((key) => key.startsWith('settings.'));
  const changedStatus =
    Object.prototype.hasOwnProperty.call(update, 'status') ||
    Object.prototype.hasOwnProperty.call(update, 'isActive');
  const notificationType = changedStatus
    ? 'companyStatusChanged'
    : changedLimits.length > 0
      ? 'companyLimitChanged'
      : changedFeatures.length > 0
        ? 'companyFeatureChanged'
        : 'companySettingsChanged';
  const severity = changedStatus && update.isActive === false ? 'warning' : 'info';
  await createPlatformNotificationSafely('update_company_platform_settings', {
    type: notificationType,
    title: 'Company settings changed',
    message: `${companyName} platform settings were updated.`,
    severity,
    source: 'company',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    companyId,
    companyName,
    metadata: {
      changedFeatures: changedFeatures.join(','),
      changedLimits: changedLimits.join(','),
      changedSettings: changedSettings.join(','),
      status: update.status || '',
      isActive: Object.prototype.hasOwnProperty.call(update, 'isActive') ? update.isActive : null,
    },
  });

  return { companyId };
});

exports.markCompanyPaymentPaid = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);
  const amount = paymentAmountValue(data.amount);
  const currency = normalizeCurrency(data.currency);
  const paymentDate = parseOptionalDate(data.paymentDate) || new Date();
  const nextPaymentDueAt = parseFutureDate(data.nextPaymentDueAt, 'nextPaymentDueAt');
  const paymentCycle = normalizePaymentCycle(data.paymentCycle);
  const notes = sanitizePlainString(optionalString(data.notes), 500);

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  const previousStatus = paymentStatusForCompany(company);
  const actor = await platformActorSummary(actorUid);
  const companyName = companyNotificationName(companyId, company);
  const affectedUserIds = await listCompanyUserIds(companyId);
  const batch = db.batch();
  const now = FieldValue.serverTimestamp();

  batch.update(companyRef, {
    status: 'active',
    isActive: true,
    paymentStatus: 'paid',
    lastPaymentAt: paymentDate,
    nextPaymentDueAt,
    paymentAmount: amount,
    paymentCurrency: currency,
    paymentCycle,
    paymentNotes: notes,
    paymentUpdatedAt: now,
    paymentUpdatedBy: actorUid,
    gracePeriodEndsAt: FieldValue.delete(),
    suspendedAt: FieldValue.delete(),
    suspendedReason: FieldValue.delete(),
    trialEndsAt: FieldValue.delete(),
    trialConvertedAt: now,
    paymentReminderState: {},
    updatedAt: now,
    updatedBy: actorUid,
  });
  addPaymentHistoryToBatch(batch, {
    companyId,
    companyName,
    action: 'markedPaid',
    amount,
    currency,
    paymentDate,
    nextPaymentDueAt,
    previousStatus,
    newStatus: 'paid',
    notes,
    actor,
    now,
  });
  await batch.commit();
  await syncGlobalUserActiveStatuses(affectedUserIds);
  await createPlatformPaymentNotification({
    type: 'paymentMarkedPaid',
    title: 'Payment marked paid',
    message: `${companyName} was marked as paid.`,
    companyId,
    companyName,
    actor,
    metadata: { amount, currency, nextPaymentDueAt: nextPaymentDueAt.toISOString() },
  });
  await notifyCompanyAdminsForPaymentState({
    companyId,
    company: { ...company, paymentStatus: 'paid' },
    paymentStatus: 'paid',
    dedupeSuffix: `paid_${Date.now()}`,
  });
  return { companyId, paymentStatus: 'paid' };
});

exports.extendCompanyPaymentDueDate = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);
  const nextPaymentDueAt = parseFutureDate(data.nextPaymentDueAt, 'nextPaymentDueAt');
  const notes = sanitizePlainString(optionalString(data.notes), 500);
  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  const previousStatus = paymentStatusForCompany(company);
  const actor = await platformActorSummary(actorUid);
  const companyName = companyNotificationName(companyId, company);
  const now = FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.update(companyRef, {
    paymentStatus: previousStatus === 'suspended' ? 'suspended' : 'paid',
    nextPaymentDueAt,
    paymentNotes: notes || optionalString(company.paymentNotes),
    paymentUpdatedAt: now,
    paymentUpdatedBy: actorUid,
    paymentReminderState: {},
    updatedAt: now,
    updatedBy: actorUid,
  });
  addPaymentHistoryToBatch(batch, {
    companyId,
    companyName,
    action: 'extended',
    amount: paymentAmountValue(company.paymentAmount, true),
    currency: normalizeCurrency(company.paymentCurrency, true),
    paymentDate: dateFromCallableValue(company.lastPaymentAt),
    nextPaymentDueAt,
    previousStatus,
    newStatus: previousStatus === 'suspended' ? 'suspended' : 'paid',
    notes,
    actor,
    now,
  });
  await batch.commit();
  await createPlatformPaymentNotification({
    type: 'paymentDueSoon',
    title: 'Payment due date extended',
    message: `${companyName} payment due date was extended.`,
    companyId,
    companyName,
    actor,
    metadata: { nextPaymentDueAt: nextPaymentDueAt.toISOString() },
  });
  return { companyId, nextPaymentDueAt: nextPaymentDueAt.toISOString() };
});

exports.updateCompanyPaymentStatus = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);
  const paymentStatus = normalizePaymentStatus(data.paymentStatus);
  const notes = sanitizePlainString(optionalString(data.notes), 500);
  const suspendedReason = sanitizePlainString(optionalString(data.suspendedReason), 500);
  const nextPaymentDueAt = parseOptionalDate(data.nextPaymentDueAt);
  const gracePeriodEndsAt = parseOptionalDate(data.gracePeriodEndsAt);
  if (paymentStatus === 'gracePeriod' && !gracePeriodEndsAt) {
    throw new HttpsError('invalid-argument', 'gracePeriodEndsAt is required.');
  }
  if (paymentStatus === 'suspended' && !suspendedReason && !notes) {
    throw new HttpsError('invalid-argument', 'Suspension reason is required.');
  }

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  const previousStatus = paymentStatusForCompany(company);
  const companyName = companyNotificationName(companyId, company);
  const actor = await platformActorSummary(actorUid);
  const now = FieldValue.serverTimestamp();
  const update = {
    paymentStatus,
    paymentNotes: notes || optionalString(company.paymentNotes),
    paymentUpdatedAt: now,
    paymentUpdatedBy: actorUid,
    paymentReminderState: {},
    updatedAt: now,
    updatedBy: actorUid,
  };

  if (nextPaymentDueAt) {
    update.nextPaymentDueAt = nextPaymentDueAt;
  }
  if (paymentStatus === 'gracePeriod') {
    update.status = 'active';
    update.isActive = true;
    update.gracePeriodEndsAt = gracePeriodEndsAt;
    update.suspendedAt = FieldValue.delete();
    update.suspendedReason = FieldValue.delete();
  } else if (paymentStatus === 'suspended') {
    update.status = 'inactive';
    update.isActive = false;
    update.suspendedAt = now;
    update.suspendedReason = suspendedReason || notes;
  } else if (paymentStatus === 'paid' || paymentStatus === 'dueSoon' || paymentStatus === 'overdue') {
    update.status = 'active';
    update.isActive = true;
    update.gracePeriodEndsAt = FieldValue.delete();
    update.suspendedAt = FieldValue.delete();
    update.suspendedReason = FieldValue.delete();
  } else if (paymentStatus === 'inactive') {
    update.status = 'inactive';
    update.isActive = false;
  }

  const affectedUserIds = await listCompanyUserIds(companyId);
  if (update.isActive === false) {
    await revokeRefreshTokensForUids(affectedUserIds);
  }

  const batch = db.batch();
  batch.update(companyRef, update);
  const action = paymentHistoryActionForStatus(paymentStatus, previousStatus, notes);
  addPaymentHistoryToBatch(batch, {
    companyId,
    companyName,
    action,
    amount: paymentAmountValue(company.paymentAmount, true),
    currency: normalizeCurrency(company.paymentCurrency, true),
    paymentDate: dateFromCallableValue(company.lastPaymentAt),
    nextPaymentDueAt: nextPaymentDueAt || dateFromCallableValue(company.nextPaymentDueAt),
    previousStatus,
    newStatus: paymentStatus,
    notes: suspendedReason || notes,
    actor,
    now,
  });
  await batch.commit();
  await syncGlobalUserActiveStatuses(affectedUserIds);

  await createPlatformPaymentNotification({
    type: platformPaymentNotificationType(paymentStatus, action),
    title: platformPaymentNotificationTitle(paymentStatus, action),
    message: `${companyName}: ${platformPaymentNotificationTitle(paymentStatus, action)}.`,
    companyId,
    companyName,
    actor,
    metadata: { previousStatus, paymentStatus },
  });
  await notifyCompanyAdminsForPaymentState({
    companyId,
    company: { ...company, paymentStatus, gracePeriodEndsAt },
    paymentStatus,
    dedupeSuffix: `${paymentStatus}_${Date.now()}`,
  });

  return { companyId, paymentStatus };
});

exports.recordReportExportActivity = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const actorUid = request.auth && request.auth.uid ? request.auth.uid : '';
  if (!actorUid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'This role cannot export reports.');
  }
  await requireCompanyExportsEnabled(companyId);

  const exportType = enumValueOrDefault(
    data.exportType,
    REPORT_EXPORT_TYPES,
    'reportsExport',
  );
  const reportType = enumValueOrDefault(
    data.reportType || data.exportedModule,
    REPORT_EXPORT_MODULES,
    'leads',
  );
  const dateRangePreset = enumValueOrDefault(
    data.dateRangePreset,
    REPORT_EXPORT_DATE_RANGES,
    'thisMonth',
  );
  const exportScope = enumValueOrDefault(
    data.exportScope,
    REPORT_EXPORT_SCOPES,
    exportScopeForRole(actorRole),
  );

  assertReportExportAllowed({ actorRole, exportType, reportType, exportScope });

  const rowCount = boundedExportInteger(data.rowCount, 0, 2000);
  const selectedColumns = safeStringList(data.selectedColumns, 40, 80);
  const selectedColumnsCount = boundedExportInteger(
    data.selectedColumnsCount,
    selectedColumns.length,
    200,
  );
  const labels = serverExportLabels(data.labels);
  const exportedModules = safeStringList(data.exportedModules, 20, 80)
    .filter((module) => REPORT_EXPORT_MODULES.has(module));
  const exportedModuleLabels = exportedModules.length > 1
    ? exportedModules.map((module) => labelForExport(labels, `module.${module}`, module))
    : [];
  const exportedModulesLabel = exportedModuleLabels.length > 1
    ? exportedModuleLabels.join(', ')
    : '';
  const reportTypeLabel = sanitizeLogText(
    exportedModulesLabel || optionalString(data.reportTypeLabel) || labelForExport(labels, `module.${reportType}`, reportType),
    220,
  );
  const dateRangeLabel = sanitizeLogText(
    optionalString(data.dateRangeLabel) || dateRangePreset,
    120,
  );
  const filtersSummary = sanitizeLogText(optionalString(data.filtersSummary), 300);
  const fileFormat = optionalString(data.fileFormat).toLowerCase() === 'excel'
    ? 'Excel'
    : 'Excel';
  const exportedAt = new Date();
  const exportedAtIso = exportedAt.toISOString();
  const exportedAtLabel = exportedAtIso.slice(0, 16).replace('T', ' ');
  const limitedByCap = data.limitedByCap === true;
  const module = exportType === 'auditLogsExport' ? 'auditLogs' : 'reports';
  const actorName = sanitizeLogText(
    optionalString(actor.fullName) || optionalString(actor.email) || actorRole,
    160,
  );
  const actorEmail = sanitizeLogText(optionalString(actor.email), 180);
  const exportScopeSnapshot = await resolveExportActorScope({
    companyId,
    actor,
    actorUid,
    actorRole,
    actorName,
  });
  const teamId = exportScopeSnapshot.teamId;
  const teamName = exportScopeSnapshot.teamName;
  const managerId = exportScopeSnapshot.managerId;
  const managerName = exportScopeSnapshot.managerName;

  const auditRef = db.collection(`companies/${companyId}/audit_logs`).doc();
  const notificationResult = await createExportSupervisorNotifications({
    companyId,
    actorUid,
    actorRole,
    actorName,
    actorEmail,
    teamId,
    teamName,
    managerId,
    auditLogId: auditRef.id,
    exportType,
    reportType,
    reportTypeLabel,
    exportedModules,
    exportedModuleLabels,
    dateRangeLabel,
    exportedAtLabel,
    exportScope,
    rowCount,
  });

  await auditRef.set({
    id: auditRef.id,
    companyId,
    actorId: actorUid,
    actorName,
    actorEmail,
    actorRole,
    action: 'exported',
    module,
    recordId: reportType,
    recordTitle: reportTypeLabel,
    recordSubtitle: `${fileFormat} - ${dateRangeLabel}`,
    assignedTo: actorRole === 'salesAgent' || actorRole === 'marketing'
      ? actorUid
      : '',
    teamId,
    teamName,
    managerId,
    managerName,
    createdAt: FieldValue.serverTimestamp(),
    metadata: {
      exportType,
      reportType,
      exportedModule: reportType,
      reportTypeLabel,
      exportedModules,
      exportedModuleLabels,
      exportedModulesLabel,
      dateRangePreset,
      dateRangeLabel,
      exportedAt: exportedAtIso,
      filtersSummary,
      selectedColumns,
      selectedColumnsCount,
      rowCount,
      fileFormat,
      exportScope,
      limitedByCap,
      auditLogId: auditRef.id,
      notifiedAdminCount: notificationResult.notifiedAdminCount,
      notifiedManagerCount: notificationResult.notifiedManagerCount,
    },
  });

  return {
    auditLogId: auditRef.id,
    notifiedAdminCount: notificationResult.notifiedAdminCount,
    notifiedManagerCount: notificationResult.notifiedManagerCount,
  };
});


exports.generateReportExportFile = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const actorUid = request.auth && request.auth.uid ? request.auth.uid : '';
  if (!actorUid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'This role cannot export reports.');
  }
  await requireCompanyExportsEnabled(companyId);

  const exportType = enumValueOrDefault(
    data.exportType,
    REPORT_EXPORT_TYPES,
    'reportsExport',
  );
  const reportType = enumValueOrDefault(
    data.reportType || data.exportedModule,
    REPORT_EXPORT_MODULES,
    'leads',
  );
  const dateRangePreset = enumValueOrDefault(
    data.dateRangePreset,
    REPORT_EXPORT_DATE_RANGES,
    'thisMonth',
  );
  const exportScope = enumValueOrDefault(
    data.exportScope,
    REPORT_EXPORT_SCOPES,
    exportScopeForRole(actorRole),
  );
  assertReportExportAllowed({ actorRole, exportType, reportType, exportScope });

  const labels = serverExportLabels(data.labels);
  const reportTypeLabel = sanitizeLogText(
    optionalString(data.reportTypeLabel) || labelForExport(labels, `module.${reportType}`, reportType),
    160,
  );
  const dateRangeLabel = sanitizeLogText(
    optionalString(data.dateRangeLabel) || labelForExport(labels, `dateRange.${dateRangePreset}`, dateRangePreset),
    120,
  );
  const filtersSummary = sanitizeLogText(optionalString(data.filtersSummary), 300);
  const statusFilter = optionalString(data.statusFilter);
  const assigneeId = optionalString(data.assigneeId);
  const includeArchived = data.includeArchived === true;
  const outputLanguage = optionalString(data.outputLanguage) === 'ar' ? 'ar' : 'en';
  const selectedColumns = safeStringList(data.selectedColumns, 80, 80);
  const exportScopeSnapshot = await resolveExportActorScope({
    companyId,
    actor,
    actorUid,
    actorRole,
    actorName: sanitizeLogText(optionalString(actor.fullName) || optionalString(actor.email) || actorRole, 160),
  });
  const dateWindow = serverExportDateWindow({
    dateRangePreset,
    customStart: data.customStart,
    customEnd: data.customEnd,
  });

  const dataset = await buildServerReportDataset({
    companyId,
    actorUid,
    actorRole,
    teamId: exportScopeSnapshot.teamId,
    managerId: exportScopeSnapshot.managerId,
    reportType,
    labels,
    selectedColumns,
    dateWindow,
    statusFilter,
    assigneeId,
    includeArchived,
  });

  const generatedAt = new Date();
  const exportedAtIso = generatedAt.toISOString();
  const exportedAtLabel = exportedAtIso.slice(0, 16).replace('T', ' ');
  const actorName = sanitizeLogText(
    optionalString(actor.fullName) || optionalString(actor.email) || actorRole,
    160,
  );
  const actorEmail = sanitizeLogText(optionalString(actor.email), 180);
  const auditRef = db.collection(`companies/${companyId}/audit_logs`).doc();

  const notificationResult = await createExportSupervisorNotifications({
    companyId,
    actorUid,
    actorRole,
    actorName,
    actorEmail,
    teamId: exportScopeSnapshot.teamId,
    teamName: exportScopeSnapshot.teamName,
    managerId: exportScopeSnapshot.managerId,
    auditLogId: auditRef.id,
    exportType,
    reportType,
    reportTypeLabel,
    dateRangeLabel,
    exportedAtLabel,
    exportScope,
    rowCount: dataset.recordCount,
  });

  const fileFormat = 'Excel';
  await auditRef.set({
    id: auditRef.id,
    companyId,
    actorId: actorUid,
    actorName,
    actorEmail,
    actorRole,
    action: 'exported',
    module: exportType === 'auditLogsExport' ? 'auditLogs' : 'reports',
    recordId: reportType,
    recordTitle: reportTypeLabel,
    recordSubtitle: `${fileFormat} - ${dateRangeLabel}`,
    assignedTo: actorRole === 'salesAgent' || actorRole === 'marketing'
      ? actorUid
      : '',
    teamId: exportScopeSnapshot.teamId,
    teamName: exportScopeSnapshot.teamName,
    managerId: exportScopeSnapshot.managerId,
    managerName: exportScopeSnapshot.managerName,
    createdAt: FieldValue.serverTimestamp(),
    metadata: {
      exportType,
      reportType,
      exportedModule: reportType,
      reportTypeLabel,
      dateRangePreset,
      dateRangeLabel,
      exportedAt: exportedAtIso,
      filtersSummary,
      selectedColumns: dataset.columns.map((column) => column.key).slice(0, 80),
      selectedColumnsCount: dataset.columns.length,
      rowCount: dataset.recordCount,
      fileFormat,
      exportScope,
      limitedByCap: dataset.limitedByCap,
      generatedServerSide: true,
      auditLogId: auditRef.id,
      notifiedAdminCount: notificationResult.notifiedAdminCount,
      notifiedManagerCount: notificationResult.notifiedManagerCount,
    },
  });

  const companyName = sanitizeLogText(optionalString(data.companyName) || companyId, 160);
  const fileName = `masar_${companyId}_${reportType}_${serverExportFileStamp(generatedAt)}.xlsx`;
  const workbook = buildServerXlsxWorkbook({
    title: 'Masar CRM',
    subtitle: reportTypeLabel,
    summaryRows: [
      [labelForExport(labels, 'company', 'Company'), companyName],
      [labelForExport(labels, 'reportName', 'Report'), reportTypeLabel],
      [labelForExport(labels, 'scope', 'Scope'), serverExportScopeLabel(labels, exportScope)],
      [labelForExport(labels, 'dateRange', 'Date range'), dateRangeLabel],
      [labelForExport(labels, 'generatedBy', 'Generated by'), actorName],
      [labelForExport(labels, 'generatedAt', 'Generated at'), exportedAtLabel],
      [labelForExport(labels, 'recordCount', 'Record count'), String(dataset.recordCount)],
      [labelForExport(labels, 'filtersSummary', 'Filters'), filtersSummary],
    ],
    columns: dataset.columns.map((column) => column.label),
    rows: dataset.rows,
    summarySheetName: labelForExport(labels, 'reportSummary', 'Summary'),
    dataSheetName: labelForExport(labels, 'dataSheet', 'Data'),
    rtl: outputLanguage === 'ar',
  });

  return {
    fileName,
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    base64Data: workbook.toString('base64'),
    generatedAt: exportedAtIso,
    recordCount: dataset.recordCount,
    auditLogId: auditRef.id,
    notifiedAdminCount: notificationResult.notifiedAdminCount,
    notifiedManagerCount: notificationResult.notifiedManagerCount,
  };
});

function serverExportLabels(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    return {};
  }
  const result = {};
  for (const [key, value] of Object.entries(raw)) {
    const cleanKey = sanitizeLogText(String(key), 120);
    if (!cleanKey) continue;
    result[cleanKey] = sanitizeLogText(String(value ?? ''), 240);
  }
  return result;
}

function labelForExport(labels, key, fallback) {
  return labels[key] || fallback || key;
}

function serverExportScopeLabel(labels, scope) {
  switch (scope) {
    case 'companyWide': return labelForExport(labels, 'scope.companyWide', 'Company-wide');
    case 'teamOnly': return labelForExport(labels, 'scope.myTeam', 'My team');
    case 'assignedOnly': return labelForExport(labels, 'scope.myRecords', 'My records');
    default: return labelForExport(labels, 'scope.restricted', scope || 'Restricted');
  }
}

function serverExportDateWindow({ dateRangePreset, customStart, customEnd }) {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  switch (dateRangePreset) {
    case 'today':
      return { start: today, end: new Date(today.getTime() + 24 * 60 * 60 * 1000) };
    case 'thisWeek': {
      const day = today.getDay();
      const start = new Date(today.getTime() - day * 24 * 60 * 60 * 1000);
      return { start, end: new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000) };
    }
    case 'thisMonth':
      return {
        start: new Date(today.getFullYear(), today.getMonth(), 1),
        end: new Date(today.getFullYear(), today.getMonth() + 1, 1),
      };
    case 'lastMonth':
      return {
        start: new Date(today.getFullYear(), today.getMonth() - 1, 1),
        end: new Date(today.getFullYear(), today.getMonth(), 1),
      };
    case 'custom': {
      const start = new Date(optionalString(customStart));
      const end = new Date(optionalString(customEnd));
      if (!Number.isNaN(start.getTime()) && !Number.isNaN(end.getTime())) {
        return {
          start: new Date(start.getFullYear(), start.getMonth(), start.getDate()),
          end: new Date(end.getFullYear(), end.getMonth(), end.getDate() + 1),
        };
      }
      return null;
    }
    case 'allTime':
    default:
      return null;
  }
}

async function buildServerReportDataset({
  companyId,
  actorUid,
  actorRole,
  teamId,
  managerId,
  reportType,
  labels,
  selectedColumns,
  dateWindow,
  statusFilter,
  assigneeId,
  includeArchived,
}) {
  const collectionName = serverExportCollection(reportType);
  if (!collectionName) {
    throw new HttpsError('invalid-argument', 'Unsupported report export type.');
  }
  if (reportType === 'properties' && actorRole !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can export properties.');
  }
  const docs = await fetchServerExportDocs({
    companyId,
    collectionName,
    actorUid,
    actorRole,
    teamId,
    managerId,
  });
  const columns = serverExportColumns(reportType, selectedColumns, labels);
  const rows = [];
  for (const doc of docs) {
    const row = { id: doc.id, ...(doc.data || {}) };
    if (!serverExportRowAllowed({ row, actorUid, actorRole, teamId, managerId, reportType })) continue;
    if (!includeArchived && row.isArchived === true) continue;
    if (row.isActive === false && ['clients', 'deals', 'tasks'].includes(reportType)) continue;
    if (assigneeId && optionalString(row.assignedTo) !== assigneeId) continue;
    if (statusFilter && !serverExportMatchesStatus(row, reportType, statusFilter)) continue;
    if (dateWindow && !serverExportMatchesDate(row, reportType, dateWindow)) continue;
    rows.push(columns.map((column) => serverExportCell(row, column.key)));
    if (rows.length >= 2000) break;
  }
  return {
    columns,
    rows,
    recordCount: rows.length,
    limitedByCap: rows.length >= 2000,
  };
}

function serverExportCollection(reportType) {
  switch (reportType) {
    case 'leads': return 'leads';
    case 'clients': return 'clients';
    case 'deals':
    case 'pipeline': return 'deals';
    case 'tasks':
    case 'followUps': return 'tasks';
    case 'appointments': return 'appointments';
    case 'properties': return 'properties';
    case 'teamPerformance': return 'users';
    case 'auditSummary':
    case 'auditLogs': return 'audit_logs';
    default: return null;
  }
}

async function fetchServerExportDocs({ companyId, collectionName, actorUid, actorRole, teamId, managerId }) {
  const collection = db.collection(`companies/${companyId}/${collectionName}`);
  const snapshots = [];
  if (actorRole === 'admin') {
    snapshots.push(await collection.limit(2001).get());
  } else if (actorRole === 'manager') {
    snapshots.push(await collection.where('managerId', '==', actorUid).limit(1200).get());
    if (managerId && managerId !== actorUid) {
      snapshots.push(await collection.where('managerId', '==', managerId).limit(1200).get());
    }
    if (teamId) {
      snapshots.push(await collection.where('teamId', '==', teamId).limit(1200).get());
    }
  } else if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    snapshots.push(await collection.where('assignedTo', '==', actorUid).limit(2001).get());
  }
  const byId = new Map();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      byId.set(doc.id, { id: doc.id, data: doc.data() || {} });
    }
  }
  return [...byId.values()];
}

function serverExportRowAllowed({ row, actorUid, actorRole, teamId, managerId, reportType }) {
  if (actorRole === 'admin') return true;
  if (actorRole === 'manager') {
    const rowManagerId = optionalString(row.managerId);
    const rowTeamId = optionalString(row.teamId);
    return (rowManagerId && (rowManagerId === actorUid || rowManagerId === managerId)) ||
      (teamId && rowTeamId === teamId);
  }
  if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    return optionalString(row.assignedTo) === actorUid;
  }
  return false;
}

function serverExportMatchesStatus(row, reportType, statusFilter) {
  const value = reportType === 'deals' || reportType === 'pipeline'
    ? optionalString(row.stage)
    : optionalString(row.status);
  return !statusFilter || value === statusFilter;
}

function serverExportMatchesDate(row, reportType, window) {
  const raw = reportType === 'appointments'
    ? row.scheduledAt
    : reportType === 'followUps'
      ? row.dueDate
      : row.createdAt || row.updatedAt;
  const date = serverExportDate(raw);
  if (!date) return false;
  return date >= window.start && date < window.end;
}

function serverExportDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (typeof value === 'number') return new Date(value);
  return null;
}

function serverExportColumns(reportType, selectedColumns, labels) {
  const defaults = serverExportDefaultColumns(reportType);
  const ids = selectedColumns.length > 0
    ? selectedColumns.filter((id) => defaults.includes(id))
    : defaults;
  return ids.map((key) => ({ key, label: labelForExport(labels, `column.${key}`, humanizeServerExportKey(key)) }));
}

function serverExportDefaultColumns(reportType) {
  switch (reportType) {
    case 'leads': return ['leadName', 'phone', 'email', 'status', 'priority', 'source', 'assignedTo', 'team', 'manager', 'createdAt', 'updatedAt'];
    case 'clients': return ['clientName', 'phone', 'email', 'assignedTo', 'team', 'manager', 'createdAt', 'updatedAt'];
    case 'deals':
    case 'pipeline': return ['dealTitle', 'client', 'property', 'stage', 'value', 'commission', 'assignedTo', 'team', 'manager', 'createdAt', 'updatedAt'];
    case 'tasks':
    case 'followUps': return ['title', 'status', 'priority', 'dueDate', 'assignedTo', 'team', 'manager', 'relatedType', 'relatedTitle', 'createdAt', 'updatedAt'];
    case 'appointments': return ['title', 'scheduledAt', 'status', 'appointmentType', 'assignedTo', 'team', 'manager', 'relatedType', 'relatedTitle', 'location', 'createdAt', 'updatedAt'];
    case 'properties': return ['propertyTitle', 'propertyType', 'listingType', 'status', 'price', 'location', 'bedrooms', 'bathrooms', 'area', 'assignedTo', 'createdAt', 'updatedAt', 'imageCount', 'archived'];
    case 'teamPerformance': return ['fullName', 'email', 'role', 'team', 'manager', 'isActive', 'createdAt', 'updatedAt'];
    case 'auditSummary':
    case 'auditLogs': return ['createdAt', 'module', 'action', 'recordTitle', 'actor', 'assignedTo', 'team', 'manager'];
    default: return ['title', 'status', 'assignedTo', 'createdAt'];
  }
}

function serverExportCell(row, key) {
  switch (key) {
    case 'leadName': return cleanCell(row.fullName || row.name || row.title);
    case 'clientName': return cleanCell(row.fullName || row.clientName || row.name);
    case 'dealTitle': return cleanCell(row.title || row.clientName || row.propertyTitle || row.id);
    case 'propertyTitle': return cleanCell(row.title || row.propertyTitle || row.name);
    case 'appointmentType': return cleanCell(row.type || row.appointmentType);
    case 'relatedType': return cleanCell(row.relatedType);
    case 'relatedTitle': return cleanCell(row.relatedTitle || row.recordTitle);
    case 'assignedTo': return cleanCell(row.assignedToName || row.assignedToEmail || row.assignedTo);
    case 'team': return cleanCell(row.teamName || row.teamId);
    case 'manager': return cleanCell(row.managerName || row.managerId);
    case 'client': return cleanCell(row.clientName || row.clientTitle || row.clientId);
    case 'property': return cleanCell(row.propertyTitle || row.propertyId);
    case 'value': return cleanCell(row.value || row.dealValue || row.amount);
    case 'imageCount': return Array.isArray(row.imageUrls) ? String(row.imageUrls.length) : cleanCell(row.imageCount);
    case 'actor': return cleanCell(row.actorName || row.actorEmail || row.actorId);
    case 'role': return cleanCell(row.role || row.actorRole);
    case 'createdAt':
    case 'updatedAt':
    case 'scheduledAt':
    case 'dueDate':
    case 'expectedCloseDate': return formatServerExportDate(row[key]);
    default: return cleanCell(row[key]);
  }
}

function cleanCell(value) {
  if (value === null || value === undefined) return '';
  if (typeof value === 'boolean') return value ? 'Yes' : 'No';
  if (typeof value === 'number') return String(value);
  if (typeof value.toDate === 'function') return formatServerExportDate(value);
  if (Array.isArray(value)) return value.map(cleanCell).filter(Boolean).join(', ');
  if (typeof value === 'object') return '';
  return sanitizeLogText(String(value), 500);
}

function formatServerExportDate(value) {
  const date = serverExportDate(value);
  if (!date) return '';
  return date.toISOString().slice(0, 16).replace('T', ' ');
}

function humanizeServerExportKey(key) {
  return String(key || '')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/[_-]+/g, ' ')
    .replace(/^\w/, (letter) => letter.toUpperCase());
}

function serverExportFileStamp(date) {
  return date.toISOString().slice(0, 16).replace(/[-:T]/g, '');
}

function buildServerXlsxWorkbook({ title, subtitle, summaryRows, columns, rows, summarySheetName, dataSheetName, rtl }) {
  const sheets = [
    {
      name: safeSheetName(summarySheetName || 'Summary'),
      rows: [
        [title],
        [subtitle],
        [],
        ['Field', 'Value'],
        ...summaryRows,
      ],
      rtl,
    },
    {
      name: safeSheetName(dataSheetName || 'Data'),
      rows: [
        [title + ' - ' + subtitle],
        [],
        [...columns],
        ...rows,
      ],
      rtl,
    },
  ];
  return buildMinimalXlsx(sheets);
}

function buildPlatformXlsxPayload({ companyId, company, collections, data, exportedAt }) {
  const sheets = [
    {
      name: 'Summary',
      rows: [
        ['Masar CRM'],
        ['Company export'],
        [],
        ['Company ID', companyId],
        ['Company', cleanCell(company.displayName || company.name || companyId)],
        ['Exported at', exportedAt.toISOString()],
        ['Sections', collections.join(', ')],
      ],
      rtl: false,
    },
  ];
  for (const collectionName of collections) {
    const items = Array.isArray(data[collectionName]) ? data[collectionName] : [];
    const keys = platformExportKeys(items);
    sheets.push({
      name: safeSheetName(collectionName),
      rows: [
        [collectionName],
        [],
        keys,
        ...items.map((item) => keys.map((key) => cleanCell(item[key]))),
      ],
      rtl: false,
    });
  }
  return buildMinimalXlsx(sheets);
}

function platformExportKeys(items) {
  const blocked = new Set(['imageUrls', 'imageStoragePaths', 'photoUrl', 'downloadUrl', 'storagePath', 'token', 'password', 'resetLink']);
  const keys = [];
  for (const item of items.slice(0, 100)) {
    if (!item || typeof item !== 'object') continue;
    for (const key of Object.keys(item)) {
      const lower = key.toLowerCase();
      if (blocked.has(key) || lower.includes('token') || lower.includes('secret') || lower.includes('password')) continue;
      if (!keys.includes(key) && keys.length < 40) keys.push(key);
    }
  }
  return keys.length > 0 ? keys : ['id'];
}

function safeSheetName(name) {
  const clean = String(name || 'Sheet').replace(/[\\/?*\[\]:]/g, ' ').trim().slice(0, 31);
  return clean || 'Sheet';
}

function buildMinimalXlsx(sheets) {
  const files = [];
  files.push({ name: '[Content_Types].xml', content: Buffer.from(xlsxContentTypes(sheets.length), 'utf8') });
  files.push({ name: '_rels/.rels', content: Buffer.from(xlsxRootRels(), 'utf8') });
  files.push({ name: 'xl/workbook.xml', content: Buffer.from(xlsxWorkbook(sheets), 'utf8') });
  files.push({ name: 'xl/_rels/workbook.xml.rels', content: Buffer.from(xlsxWorkbookRels(sheets.length), 'utf8') });
  files.push({ name: 'xl/styles.xml', content: Buffer.from(xlsxStyles(), 'utf8') });
  sheets.forEach((sheet, index) => {
    files.push({ name: `xl/worksheets/sheet${index + 1}.xml`, content: Buffer.from(xlsxWorksheet(sheet), 'utf8') });
  });
  return zipStore(files);
}

function xlsxContentTypes(sheetCount) {
  let overrides = '';
  for (let i = 1; i <= sheetCount; i++) {
    overrides += `<Override PartName="/xl/worksheets/sheet${i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`;
  }
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>${overrides}</Types>`;
}

function xlsxRootRels() {
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>`;
}

function xlsxWorkbook(sheets) {
  const sheetXml = sheets.map((sheet, index) => `<sheet name="${xmlEscape(safeSheetName(sheet.name))}" sheetId="${index + 1}" r:id="rId${index + 1}"/>`).join('');
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>${sheetXml}</sheets></workbook>`;
}

function xlsxWorkbookRels(sheetCount) {
  let rels = '';
  for (let i = 1; i <= sheetCount; i++) {
    rels += `<Relationship Id="rId${i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i}.xml"/>`;
  }
  rels += `<Relationship Id="rId${sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>`;
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${rels}</Relationships>`;
}

function xlsxStyles() {
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>`;
}

function xlsxWorksheet(sheet) {
  const rows = sheet.rows || [];
  const rowXml = rows.map((row, rowIndex) => {
    const cells = (row || []).map((value, colIndex) => {
      const ref = xlsxColumnName(colIndex + 1) + (rowIndex + 1);
      const style = rowIndex === 0 || rowIndex === 2 ? ' s="1"' : '';
      return `<c r="${ref}" t="inlineStr"${style}><is><t>${xmlEscape(cleanCell(value))}</t></is></c>`;
    }).join('');
    return `<row r="${rowIndex + 1}">${cells}</row>`;
  }).join('');
  const rtl = sheet.rtl ? '<sheetViews><sheetView rightToLeft="1" workbookViewId="0"/></sheetViews>' : '<sheetViews><sheetView workbookViewId="0"/></sheetViews>';
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">${rtl}<sheetData>${rowXml}</sheetData></worksheet>`;
}

function xlsxColumnName(index) {
  let name = '';
  let value = index;
  while (value > 0) {
    const rem = (value - 1) % 26;
    name = String.fromCharCode(65 + rem) + name;
    value = Math.floor((value - 1) / 26);
  }
  return name;
}

function xmlEscape(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

const CRC_TABLE = (() => {
  const table = new Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(buffer) {
  let crc = 0 ^ (-1);
  for (let i = 0; i < buffer.length; i++) {
    crc = (crc >>> 8) ^ CRC_TABLE[(crc ^ buffer[i]) & 0xFF];
  }
  return (crc ^ (-1)) >>> 0;
}

function zipStore(files) {
  const localParts = [];
  const centralParts = [];
  let offset = 0;
  for (const file of files) {
    const nameBuffer = Buffer.from(file.name, 'utf8');
    const content = Buffer.isBuffer(file.content) ? file.content : Buffer.from(file.content || '');
    const crc = crc32(content);
    const local = Buffer.alloc(30 + nameBuffer.length);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0x0800, 6);
    local.writeUInt16LE(0, 8);
    local.writeUInt16LE(0, 10);
    local.writeUInt16LE(0, 12);
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(content.length, 18);
    local.writeUInt32LE(content.length, 22);
    local.writeUInt16LE(nameBuffer.length, 26);
    local.writeUInt16LE(0, 28);
    nameBuffer.copy(local, 30);
    localParts.push(local, content);

    const central = Buffer.alloc(46 + nameBuffer.length);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(20, 4);
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0x0800, 8);
    central.writeUInt16LE(0, 10);
    central.writeUInt16LE(0, 12);
    central.writeUInt16LE(0, 14);
    central.writeUInt32LE(crc, 16);
    central.writeUInt32LE(content.length, 20);
    central.writeUInt32LE(content.length, 24);
    central.writeUInt16LE(nameBuffer.length, 28);
    central.writeUInt16LE(0, 30);
    central.writeUInt16LE(0, 32);
    central.writeUInt16LE(0, 34);
    central.writeUInt16LE(0, 36);
    central.writeUInt32LE(0, 38);
    central.writeUInt32LE(offset, 42);
    nameBuffer.copy(central, 46);
    centralParts.push(central);
    offset += local.length + content.length;
  }
  const centralSize = centralParts.reduce((sum, part) => sum + part.length, 0);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(0, 4);
  end.writeUInt16LE(0, 6);
  end.writeUInt16LE(files.length, 8);
  end.writeUInt16LE(files.length, 10);
  end.writeUInt32LE(centralSize, 12);
  end.writeUInt32LE(offset, 16);
  end.writeUInt16LE(0, 20);
  return Buffer.concat([...localParts, ...centralParts, end]);
}



exports.listPlatformErrorLogs = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const requestedLimit = optionalPositiveInteger(data.limit, 'limit') || 160;
  const limit = Math.min(requestedLimit, 500);

  const snapshot = await db
    .collection('platform_error_logs')
    .orderBy('lastSeenAt', 'desc')
    .limit(limit)
    .get();

  return {
    logs: snapshot.docs.map((doc) => ({
      id: doc.id,
      ...serializeExportValue(doc.data() || {}),
    })),
  };
});

exports.exportCompanyDataForPlatform = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }

  const allowedCollections = new Set([
    'users',
    'leads',
    'clients',
    'properties',
    'tasks',
    'deals',
    'appointments',
    'notifications',
    'audit_logs',
    'teams',
  ]);
  const requestedCollections = Array.isArray(data.collections)
    ? data.collections.map(optionalString).filter(Boolean)
    : [];
  const collections = requestedCollections.length > 0
    ? requestedCollections.filter((collectionName) => allowedCollections.has(collectionName))
    : [...allowedCollections];

  if (collections.length === 0) {
    throw new HttpsError('invalid-argument', 'Select at least one export section.');
  }

  const result = {
    companyId,
    exportedAt: new Date().toISOString(),
    company: serializeExportValue(companySnapshot.data() || {}),
    data: {},
  };

  for (const collectionName of collections) {
    const snapshot = await db
      .collection(`companies/${companyId}/${collectionName}`)
      .limit(5000)
      .get();
    result.data[collectionName] = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...serializeExportValue(doc.data() || {}),
    }));
  }

  const exportedAt = new Date();
  const workbook = buildPlatformXlsxPayload({
    companyId,
    company: result.company,
    collections,
    data: result.data,
    exportedAt,
  });
  // Platform owner exports are administrative platform operations. They should
  // not create company-visible audit logs or tenant admin notifications, because
  // the company export feature toggle only controls tenant/company users.


  return {
    ...result,
    fileName: `masar_${companyId}_platform_export_${serverExportFileStamp(exportedAt)}.xlsx`,
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    base64Data: workbook.toString('base64'),
    generatedAt: exportedAt.toISOString(),
    recordCount: Object.values(result.data).reduce((sum, items) => sum + (Array.isArray(items) ? items.length : 0), 0),
  };
});

exports.expireTrialCompanies = onSchedule('every 1 minutes', async () => {
  const now = new Date();
  const snapshot = await db
    .collection('companies')
    .where('status', '==', 'trial')
    .limit(500)
    .get();

  for (const doc of snapshot.docs) {
    const company = doc.data() || {};
    const companyId = doc.id;
    const trialEndsAt = dateFromCallableValue(company.trialEndsAt);
    const trialStartedAt = dateFromCallableValue(company.trialStartedAt);
    if (!trialEndsAt) {
      continue;
    }

    if (trialEndsAt.getTime() > now.getTime()) {
      const milestone = trialNotificationMilestone({
        start: trialStartedAt,
        end: trialEndsAt,
        now,
      });
      if (milestone > 0) {
        await notifyTrialMilestone({ companyId, company, milestone, trialEndsAt, now });
      }
      continue;
    }

    const affectedUserIds = await listCompanyUserIds(companyId);
    await revokeRefreshTokensForUids(affectedUserIds);
    await doc.ref.update({
      status: 'trialExpired',
      isActive: false,
      trialExpiredAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: 'system:trial-expiry',
    });
    await syncGlobalUserActiveStatuses(affectedUserIds);
    const platformExpiredLocale = await platformNotificationLocale();
    const platformExpiredText = trialNotificationText({
      locale: platformExpiredLocale,
      milestone: 3,
      companyName: companyNotificationName(companyId, company),
      expired: true,
    });
    await createPlatformNotificationSafely('trial_expired', {
      id: `trial_expired_${companyId}`,
      type: 'trialExpired',
      title: platformExpiredText.title,
      message: platformExpiredText.platformBody,
      severity: 'warning',
      source: 'company',
      route: '/platform',
      companyId,
      companyName: companyNotificationName(companyId, company),
      metadata: trialLocalizedNotificationMetadata({
        milestone: 3,
        trialEndsAt: trialEndsAt.toISOString(),
        companyName: companyNotificationName(companyId, company),
        expired: true,
        extra: { status: 'trialExpired' },
      }),
    });

    const admins = await listCompanyAdminUsers(companyId);
    for (const admin of admins) {
      const locale = notificationLocaleForCompanyUser(company, admin);
      const text = trialNotificationText({
        locale,
        milestone: 3,
        expired: true,
      });
      await createCompanyNotification({
        companyId,
        recipientUid: admin.uid,
        recipientRole: 'admin',
        type: 'systemInfo',
        module: 'company',
        recordId: companyId,
        recordTitle: text.title,
        recordSubtitle: text.body,
        route: '/dashboard',
        actorUid: 'system:trial',
        actorName: 'Masar CRM',
        priority: 'urgent',
        metadata: trialLocalizedNotificationMetadata({
          milestone: 3,
          trialEndsAt: trialEndsAt.toISOString(),
          companyName: companyNotificationName(companyId, company),
          expired: true,
          extra: { status: 'trialExpired' },
        }),
        fallbackTitle: text.title,
        fallbackBody: text.body,
        dedupeKey: `trial_expired_${companyId}_admin_${admin.uid}`,
      });
    }
  }

  return null;
});

exports.runPaymentReminderSweep = onSchedule('every 6 hours', async () => {
  const now = new Date();
  const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
  const tomorrowMs = 24 * 60 * 60 * 1000;
  const snapshot = await db
    .collection('companies')
    .where('isActive', '==', true)
    .limit(500)
    .get();

  for (const doc of snapshot.docs) {
    const company = doc.data() || {};
    const companyId = doc.id;
    const status = paymentStatusForCompany(company);
    if (['trial', 'trialExpired', 'inactive', 'suspended'].includes(status)) {
      continue;
    }
    const nextDue = dateFromCallableValue(company.nextPaymentDueAt);
    const graceEnds = dateFromCallableValue(company.gracePeriodEndsAt);
    const reminderState = company && typeof company.paymentReminderState === 'object'
      ? company.paymentReminderState
      : {};
    const updates = {};

    if (status === 'gracePeriod' && graceEnds) {
      const remaining = graceEnds.getTime() - now.getTime();
      if (remaining <= tomorrowMs && remaining > 0) {
        const key = `graceEnding_${graceEnds.getTime()}`;
        if (!reminderState[key]) {
          await createPlatformPaymentNotification({
            type: 'paymentGraceEnding',
            title: 'Grace period ending soon',
            message: `${companyNotificationName(companyId, company)} grace period is ending soon.`,
            companyId,
            companyName: companyNotificationName(companyId, company),
            metadata: { gracePeriodEndsAt: graceEnds.toISOString() },
          });
          await notifyCompanyAdminsForPaymentState({
            companyId,
            company,
            paymentStatus: 'gracePeriod',
            dedupeSuffix: key,
          });
          updates[`paymentReminderState.${key}`] = true;
        }
      }
      if (remaining <= 0) {
        updates.paymentStatus = 'suspended';
        updates.status = 'inactive';
        updates.isActive = false;
        updates.suspendedAt = FieldValue.serverTimestamp();
        updates.suspendedReason = 'Grace period ended.';
        const key = `graceExpired_${graceEnds.getTime()}`;
        if (!reminderState[key]) {
          await createPlatformPaymentNotification({
            type: 'paymentSuspended',
            title: 'Company suspended',
            message: `${companyNotificationName(companyId, company)} was suspended after the payment grace period ended.`,
            companyId,
            companyName: companyNotificationName(companyId, company),
            metadata: { gracePeriodEndsAt: graceEnds.toISOString() },
          });
          await notifyCompanyAdminsForPaymentState({
            companyId,
            company,
            paymentStatus: 'suspended',
            dedupeSuffix: key,
          });
          updates[`paymentReminderState.${key}`] = true;
        }
      }
    }

    if (nextDue) {
      const remaining = nextDue.getTime() - now.getTime();
      if (remaining <= 0) {
        const key = `overdue_${nextDue.getTime()}`;
        updates.paymentStatus = status === 'gracePeriod' ? 'gracePeriod' : 'overdue';
        if (!reminderState[key]) {
          await createPlatformPaymentNotification({
            type: 'paymentOverdue',
            title: 'Payment overdue',
            message: `${companyNotificationName(companyId, company)} payment is overdue.`,
            companyId,
            companyName: companyNotificationName(companyId, company),
            metadata: { nextPaymentDueAt: nextDue.toISOString() },
          });
          await notifyCompanyAdminsForPaymentState({
            companyId,
            company,
            paymentStatus: status === 'gracePeriod' ? 'gracePeriod' : 'overdue',
            dedupeSuffix: key,
          });
          updates[`paymentReminderState.${key}`] = true;
        }
      } else if (remaining <= tomorrowMs) {
        const key = `dueTomorrow_${nextDue.getTime()}`;
        updates.paymentStatus = 'dueSoon';
        if (!reminderState[key]) {
          await createPlatformPaymentNotification({
            type: 'paymentDueSoon',
            title: 'Payment due tomorrow',
            message: `${companyNotificationName(companyId, company)} payment is due tomorrow.`,
            companyId,
            companyName: companyNotificationName(companyId, company),
            metadata: { nextPaymentDueAt: nextDue.toISOString() },
          });
          updates[`paymentReminderState.${key}`] = true;
        }
      } else if (remaining <= sevenDaysMs) {
        const key = `due7_${nextDue.getTime()}`;
        updates.paymentStatus = 'dueSoon';
        if (!reminderState[key]) {
          await createPlatformPaymentNotification({
            type: 'paymentDueSoon',
            title: 'Payment due soon',
            message: `${companyNotificationName(companyId, company)} payment is due within 7 days.`,
            companyId,
            companyName: companyNotificationName(companyId, company),
            metadata: { nextPaymentDueAt: nextDue.toISOString() },
          });
          updates[`paymentReminderState.${key}`] = true;
        }
      }
    }

    if (Object.keys(updates).length > 0) {
      updates.paymentUpdatedAt = FieldValue.serverTimestamp();
      updates.paymentUpdatedBy = 'system:payment-reminder';
      await doc.ref.set(updates, { merge: true });
      if (updates.isActive === false) {
        const affectedUserIds = await listCompanyUserIds(companyId);
        await revokeRefreshTokensForUids(affectedUserIds);
        await syncGlobalUserActiveStatuses(affectedUserIds);
      }
    }
  }

  return null;
});



exports.validateUploadedImageMagicBytes = onObjectFinalized(
  {
    region: 'us-east1',
  },
  async (event) => {
  const object = event.data || {};
  const bucketName = object.bucket;
  const filePath = object.name;
  const declaredContentType = object.contentType || '';

  if (!bucketName || !filePath) {
    return;
  }

  if (!isPropertyImagePath(filePath)) {
    return;
  }

  const file = admin.storage().bucket(bucketName).file(filePath);

  try {
    if (!declaredContentType.startsWith('image/')) {
      await deleteSpoofedImageAndLog({
        bucketName,
        filePath,
        declaredContentType,
        detectedContentType: '',
        reason: 'Uploaded property image is missing an image/* content type.',
      });
      return;
    }

    const [headerBuffer] = await file.download({ start: 0, end: 15 });
    const detectedContentType = detectImageContentType(headerBuffer);

    if (!detectedContentType || detectedContentType !== declaredContentType) {
      await deleteSpoofedImageAndLog({
        bucketName,
        filePath,
        declaredContentType,
        detectedContentType: detectedContentType || '',
        reason: 'Uploaded property image content does not match its declared MIME type.',
      });
    }
  } catch (error) {
    console.error('Image magic-byte validation failed.', {
      bucketName,
      filePath,
      declaredContentType,
      error: error && error.message ? error.message : String(error),
    });
    throw error;
  }
  },
);

exports.setCompanyUserActiveStatus = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  const isActive = requiredBoolean(data.isActive, 'isActive');
  validateCompanyId(companyId);
  const actorUid = await requirePlatformOrCompanyAdmin(request, companyId);
  const isPlatformActor = await isActivePlatformAdminUid(actorUid);
  const [companySnapshot, targetUserSnapshot] = await Promise.all([
    db.doc(`companies/${companyId}`).get(),
    db.doc(`companies/${companyId}/users/${uid}`).get(),
  ]);
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  if (!targetUserSnapshot.exists) {
    throw new HttpsError('not-found', 'Company user was not found.');
  }
  const company = companySnapshot.data() || {};
  const targetUser = targetUserSnapshot.data() || {};
  if (targetUser.companyId && targetUser.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'Company user does not belong to this company.');
  }
  const wasPlatformLocked = targetUser.platformDisabled === true ||
    targetUser.platformDisabledAt ||
    (targetUser.isActive === false && await isActivePlatformAdminUid(optionalString(targetUser.updatedBy)));

  if (!isPlatformActor) {
    enforceUserManagementFeature(company, false);
    if (isActive && wasPlatformLocked) {
      throw new HttpsError(
        'permission-denied',
        'This user was disabled by the platform owner. Contact platform owner support to reactivate it.',
      );
    }
    assertCompanyAdminCanManageTarget({
      actorUid,
      targetUid: uid,
      targetUser,
      nextActive: isActive,
    });
  }
  if (!isActive) {
    await revokeRefreshTokensForUid(uid);
    if (isPlatformActor) {
      try {
        await auth.updateUser(uid, { disabled: true });
      } catch (error) {
        if (!error || error.code !== 'auth/user-not-found') {
          throw error;
        }
      }
    }
  } else {
    // Older platform/user-management flows could leave Firebase Auth disabled
    // while the company profile is reactivated. Re-enable Auth for allowed
    // reactivation so the company Admin action actually restores login access.
    try {
      await auth.updateUser(uid, { disabled: false });
    } catch (error) {
      if (error && error.code === 'auth/user-not-found') {
        const now = FieldValue.serverTimestamp();
        await db.doc(`companies/${companyId}/users/${uid}`).set({
          isActive: false,
          authMissing: true,
          authMissingAt: now,
          updatedAt: now,
          updatedBy: actorUid,
        }, { merge: true });
        throw new HttpsError(
          'not-found',
          'This company user has no Firebase Auth account. Recreate the user or repair it from platform data health.',
        );
      }
      throw error;
    }
  }

  const now = FieldValue.serverTimestamp();
  const status = isActive ? 'active' : 'inactive';
  const batch = db.batch();
  const companyUserUpdate = {
    isActive,
    authMissing: false,
    updatedAt: now,
    updatedBy: actorUid,
  };
  if (isPlatformActor && !isActive) {
    companyUserUpdate.platformDisabled = true;
    companyUserUpdate.platformDisabledAt = now;
    companyUserUpdate.platformDisabledBy = actorUid;
  }
  if (isPlatformActor && isActive) {
    companyUserUpdate.platformDisabled = false;
    companyUserUpdate.platformDisabledBy = '';
    companyUserUpdate.platformReactivatedAt = now;
    companyUserUpdate.platformReactivatedBy = actorUid;
  }
  batch.update(db.doc(`companies/${companyId}/users/${uid}`), companyUserUpdate);
  batch.set(db.doc(`users/${uid}/memberships/${companyId}`), {
    companyId,
    isActive,
    status,
    updatedAt: now,
  }, { merge: true });
  await batch.commit();
  await syncGlobalUserActiveStatus(uid);
  {
    const actor = await notificationActorSummary(companyId, actorUid);
    const actorRole = isPlatformActor ? 'platformAdmin' : 'companyAdmin';
    await createPlatformNotificationSafely('set_company_user_active_status', {
      type: 'companyUserStatusChanged',
      title: 'Company user status changed',
      message: `${optionalString(targetUser.fullName) || optionalString(targetUser.email) || uid} is now ${isActive ? 'active' : 'inactive'} by ${actor.actorName || actor.actorEmail || actorRole}.`,
      severity: isActive ? 'success' : 'warning',
      source: 'user',
      route: '/platform',
      actorId: actor.actorId,
      actorName: actor.actorName,
      actorEmail: actor.actorEmail,
      companyId,
      companyName: companyNotificationName(companyId, company),
      metadata: {
        targetUid: uid,
        targetEmail: targetUser.email || '',
        role: targetUser.role || '',
        actorRole,
        isActive,
        status,
      },
    });
  }

  return { uid, companyId, isActive };
});

exports.setCompanyUserPassword = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  const newPassword = requiredPassword(data.newPassword, 'newPassword');
  validateCompanyId(companyId);
  validatePassword(newPassword);

  const { companyUserSnapshot, userRecord } = await loadCompanyUserAndAuthUser({
    companyId,
    uid,
  });
  const companyUser = companyUserSnapshot.data() || {};
  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  const company = companySnapshot.exists ? companySnapshot.data() || {} : {};

  await auth.updateUser(uid, { password: newPassword });
  await db.collection('platform_security_alerts').add({
    type: 'platformPasswordChanged',
    companyId,
    targetUid: uid,
    targetEmail: userRecord.email || companyUser.email || '',
    actorUid: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  const actor = await platformActorSummary(actorUid);
  await createPlatformNotificationSafely('set_company_user_password', {
    type: 'companyUserPasswordReset',
    title: 'Company user password action',
    message: `A password action was completed for ${companyUser.fullName || userRecord.email || uid}.`,
    severity: 'warning',
    source: 'user',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    companyId,
    companyName: companyNotificationName(companyId, company),
    metadata: {
      targetUid: uid,
      targetEmail: userRecord.email || companyUser.email || '',
      action: 'passwordChanged',
    },
  });

  return { uid, companyId };
});

exports.setCompanyUserEmail = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  const newEmail = normalizeEmail(requiredString(data.newEmail, 'newEmail'));
  validateCompanyId(companyId);
  validateEmail(newEmail);

  const { companyUserSnapshot, userRecord } = await loadCompanyUserAndAuthUser({
    companyId,
    uid,
  });
  const companyUser = companyUserSnapshot.data() || {};
  const oldEmail = normalizeEmail(userRecord.email || companyUser.email || '');

  if (oldEmail === newEmail) {
    return { uid, companyId, email: newEmail };
  }

  try {
    const existing = await auth.getUserByEmail(newEmail);
    if (existing.uid !== uid) {
      throw new HttpsError('already-exists', 'Email is already used by another user.');
    }
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  await auth.updateUser(uid, {
    email: newEmail,
    emailVerified: false,
  });

  const now = FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(db.doc(`users/${uid}`), {
    email: newEmail,
    updatedAt: now,
  }, { merge: true });
  batch.set(db.doc(`companies/${companyId}/users/${uid}`), {
    email: newEmail,
    updatedAt: now,
    updatedBy: request.auth.uid,
  }, { merge: true });
  batch.set(db.collection('platform_security_alerts').doc(), {
    type: 'platformEmailChanged',
    companyId,
    targetUid: uid,
    oldEmail,
    newEmail,
    actorUid: request.auth.uid,
    createdAt: now,
  });

  const platformAdminRef = db.doc(`platform_admins/${uid}`);
  const platformAdminSnapshot = await platformAdminRef.get();
  if (platformAdminSnapshot.exists) {
    batch.set(platformAdminRef, {
      email: newEmail,
      updatedAt: now,
      updatedBy: request.auth.uid,
    }, { merge: true });
  }

  await batch.commit();

  return { uid, companyId, email: newEmail };
});


exports.setPlatformOwnerEmail = onCall(async (request) => {
  const actorUid = await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const uid = optionalString(data.uid) || actorUid;
  const newEmail = normalizeEmail(requiredString(data.newEmail || data.email, 'email'));
  validateEmail(newEmail);

  if (uid !== actorUid) {
    throw new HttpsError('permission-denied', 'You can only update your own platform owner email.');
  }

  const [platformAdminSnapshot, userRecord] = await Promise.all([
    db.doc(`platform_admins/${uid}`).get(),
    auth.getUser(uid),
  ]);
  if (!platformAdminSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Platform owner profile was not found.');
  }
  const platformAdmin = platformAdminSnapshot.data() || {};
  if (platformAdmin.isActive === false) {
    throw new HttpsError('permission-denied', 'Platform owner profile is inactive.');
  }

  const oldEmail = normalizeEmail(userRecord.email || platformAdmin.email || '');
  if (oldEmail === newEmail) {
    return { uid, email: newEmail };
  }

  try {
    const existing = await auth.getUserByEmail(newEmail);
    if (existing.uid !== uid) {
      throw new HttpsError('already-exists', 'Email is already used by another user.');
    }
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  await auth.updateUser(uid, {
    email: newEmail,
    emailVerified: false,
  });

  const now = FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(db.doc(`platform_admins/${uid}`), {
    email: newEmail,
    updatedAt: now,
    updatedBy: actorUid,
  }, { merge: true });
  batch.set(db.doc(`users/${uid}`), {
    email: newEmail,
    updatedAt: now,
  }, { merge: true });
  batch.set(db.collection('platform_security_alerts').doc(), {
    type: 'platformOwnerEmailChanged',
    targetUid: uid,
    oldEmail,
    newEmail,
    actorUid,
    createdAt: now,
  });
  await batch.commit();

  await createPlatformNotificationSafely('set_platform_owner_email', {
    type: 'platformOwnerEmailChanged',
    title: 'Platform owner email changed',
    message: `Platform owner email changed from ${oldEmail} to ${newEmail}.`,
    severity: 'warning',
    source: 'security',
    route: '/platform/settings',
    actorId: actorUid,
    actorName: optionalString(platformAdmin.fullName),
    actorEmail: newEmail,
    metadata: { targetUid: uid, oldEmail, newEmail },
  });

  return { uid, email: newEmail };
});


exports.updateOwnProfileSettings = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const uid = request.auth.uid;
  const data = request.data || {};
  const companyId = optionalString(data.companyId);
  const update = requiredObject(data.update || {}, 'update');
  const previousPhotoStoragePath = optionalString(data.previousPhotoStoragePath);

  const hasFullName = Object.prototype.hasOwnProperty.call(update, 'fullName');
  const hasPhotoUrl = Object.prototype.hasOwnProperty.call(update, 'photoUrl');
  const hasPhotoStoragePath = Object.prototype.hasOwnProperty.call(update, 'photoStoragePath');

  if (!hasFullName && !hasPhotoUrl && !hasPhotoStoragePath) {
    throw new HttpsError('invalid-argument', 'No profile fields were provided.');
  }

  let companyUser = null;
  if (companyId) {
    validateCompanyId(companyId);
    companyUser = await requireActiveCompanyUser(request, companyId);
    if (hasFullName && optionalString(companyUser.role) !== 'admin') {
      throw new HttpsError('permission-denied', 'Only company admins can update their profile name.');
    }
  } else {
    await requireActivePlatformAdmin(request);
  }

  const profileUpdate = {
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: uid,
  };
  const authUpdate = {};

  if (hasFullName) {
    const fullName = sanitizeProfileName(update.fullName);
    profileUpdate.fullName = fullName;
    authUpdate.displayName = fullName;
  }

  if (hasPhotoUrl || hasPhotoStoragePath) {
    const photoUrl = sanitizeProfileUrl(update.photoUrl || '');
    const photoStoragePath = optionalString(update.photoStoragePath || '');
    validateOwnedProfileStoragePath({ companyId, uid, path: photoStoragePath });
    profileUpdate.photoUrl = photoUrl;
    profileUpdate.photoStoragePath = photoStoragePath;
    authUpdate.photoURL = photoUrl || null;
  }

  if (Object.keys(authUpdate).length > 0) {
    await auth.updateUser(uid, authUpdate);
  }

  const batch = db.batch();
  batch.set(db.doc(`users/${uid}`), profileUpdate, { merge: true });

  if (companyId) {
    batch.set(db.doc(`companies/${companyId}/users/${uid}`), profileUpdate, { merge: true });
  } else {
    batch.set(db.doc(`platform_admins/${uid}`), profileUpdate, { merge: true });
  }

  await batch.commit();

  if (previousPhotoStoragePath) {
    await deleteOwnedProfileStoragePath({ companyId, uid, path: previousPhotoStoragePath });
  }

  return {
    uid,
    companyId,
    fullName: hasFullName ? profileUpdate.fullName : null,
    photoUrl: hasPhotoUrl || hasPhotoStoragePath ? profileUpdate.photoUrl : null,
    photoStoragePath: hasPhotoUrl || hasPhotoStoragePath
      ? profileUpdate.photoStoragePath
      : null,
  };
});

exports.archiveCrmRecord = onCall(async (request) => {
  return updateCrmArchiveState(request, true);
});

exports.restoreCrmRecord = onCall(async (request) => {
  return updateCrmArchiveState(request, false);
});


exports.saveLeadRecord = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const actorUid = request.auth.uid;
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const operation = requiredString(data.operation, 'operation');
  const leadInput = requiredObject(data.lead || {}, 'lead');
  validateCompanyId(companyId);

  if (!['create', 'update'].includes(operation)) {
    throw new HttpsError('invalid-argument', 'Lead operation is invalid.');
  }

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'You do not have permission to save leads.');
  }

  let leadId = optionalString(leadInput.id);
  const leadsCollection = db.collection(`companies/${companyId}/leads`);
  if (operation === 'create' && !leadId) {
    leadId = leadsCollection.doc().id;
  }
  if (!leadId) {
    throw new HttpsError('invalid-argument', 'Lead ID is required.');
  }

  const leadRef = leadsCollection.doc(leadId);
  const leadSnapshot = await leadRef.get();
  const existingLead = leadSnapshot.exists ? (leadSnapshot.data() || {}) : null;

  if (operation === 'create' && leadSnapshot.exists) {
    throw new HttpsError('already-exists', 'Lead already exists.');
  }
  if (operation === 'update' && !leadSnapshot.exists) {
    throw new HttpsError('not-found', 'Lead was not found.');
  }

  let assignedTo = optionalString(leadInput.assignedTo);
  if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    assignedTo = actorUid;
  }

  if (actorRole === 'manager' && !assignedTo) {
    throw new HttpsError('permission-denied', 'Managers must assign leads to their team.');
  }

  let assignee = null;
  if (assignedTo) {
    const assigneeSnapshot = await db
      .doc(`companies/${companyId}/users/${assignedTo}`)
      .get();
    if (!assigneeSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Selected assignee was not found.');
    }
    assignee = assigneeSnapshot.data() || {};
    if (assignee.companyId && assignee.companyId !== companyId) {
      throw new HttpsError('permission-denied', 'Selected assignee does not belong to this company.');
    }
    if (assignee.isActive !== true) {
      throw new HttpsError('failed-precondition', 'Selected assignee is inactive.');
    }
    if (!LEAD_ASSIGNABLE_ROLES.has(assignee.role)) {
      throw new HttpsError('failed-precondition', 'Selected assignee is not eligible for leads.');
    }
  }

  if (actorRole === 'manager') {
    const managerTeamId = optionalString(actor.teamId);
    const assigneeManagerId = assignee ? optionalString(assignee.managerId) : '';
    const assigneeTeamId = assignee ? optionalString(assignee.teamId) : '';
    const canAssignToUser = assigneeManagerId === actorUid ||
      (managerTeamId && assigneeTeamId === managerTeamId);
    if (!canAssignToUser) {
      throw new HttpsError('permission-denied', 'You can only assign leads to your team.');
    }

    if (existingLead) {
      const existingTeamId = optionalString(existingLead.teamId);
      const existingManagerId = optionalString(existingLead.managerId);
      const existingAssignedTo = optionalString(existingLead.assignedTo);
      const canManageExisting = existingAssignedTo === actorUid ||
        existingManagerId === actorUid ||
        (managerTeamId && existingTeamId === managerTeamId);
      if (!canManageExisting) {
        throw new HttpsError('permission-denied', 'You cannot update another team lead.');
      }
    }
  }

  if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    if (operation === 'update') {
      if (!existingLead || optionalString(existingLead.assignedTo) !== actorUid) {
        throw new HttpsError('permission-denied', 'You can update only your assigned leads.');
      }
    }
    if (operation === 'create' && assignedTo !== actorUid) {
      throw new HttpsError('permission-denied', 'You can create only your assigned leads.');
    }
  }

  const now = FieldValue.serverTimestamp();
  const payload = buildLeadPayload({
    companyId,
    leadId,
    leadInput,
    assignedTo,
    assignee,
    actorUid,
    now,
    existingLead,
    isCreate: operation === 'create',
  });

  const hasDuplicateLead = await hasDuplicateLeadRecord({
    companyId,
    phone: payload.phone,
    email: payload.email,
    excludeLeadId: operation === 'update' ? leadId : '',
  });
  if (hasDuplicateLead) {
    throw new HttpsError('already-exists', 'Lead already exists.');
  }

  if (operation === 'create') {
    await leadRef.set(payload);
  } else {
    await leadRef.set(payload, { merge: true });
  }

  // Lead assignment notifications are emitted by the Firestore write trigger below.
  // Keeping assignment notifications in one trigger covers both callable saves and
  // any safe server-side assignment updates without double-sending.

  await createLeadImportantStatusNotifications({
    companyId,
    leadId,
    actorUid,
    actor,
    existingLead,
    payload,
  }).catch(() => undefined);

  return { companyId, leadId };
});

exports.checkDuplicateLead = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  validateCompanyId(companyId);

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'You do not have permission to check lead duplicates.');
  }

  const duplicate = await hasDuplicateLeadRecord({
    companyId,
    phone: optionalString(data.phone),
    email: optionalString(data.email),
    excludeLeadId: optionalString(data.excludeLeadId),
  });

  return { duplicate };
});


exports.saveDealRecord = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const actorUid = request.auth.uid;
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const operation = requiredString(data.operation, 'operation');
  const dealInput = requiredObject(data.deal || {}, 'deal');
  validateCompanyId(companyId);

  if (!['create', 'update', 'stage'].includes(operation)) {
    throw new HttpsError('invalid-argument', 'Deal operation is invalid.');
  }

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (operation !== 'stage' && !['admin', 'manager'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'You do not have permission to save deals.');
  }
  if (operation === 'stage' && !['admin', 'manager', 'salesAgent'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'You do not have permission to update this deal stage.');
  }

  let dealId = optionalString(dealInput.id);
  const dealsCollection = db.collection(`companies/${companyId}/deals`);
  if (operation === 'create' && !dealId) {
    dealId = dealsCollection.doc().id;
  }
  if (!dealId) {
    throw new HttpsError('invalid-argument', 'Deal ID is required.');
  }

  const dealRef = dealsCollection.doc(dealId);
  const dealSnapshot = await dealRef.get();
  const existingDeal = dealSnapshot.exists ? (dealSnapshot.data() || {}) : null;

  if (operation === 'create' && dealSnapshot.exists) {
    throw new HttpsError('already-exists', 'Deal already exists.');
  }
  if ((operation === 'update' || operation === 'stage') && !dealSnapshot.exists) {
    throw new HttpsError('not-found', 'Deal was not found.');
  }

  if (operation === 'stage') {
    if (existingDeal.isActive === false || existingDeal.isArchived === true) {
      throw new HttpsError('failed-precondition', 'Archived or inactive deals cannot be updated.');
    }
    const managerTeamId = optionalString(actor.teamId);
    const canUpdateStage = actorRole === 'admin' ||
      (actorRole === 'manager' && (
        optionalString(existingDeal.assignedTo) === actorUid ||
        optionalString(existingDeal.managerId) === actorUid ||
        (managerTeamId && optionalString(existingDeal.teamId) === managerTeamId)
      )) ||
      (actorRole === 'salesAgent' && optionalString(existingDeal.assignedTo) === actorUid);
    if (!canUpdateStage) {
      throw new HttpsError('permission-denied', 'You can update only deals assigned to you or your team.');
    }

    const stage = enumValue(dealInput.stage || 'new', DEAL_STAGES, 'stage');
    const lostReason = stage === 'lost'
      ? sanitizePlainString(requiredString(dealInput.lostReason, 'lostReason'), 500)
      : '';
    await dealRef.set({
      stage,
      lostReason,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: actorUid,
    }, { merge: true });
    return { companyId, dealId };
  }

  if (actorRole === 'manager' && existingDeal) {
    const managerTeamId = optionalString(actor.teamId);
    const canManageExisting = optionalString(existingDeal.assignedTo) === actorUid ||
      optionalString(existingDeal.managerId) === actorUid ||
      (managerTeamId && optionalString(existingDeal.teamId) === managerTeamId);
    if (!canManageExisting) {
      throw new HttpsError('permission-denied', 'You can save only deals in your team.');
    }
  }

  const assignedTo = requiredString(dealInput.assignedTo, 'assignedTo');
  const assigneeSnapshot = await db.doc(`companies/${companyId}/users/${assignedTo}`).get();
  if (!assigneeSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Selected assignee was not found.');
  }
  const assignee = assigneeSnapshot.data() || {};
  if (optionalString(assignee.companyId) && optionalString(assignee.companyId) !== companyId) {
    throw new HttpsError('permission-denied', 'Selected assignee does not belong to this company.');
  }
  if (assignee.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Selected assignee is inactive.');
  }
  const assigneeRole = optionalString(assignee.role);
  if (!['salesAgent', 'admin', 'manager'].includes(assigneeRole)) {
    throw new HttpsError('failed-precondition', 'Deals can only be assigned to active sales, manager, or admin users.');
  }

  if (actorRole === 'manager') {
    const managerTeamId = optionalString(actor.teamId);
    const assigneeManagerId = optionalString(assignee.managerId);
    const assigneeTeamId = optionalString(assignee.teamId);
    const canAssignToUser = assignedTo === actorUid ||
      assigneeManagerId === actorUid ||
      (managerTeamId && assigneeTeamId === managerTeamId);
    if (!canAssignToUser) {
      throw new HttpsError('permission-denied', 'You can assign deals only to yourself or your team.');
    }
  }

  const clientId = requiredString(dealInput.clientId, 'clientId');
  const propertyId = requiredString(dealInput.propertyId, 'propertyId');
  const [clientSnapshot, propertySnapshot] = await Promise.all([
    db.doc(`companies/${companyId}/clients/${clientId}`).get(),
    db.doc(`companies/${companyId}/properties/${propertyId}`).get(),
  ]);
  if (!clientSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Selected client was not found.');
  }
  if (!propertySnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Selected property was not found.');
  }
  const client = clientSnapshot.data() || {};
  const property = propertySnapshot.data() || {};
  if (optionalString(client.companyId) !== companyId || optionalString(property.companyId) !== companyId) {
    throw new HttpsError('permission-denied', 'Selected records do not belong to this company.');
  }
  if (client.isActive === false || client.isArchived === true) {
    throw new HttpsError('failed-precondition', 'Selected client is inactive or archived.');
  }

  const stage = enumValue(dealInput.stage || 'new', DEAL_STAGES, 'stage');
  const lostReason = stage === 'lost'
    ? sanitizePlainString(requiredString(dealInput.lostReason, 'lostReason'), 500)
    : '';
  const now = FieldValue.serverTimestamp();
  const assignment = assignmentSnapshotFromAssignee(assignedTo, assignee);

  const payload = {
    id: dealId,
    companyId,
    clientId,
    clientName: sanitizePlainString(optionalString(client.fullName) || optionalString(dealInput.clientName), 180),
    clientEmail: sanitizePlainString(optionalString(client.email) || optionalString(dealInput.clientEmail), 180),
    clientPhone: sanitizePlainString(optionalString(client.phone) || optionalString(dealInput.clientPhone), 80),
    leadId: sanitizePlainString(optionalString(dealInput.leadId), 160),
    leadName: sanitizePlainString(optionalString(dealInput.leadName), 180),
    leadPhone: sanitizePlainString(optionalString(dealInput.leadPhone), 80),
    propertyId,
    propertyTitle: sanitizePlainString(optionalString(property.title) || optionalString(dealInput.propertyTitle), 220),
    propertyLocation: sanitizePlainString(optionalString(property.location) || optionalString(dealInput.propertyLocation), 220),
    ...assignment,
    stage,
    expectedValue: numberValue(dealInput.expectedValue, 'expectedValue'),
    commission: numberValue(dealInput.commission, 'commission'),
    closingDate: optionalCallableTimestamp(dealInput.closingDate),
    lostReason,
    notes: sanitizePlainString(optionalString(dealInput.notes), 4000),
    isActive: true,
    isArchived: existingDeal && existingDeal.isArchived === true ? true : false,
    archivedAt: existingDeal && existingDeal.archivedAt ? existingDeal.archivedAt : null,
    archivedBy: existingDeal ? optionalString(existingDeal.archivedBy) : '',
    archivedByName: existingDeal ? optionalString(existingDeal.archivedByName) : '',
    archiveReason: existingDeal ? optionalString(existingDeal.archiveReason) : '',
    restoredAt: existingDeal && existingDeal.restoredAt ? existingDeal.restoredAt : null,
    restoredBy: existingDeal ? optionalString(existingDeal.restoredBy) : '',
    restoredByName: existingDeal ? optionalString(existingDeal.restoredByName) : '',
    updatedAt: now,
    updatedBy: actorUid,
  };

  if (operation === 'create') {
    payload.createdAt = now;
    payload.createdBy = actorUid;
    payload.isActive = true;
    payload.isArchived = false;
    payload.archivedAt = null;
    payload.archivedBy = '';
    payload.archivedByName = '';
    payload.archiveReason = '';
    payload.restoredAt = null;
    payload.restoredBy = '';
    payload.restoredByName = '';
  } else {
    payload.createdAt = existingDeal.createdAt || now;
    payload.createdBy = optionalString(existingDeal.createdBy) || actorUid;
  }

  if (operation === 'create') {
    await dealRef.set(payload);
  } else {
    await dealRef.set(payload, { merge: true });
  }

  return { companyId, dealId };
});

exports.assignClientRecord = onCall(async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Sign in is required.');
    }

    const actorUid = request.auth.uid;
    const data = request.data || {};
    const companyId = requiredString(data.companyId, 'companyId');
    const clientId = requiredString(data.clientId, 'clientId');
    const assignedTo = optionalString(data.assignedTo);
    validateCompanyId(companyId);

    const actor = await requireActiveCompanyUser(request, companyId);
    const actorRole = optionalString(actor.role);
    if (!['admin', 'manager'].includes(actorRole)) {
      throw new HttpsError('permission-denied', 'You do not have permission to assign clients.');
    }

    const clientRef = db.doc(`companies/${companyId}/clients/${clientId}`);
    const clientSnapshot = await clientRef.get();
    if (!clientSnapshot.exists) {
      throw new HttpsError('not-found', 'Client was not found.');
    }
    const client = clientSnapshot.data() || {};
    if (optionalString(client.companyId) && optionalString(client.companyId) !== companyId) {
      throw new HttpsError('permission-denied', 'Client does not belong to this company.');
    }
    if (client.isArchived === true || client.isActive === false) {
      throw new HttpsError('failed-precondition', 'Archived or inactive clients cannot be assigned.');
    }

    const actorTeamId = optionalString(actor.teamId);
    if (actorRole === 'manager') {
      const existingAssignedTo = optionalString(client.assignedTo);
      let existingAssignee = null;
      if (existingAssignedTo) {
        const existingAssigneeSnapshot = await db
          .doc(`companies/${companyId}/users/${existingAssignedTo}`)
          .get();
        existingAssignee = existingAssigneeSnapshot.exists
          ? (existingAssigneeSnapshot.data() || {})
          : null;
      }
      const canManageExisting =
        optionalString(client.assignedTo) === actorUid ||
        optionalString(client.managerId) === actorUid ||
        (actorTeamId && optionalString(client.teamId) === actorTeamId) ||
        (existingAssignee && optionalString(existingAssignee.managerId) === actorUid) ||
        (existingAssignee && actorTeamId && optionalString(existingAssignee.teamId) === actorTeamId);
      if (!canManageExisting) {
        throw new HttpsError('permission-denied', 'You can assign only clients in your team.');
      }
      if (!assignedTo) {
        throw new HttpsError('permission-denied', 'Managers cannot leave clients unassigned.');
      }
    }

    let assignmentUpdate = {
      assignedTo: '',
      assignedToName: '',
      assignedToEmail: '',
      teamId: '',
      teamName: '',
      managerId: '',
      managerName: '',
    };

    if (assignedTo) {
      const assigneeSnapshot = await db
        .doc(`companies/${companyId}/users/${assignedTo}`)
        .get();
      if (!assigneeSnapshot.exists) {
        throw new HttpsError('failed-precondition', 'Selected assignee was not found.');
      }
      const assignee = assigneeSnapshot.data() || {};
      if (assignee.companyId && assignee.companyId !== companyId) {
        throw new HttpsError('permission-denied', 'Selected assignee does not belong to this company.');
      }
      if (assignee.isActive !== true) {
        throw new HttpsError('failed-precondition', 'Selected assignee is inactive.');
      }
      if (optionalString(assignee.role) !== 'salesAgent') {
        throw new HttpsError('failed-precondition', 'Clients can only be assigned to sales agents.');
      }
      if (actorRole === 'manager') {
        const canAssignToUser =
          optionalString(assignee.managerId) === actorUid ||
          (actorTeamId && optionalString(assignee.teamId) === actorTeamId);
        if (!canAssignToUser) {
          throw new HttpsError('permission-denied', 'You can assign clients only to your team.');
        }
      }
      assignmentUpdate = assignmentSnapshotFromAssignee(assignedTo, assignee);
    }

    const update = {
      ...assignmentUpdate,
      id: optionalString(client.id) || clientId,
      companyId,
      isActive: typeof client.isActive === 'boolean' ? client.isActive : true,
      isArchived: typeof client.isArchived === 'boolean' ? client.isArchived : false,
      archivedAt: client.archivedAt || null,
      archivedBy: optionalString(client.archivedBy),
      archivedByName: optionalString(client.archivedByName),
      archiveReason: optionalString(client.archiveReason),
      restoredAt: client.restoredAt || null,
      restoredBy: optionalString(client.restoredBy),
      restoredByName: optionalString(client.restoredByName),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: actorUid,
    };

    if (typeof client.fullName !== 'string') {
      update.fullName = '';
    }
    if (typeof client.phone !== 'string') {
      update.phone = '';
    }
    if (typeof client.email !== 'string') {
      update.email = '';
    }
    if (typeof client.preferredLocation !== 'string') {
      update.preferredLocation = '';
    }
    if (typeof client.preferredPropertyType !== 'string') {
      update.preferredPropertyType = '';
    }
    if (typeof client.notes !== 'string') {
      update.notes = '';
    }
    if (!client.createdAt) {
      update.createdAt = FieldValue.serverTimestamp();
    }
    if (typeof client.createdBy !== 'string') {
      update.createdBy = actorUid;
    }

    await clientRef.update(update);
    return { companyId, clientId, assignedTo };
});


exports.saveAppointmentRecord = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const actorUid = request.auth.uid;
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const operation = requiredString(data.operation, 'operation');
  const appointmentInput = requiredObject(data.appointment || {}, 'appointment');
  validateCompanyId(companyId);

  if (!['create', 'update'].includes(operation)) {
    throw new HttpsError('invalid-argument', 'Appointment operation is invalid.');
  }

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'You do not have permission to save appointments.');
  }

  let appointmentId = optionalString(appointmentInput.id);
  const appointmentsCollection = db.collection(`companies/${companyId}/appointments`);
  if (operation === 'create' && !appointmentId) {
    appointmentId = appointmentsCollection.doc().id;
  }
  if (!appointmentId) {
    throw new HttpsError('invalid-argument', 'Appointment ID is required.');
  }

  const appointmentRef = appointmentsCollection.doc(appointmentId);
  const appointmentSnapshot = await appointmentRef.get();
  const existingAppointment = appointmentSnapshot.exists
    ? (appointmentSnapshot.data() || {})
    : null;

  if (operation === 'create' && appointmentSnapshot.exists) {
    throw new HttpsError('already-exists', 'Appointment already exists.');
  }
  if (operation === 'update' && !appointmentSnapshot.exists) {
    throw new HttpsError('not-found', 'Appointment was not found.');
  }

  let assignedTo = optionalString(appointmentInput.assignedTo);
  if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    assignedTo = actorUid;
  }
  if (!assignedTo) {
    throw new HttpsError('failed-precondition', 'Appointment assignee is required.');
  }

  const assigneeSnapshot = await db
    .doc(`companies/${companyId}/users/${assignedTo}`)
    .get();
  if (!assigneeSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Selected assignee was not found.');
  }
  const assignee = assigneeSnapshot.data() || {};
  if (assignee.companyId && assignee.companyId !== companyId) {
    throw new HttpsError('permission-denied', 'Selected assignee does not belong to this company.');
  }
  if (assignee.isActive !== true) {
    throw new HttpsError('failed-precondition', 'Selected assignee is inactive.');
  }
  if (!APPOINTMENT_ASSIGNABLE_ROLES.has(assignee.role)) {
    throw new HttpsError('failed-precondition', 'Selected assignee is not eligible for appointments.');
  }

  if (actorRole === 'manager') {
    const managerTeamId = optionalString(actor.teamId);
    const assigneeManagerId = optionalString(assignee.managerId);
    const assigneeTeamId = optionalString(assignee.teamId);
    const canAssignToUser = assignedTo === actorUid ||
      assigneeManagerId === actorUid ||
      (managerTeamId && assigneeTeamId === managerTeamId);
    if (!canAssignToUser) {
      throw new HttpsError('permission-denied', 'You can only assign appointments to your team.');
    }

    if (existingAppointment) {
      const existingTeamId = optionalString(existingAppointment.teamId);
      const existingManagerId = optionalString(existingAppointment.managerId);
      const existingAssignedTo = optionalString(existingAppointment.assignedTo);
      const canManageExisting = existingAssignedTo === actorUid ||
        existingManagerId === actorUid ||
        (managerTeamId && existingTeamId === managerTeamId);
      if (!canManageExisting) {
        throw new HttpsError('permission-denied', 'You cannot update another team appointment.');
      }
    }
  }

  if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    if (operation === 'update') {
      if (!existingAppointment || optionalString(existingAppointment.assignedTo) !== actorUid) {
        throw new HttpsError('permission-denied', 'You can update only your appointments.');
      }
    }
    if (assignedTo !== actorUid) {
      throw new HttpsError('permission-denied', 'You can create only your own appointments.');
    }
  }

  const relatedSnapshot = await appointmentRelatedSnapshot({
    companyId,
    actor,
    actorUid,
    actorRole,
    relatedType: optionalString(appointmentInput.relatedType) || 'general',
    relatedId: optionalString(appointmentInput.relatedId),
  });

  const now = FieldValue.serverTimestamp();
  const payload = buildAppointmentPayload({
    companyId,
    appointmentId,
    appointmentInput,
    assignedTo,
    assignee,
    relatedSnapshot,
    actorUid,
    now,
    existingAppointment,
    isCreate: operation === 'create',
  });

  if (operation === 'create') {
    await appointmentRef.set(payload);
  } else {
    await appointmentRef.set(payload, { merge: true });
  }

  const actorName = optionalString(actor.fullName) || optionalString(actor.email);
  await createAppointmentAssignmentNotifications({
    companyId,
    appointmentId,
    operation,
    actorUid,
    actorName,
    existingAppointment,
    payload,
  }).catch(() => undefined);

  await createAppointmentStatusNotifications({
    companyId,
    appointmentId,
    actorUid,
    actorName,
    before: existingAppointment,
    after: payload,
  }).catch(() => undefined);

  await resolveStaleAppointmentTimingNotifications({
    companyId,
    appointmentId,
    appointment: payload,
  }).catch(() => undefined);

  await createAppointmentTimingNotifications({
    companyId,
    appointmentId,
    appointment: payload,
    now: admin.firestore.Timestamp.now(),
  }).catch(() => undefined);

  return { companyId, appointmentId };
});






exports.registerCompanyNotificationToken = onCall(
  { region: 'us-east1' },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Sign in is required.');
    }

    const data = request.data || {};
    const companyId = requiredString(data.companyId, 'companyId');
    validateCompanyId(companyId);
    const token = sanitizeNotificationToken(data.token);
    const platform = sanitizeNotificationTokenPlatform(data.platform);
    const locale = sanitizeNotificationTokenLocale(data.locale);
    const uid = request.auth.uid;

    const [companySnapshot, companyUserSnapshot, userRecord] = await Promise.all([
      db.doc(`companies/${companyId}`).get(),
      db.doc(`companies/${companyId}/users/${uid}`).get(),
      auth.getUser(uid).catch(() => null),
    ]);

    if (!companySnapshot.exists) {
      throw new HttpsError('not-found', 'Company was not found.');
    }
    const company = companySnapshot.data() || {};
    if (company.isActive !== true || company.status === 'inactive') {
      throw new HttpsError('failed-precondition', 'Company is inactive.');
    }
    if (!companyUserSnapshot.exists) {
      throw new HttpsError('permission-denied', 'Company user was not found.');
    }
    const companyUser = companyUserSnapshot.data() || {};
    if (companyUser.companyId !== companyId || companyUser.isActive !== true) {
      throw new HttpsError('permission-denied', 'Company user is inactive.');
    }

    const tokenHash = notificationTokenHash(token);
    const tokenRef = db.collection(`companies/${companyId}/notification_tokens`).doc(tokenHash);

    if (!companyFeatureEnabled(company, 'notifications')) {
      await tokenRef.set({
        tokenHash,
        token: '',
        scope: 'company',
        companyId,
        uid,
        platform,
        isActive: false,
        deactivatedReason: 'notifications-feature-disabled',
        deactivatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return { registered: false, reason: 'notifications-feature-disabled' };
    }

    const existingTokenSnapshot = await tokenRef.get();
    const existingToken = existingTokenSnapshot.exists ? (existingTokenSnapshot.data() || {}) : {};
    if (
      platform === 'web' &&
      existingToken.isActive !== true &&
      optionalString(existingToken.deactivatedReason) === 'fcm-invalid-token' &&
      (optionalString(existingToken.tokenHash) || tokenRef.id) === tokenHash
    ) {
      return {
        registered: false,
        refreshRequired: true,
        reason: 'cached-invalid-web-token',
        scope: 'company',
        companyId,
        tokenHash,
      };
    }

    await bestEffortDeactivateNotificationTokenEverywhere({
      tokenHash,
      keepPath: tokenRef.path,
      reason: 'registered-company-token',
      scope: 'company',
      companyId,
      uid,
    });

    const now = FieldValue.serverTimestamp();
    await tokenRef.set({
      tokenHash,
      token,
      scope: 'company',
      companyId,
      uid,
      email: sanitizePlainString(optionalString(companyUser.email) || optionalString(userRecord && userRecord.email), 180),
      fullName: sanitizePlainString(optionalString(companyUser.fullName) || optionalString(userRecord && userRecord.displayName), 160),
      role: sanitizePlainString(optionalString(companyUser.role), 40),
      teamId: sanitizePlainString(optionalString(companyUser.teamId), 160),
      teamName: sanitizePlainString(optionalString(companyUser.teamName), 160),
      managerId: sanitizePlainString(optionalString(companyUser.managerId), 160),
      managerName: sanitizePlainString(optionalString(companyUser.managerName), 160),
      locale,
      platform,
      installId: sanitizeShortString(data.installId, 140),
      appVersion: sanitizeShortString(data.appVersion, 40),
      buildNumber: sanitizeShortString(data.buildNumber, 20),
      timezone: sanitizeShortString(data.timezone, 80),
      userAgent: sanitizeShortString(data.userAgent, 600),
      webOrigin: sanitizeShortString(data.webOrigin, 240),
      webHref: sanitizeShortString(data.webHref, 500),
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
      deactivatedAt: null,
      deactivatedReason: '',
    }, { merge: true });

    await bestEffortDeactivateSiblingCompanyNotificationTokens({
      companyId,
      uid,
      platform,
      currentTokenHash: tokenHash,
      webOrigin: sanitizeShortString(data.webOrigin, 240),
    });

    const installId = sanitizeShortString(data.installId, 140);
    if (installId) {
      await db.doc(`companies/${companyId}/device_installs/${installId}`).set({
        installId,
        uid,
        companyId,
        platform,
        tokenHash,
        tokenHashPrefix: tokenHash.slice(0, 12),
        notificationTokenStatus: 'active',
        notificationPermission: 'granted',
        lastTokenRefreshAt: now,
        lastSeenAt: now,
        updatedAt: now,
        isActive: true,
      }, { merge: true }).catch(() => undefined);
    }

    return { registered: true, scope: 'company', companyId, tokenHash };
  },
);

exports.registerPlatformNotificationToken = onCall(
  { region: 'us-east1' },
  async (request) => {
    const uid = await requireActivePlatformAdmin(request);
    const data = request.data || {};
    const token = sanitizeNotificationToken(data.token);
    const platform = sanitizeNotificationTokenPlatform(data.platform);
    const locale = sanitizeNotificationTokenLocale(data.locale);
    const tokenHash = notificationTokenHash(token);
    const tokenRef = db.collection('platform_notification_tokens').doc(tokenHash);

    const [platformAdminSnapshot, userRecord] = await Promise.all([
      db.doc(`platform_admins/${uid}`).get(),
      auth.getUser(uid).catch(() => null),
    ]);
    const platformAdmin = platformAdminSnapshot.exists ? platformAdminSnapshot.data() || {} : {};

    const existingTokenSnapshot = await tokenRef.get();
    const existingToken = existingTokenSnapshot.exists ? (existingTokenSnapshot.data() || {}) : {};
    if (
      platform === 'web' &&
      existingToken.isActive !== true &&
      optionalString(existingToken.deactivatedReason) === 'fcm-invalid-token' &&
      (optionalString(existingToken.tokenHash) || tokenRef.id) === tokenHash
    ) {
      return {
        registered: false,
        refreshRequired: true,
        reason: 'cached-invalid-web-token',
        scope: 'platformOwner',
        tokenHash,
      };
    }

    await bestEffortDeactivateNotificationTokenEverywhere({
      tokenHash,
      keepPath: tokenRef.path,
      reason: 'registered-platform-token',
      scope: 'platformOwner',
      companyId: '',
      uid,
    });

    const now = FieldValue.serverTimestamp();
    await tokenRef.set({
      tokenHash,
      token,
      scope: 'platformOwner',
      companyId: '',
      uid,
      email: sanitizePlainString(optionalString(platformAdmin.email) || optionalString(userRecord && userRecord.email), 180),
      fullName: sanitizePlainString(optionalString(platformAdmin.fullName) || optionalString(userRecord && userRecord.displayName), 160),
      role: 'platformOwner',
      locale,
      platform,
      installId: sanitizeShortString(data.installId, 140),
      appVersion: sanitizeShortString(data.appVersion, 40),
      buildNumber: sanitizeShortString(data.buildNumber, 20),
      timezone: sanitizeShortString(data.timezone, 80),
      userAgent: sanitizeShortString(data.userAgent, 600),
      webOrigin: sanitizeShortString(data.webOrigin, 240),
      webHref: sanitizeShortString(data.webHref, 500),
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
      deactivatedAt: null,
      deactivatedReason: '',
    }, { merge: true });

    return { registered: true, scope: 'platformOwner', tokenHash };
  },
);


async function bestEffortDeactivateSiblingCompanyNotificationTokens({
  companyId,
  uid,
  platform,
  currentTokenHash,
  webOrigin,
}) {
  try {
    if (optionalString(platform) !== 'web') {
      return;
    }
    const cleanCompanyId = optionalString(companyId);
    const cleanUid = optionalString(uid);
    const cleanCurrentHash = optionalString(currentTokenHash);
    const cleanOrigin = optionalString(webOrigin);
    if (!cleanCompanyId || !cleanUid || !cleanCurrentHash) {
      return;
    }
    const snapshot = await db
      .collection(`companies/${cleanCompanyId}/notification_tokens`)
      .where('uid', '==', cleanUid)
      .limit(100)
      .get();
    if (snapshot.empty) {
      return;
    }
    const currentIsLocalhost = isLocalhostWebOrigin(cleanOrigin);
    let batch = db.batch();
    let updates = 0;
    snapshot.docs.forEach((document) => {
      const data = document.data() || {};
      const hash = optionalString(data.tokenHash) || document.id;
      if (hash === cleanCurrentHash) {
        return;
      }
      if (data.isActive !== true || optionalString(data.platform) !== 'web') {
        return;
      }
      const oldOrigin = optionalString(data.webOrigin);
      const sameOrigin = cleanOrigin && oldOrigin === cleanOrigin;
      const sameLocalhostFamily = currentIsLocalhost && isLocalhostWebOrigin(oldOrigin);
      const missingOrigin = !oldOrigin;
      if (!sameOrigin && !sameLocalhostFamily && !missingOrigin) {
        return;
      }
      batch.set(document.ref, {
        isActive: false,
        updatedAt: FieldValue.serverTimestamp(),
        deactivatedAt: FieldValue.serverTimestamp(),
        deactivatedReason: sameOrigin
          ? 'replaced-by-new-web-token-same-origin'
          : (missingOrigin
            ? 'replaced-by-new-web-token-missing-origin'
            : 'replaced-by-new-localhost-web-token'),
      }, { merge: true });
      updates += 1;
    });
    if (updates > 0) {
      await batch.commit();
    }
  } catch (error) {
    console.error('notification_sibling_token_cleanup_failed', {
      companyId: optionalString(companyId),
      uid: optionalString(uid),
      platform: optionalString(platform),
      code: error && error.code ? error.code : '',
      message: error && error.message ? sanitizeLogText(error.message, 240) : '',
    });
  }
}

function isLocalhostWebOrigin(value) {
  const origin = optionalString(value).toLowerCase();
  return origin.startsWith('http://localhost:') ||
    origin.startsWith('https://localhost:') ||
    origin.startsWith('http://127.0.0.1:') ||
    origin.startsWith('https://127.0.0.1:');
}

exports.removeNotificationToken = onCall(
  { region: 'us-east1' },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Sign in is required.');
    }

    const data = request.data || {};
    const token = sanitizeNotificationToken(data.token);
    const tokenHash = notificationTokenHash(token);
    const scope = optionalString(data.scope) || 'company';
    const uid = request.auth.uid;
    const now = FieldValue.serverTimestamp();

    if (scope === 'platformOwner') {
      await requireActivePlatformAdmin(request);
      await db.collection('platform_notification_tokens').doc(tokenHash).set({
        isActive: false,
        updatedAt: now,
        deactivatedAt: now,
        deactivatedReason: 'client-removed-token',
      }, { merge: true });
      return { removed: true, scope: 'platformOwner', tokenHash };
    }

    const companyId = requiredString(data.companyId, 'companyId');
    validateCompanyId(companyId);
    const companyUser = await requireActiveCompanyUser(request, companyId);
    if (optionalString(companyUser.companyId) !== companyId) {
      throw new HttpsError('permission-denied', 'Company user was not found.');
    }

    const tokenRef = db.collection(`companies/${companyId}/notification_tokens`).doc(tokenHash);
    const snapshot = await tokenRef.get();
    if (snapshot.exists && optionalString(snapshot.get('uid')) && optionalString(snapshot.get('uid')) !== uid) {
      throw new HttpsError('permission-denied', 'Token belongs to another user.');
    }

    await tokenRef.set({
      isActive: false,
      updatedAt: now,
      deactivatedAt: now,
      deactivatedReason: 'client-removed-token',
    }, { merge: true });
    return { removed: true, scope: 'company', companyId, tokenHash };
  },
);

exports.markCompanyNotificationRead = onCall(
  { region: 'us-east1' },
  async (request) => {
    const actorUid = optionalString(request.auth && request.auth.uid);
    if (!actorUid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }
    const payload = request.data || {};
    const companyId = optionalString(payload.companyId);
    const notificationId = optionalString(payload.notificationId);
    validateCompanyId(companyId);
    if (!notificationId) {
      throw new HttpsError('invalid-argument', 'Notification id is required.');
    }

    const actor = await loadCompanyUserSafe(companyId, actorUid);
    if (!actor || actor.isActive !== true) {
      throw new HttpsError('permission-denied', 'You do not have access to this company.');
    }

    const notificationRef = db.doc(`companies/${companyId}/notifications/${safeDocumentId(notificationId)}`);
    const notificationSnapshot = await notificationRef.get();
    if (!notificationSnapshot.exists) {
      throw new HttpsError('not-found', 'Notification was not found.');
    }
    const notification = notificationSnapshot.data() || {};
    const notificationCompanyId = optionalString(notification.companyId);
    if ((notificationCompanyId && notificationCompanyId !== companyId) || optionalString(notification.recipientUid) !== actorUid) {
      throw new HttpsError('permission-denied', 'You cannot update this notification.');
    }

    if (notification.isRead === true) {
      return { updated: 0, alreadyRead: true };
    }

    await notificationRef.update({
      isRead: true,
      readAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { updated: 1, alreadyRead: false };
  },
);

exports.markCompanyNotificationsRead = onCall(
  { region: 'us-east1' },
  async (request) => {
    const actorUid = optionalString(request.auth && request.auth.uid);
    if (!actorUid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }
    const payload = request.data || {};
    const companyId = optionalString(payload.companyId);
    validateCompanyId(companyId);

    const actor = await loadCompanyUserSafe(companyId, actorUid);
    if (!actor || actor.isActive !== true) {
      throw new HttpsError('permission-denied', 'You do not have access to this company.');
    }

    const requestedLimit = Number(payload.limit || 0);
    const batchSize = Math.max(1, Math.min(Number.isFinite(requestedLimit) && requestedLimit > 0 ? requestedLimit : 250, 450));
    let updated = 0;
    let safety = 0;
    const collection = db.collection(`companies/${companyId}/notifications`);

    while (safety < 30) {
      safety += 1;
      const snapshot = await collection
        .where('recipientUid', '==', actorUid)
        .where('isRead', '==', false)
        .limit(batchSize)
        .get();
      if (snapshot.empty) {
        break;
      }
      const batch = db.batch();
      for (const document of snapshot.docs) {
        const data = document.data() || {};
        const notificationCompanyId = optionalString(data.companyId);
        if ((notificationCompanyId && notificationCompanyId !== companyId) || optionalString(data.recipientUid) !== actorUid) {
          continue;
        }
        batch.update(document.ref, {
          isRead: true,
          readAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        updated += 1;
      }
      await batch.commit();
      if (snapshot.size < batchSize) {
        break;
      }
    }

    // Legacy safety pass: old notification docs can miss isRead entirely, which
    // makes the client render them unread but makes a where('isRead', false)
    // query skip them. Sweep the recipient's notification pages by document id
    // and mark every non-read visible notification as read.
    let lastDoc = null;
    let legacySafety = 0;
    while (legacySafety < 30) {
      legacySafety += 1;
      let query = collection
        .where('recipientUid', '==', actorUid)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(batchSize);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }
      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }
      const batch = db.batch();
      let hasUpdates = false;
      for (const document of snapshot.docs) {
        const data = document.data() || {};
        const notificationCompanyId = optionalString(data.companyId);
        if ((notificationCompanyId && notificationCompanyId !== companyId) || optionalString(data.recipientUid) !== actorUid) {
          continue;
        }
        if (data.isRead === true) {
          continue;
        }
        hasUpdates = true;
        batch.update(document.ref, {
          isRead: true,
          readAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        updated += 1;
      }
      if (hasUpdates) {
        await batch.commit();
      }
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < batchSize) {
        break;
      }
    }

    return { updated };
  },
);

exports.refreshActionableReminderNotifications = onCall(
  { region: 'us-east1' },
  async (request) => {
    const actorUid = optionalString(request.auth && request.auth.uid);
    if (!actorUid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }
    const payload = request.data || {};
    const companyId = optionalString(payload.companyId);
    validateCompanyId(companyId);

    const actor = await loadCompanyUserSafe(companyId, actorUid);
    if (!actor || actor.isActive !== true) {
      throw new HttpsError('permission-denied', 'You do not have access to this company.');
    }
    const role = optionalString(actor.role);
    if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(role)) {
      return { checked: 0, created: 0 };
    }
    return refreshActionableReminderWindow({
      companyId,
      actorUid,
      actor,
      nowDate: new Date(),
      limit: 180,
    });
  },
);

exports.createActionableReminderNotifications = onSchedule(
  {
    schedule: '*/5 * * * *',
    timeZone: 'Africa/Cairo',
    region: 'us-east1',
  },
  async () => {
    await refreshActionableReminderWindow({
      nowDate: new Date(),
      limit: 400,
    });
  },
);

async function refreshActionableReminderWindow({ companyId, actorUid, actor, nowDate, limit }) {
  // Live attention reminders are now shown from scoped CRM queries in the app.
  // Do not create persistent notification documents for generic suggestions,
  // because they flood the bell/unread list and make release QA noisy.
  return { checked: 0, created: 0, mode: 'liveAttentionOnly' };

  const now = nowDate instanceof Date ? nowDate : new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
  const staleDealCutoff = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const dueEnd = admin.firestore.Timestamp.fromDate(todayEnd);
  const staleDealTimestamp = admin.firestore.Timestamp.fromDate(staleDealCutoff);
  let checked = 0;
  let created = 0;

  const leadQuery = reminderCollectionQuery({ companyId, collection: 'leads' })
    .where('nextFollowUpAt', '<=', dueEnd)
    .limit(limit || 180);
  const taskQuery = reminderCollectionQuery({ companyId, collection: 'tasks' })
    .where('dueDate', '<=', dueEnd)
    .limit(limit || 180);
  const dealQuery = reminderCollectionQuery({ companyId, collection: 'deals' })
    .where('updatedAt', '<=', staleDealTimestamp)
    .limit(Math.min(limit || 180, 160));

  const [leadSnapshot, taskSnapshot, dealSnapshot] = await Promise.all([
    leadQuery.get(),
    taskQuery.get(),
    dealQuery.get(),
  ]);

  for (const document of leadSnapshot.docs) {
    const lead = document.data() || {};
    const resolvedCompanyId = optionalString(lead.companyId) || companyIdFromScopedPath(document.ref.path);
    if (!resolvedCompanyId || (companyId && resolvedCompanyId !== companyId)) {
      continue;
    }
    if (lead.isArchived === true) {
      continue;
    }
    const status = normalizedWorkflowValue(lead.status);
    if (['won', 'lost', 'converted', 'closed'].includes(status)) {
      continue;
    }
    if (!actorCanReceiveReminder({ actorUid, actor, companyId: resolvedCompanyId, record: lead })) {
      continue;
    }
    const dueAt = timestampToDateSafe(lead.nextFollowUpAt);
    if (!dueAt || dueAt > todayEnd) {
      continue;
    }
    checked += 1;
    const reminderType = dueAt < todayStart ? 'followUpOverdue' : 'followUpDueToday';
    const recipients = await actionableReminderRecipients({
      companyId: resolvedCompanyId,
      record: lead,
      actorUid,
      actor,
      fallbackAdminForUnassigned: true,
    });
    for (const recipient of recipients) {
      const id = await createCompanyNotification({
        companyId: resolvedCompanyId,
        recipientUid: recipient.uid,
        recipientRole: recipient.role,
        type: reminderType,
        module: 'leads',
        recordId: optionalString(lead.id) || document.id,
        recordTitle: optionalString(lead.fullName) || 'Lead follow-up',
        recordSubtitle: optionalString(lead.phone) || optionalString(lead.source),
        route: `/leads/${optionalString(lead.id) || document.id}`,
        actorUid: '',
        actorName: '',
        teamId: optionalString(lead.teamId),
        teamName: optionalString(lead.teamName),
        managerId: optionalString(lead.managerId),
        priority: reminderType === 'followUpOverdue' ? 'high' : 'normal',
        actionState: 'actionNeeded',
        metadata: {
          rule: reminderType,
          dueAt: dueAt.toISOString(),
          titleEn: reminderType === 'followUpOverdue' ? 'Follow-up overdue' : 'Follow-up due today',
          titleAr: reminderType === 'followUpOverdue' ? 'متابعة متأخرة' : 'متابعة مستحقة اليوم',
          bodyEn: 'Open the lead and complete the next follow-up action.',
          bodyAr: 'افتح العميل المحتمل وأنهِ إجراء المتابعة التالي.',
        },
        dedupeKey: `actionable_${reminderType}_${optionalString(lead.id) || document.id}_${recipient.uid}_${dateKey(todayStart)}`,
      });
      if (id) created += 1;
    }
  }

  for (const document of taskSnapshot.docs) {
    const task = document.data() || {};
    const resolvedCompanyId = optionalString(task.companyId) || companyIdFromScopedPath(document.ref.path);
    if (!resolvedCompanyId || (companyId && resolvedCompanyId !== companyId)) {
      continue;
    }
    if (task.isActive === false) {
      continue;
    }
    const status = normalizedWorkflowValue(task.status);
    if (['completed', 'cancelled', 'canceled', 'closed'].includes(status)) {
      continue;
    }
    if (!actorCanReceiveReminder({ actorUid, actor, companyId: resolvedCompanyId, record: task })) {
      continue;
    }
    const dueAt = timestampToDateSafe(task.dueDate);
    if (!dueAt || dueAt > todayEnd) {
      continue;
    }
    checked += 1;
    const reminderType = dueAt < todayStart ? 'taskOverdue' : 'taskDueToday';
    const recipients = await actionableReminderRecipients({
      companyId: resolvedCompanyId,
      record: task,
      actorUid,
      actor,
      fallbackAdminForUnassigned: false,
    });
    for (const recipient of recipients) {
      const id = await createCompanyNotification({
        companyId: resolvedCompanyId,
        recipientUid: recipient.uid,
        recipientRole: recipient.role,
        type: reminderType,
        module: 'tasks',
        recordId: optionalString(task.id) || document.id,
        recordTitle: optionalString(task.title) || 'Task',
        recordSubtitle: optionalString(task.relatedTitle) || optionalString(task.relatedSubtitle),
        route: `/tasks/${optionalString(task.id) || document.id}/edit`,
        actorUid: '',
        actorName: '',
        teamId: optionalString(task.teamId),
        teamName: optionalString(task.teamName),
        managerId: optionalString(task.managerId),
        priority: reminderType === 'taskOverdue' ? 'high' : 'normal',
        actionState: 'actionNeeded',
        metadata: {
          rule: reminderType,
          dueAt: dueAt.toISOString(),
          titleEn: reminderType === 'taskOverdue' ? 'Task overdue' : 'Task due today',
          titleAr: reminderType === 'taskOverdue' ? 'مهمة متأخرة' : 'مهمة مستحقة اليوم',
          bodyEn: 'Open the task and finish the required action.',
          bodyAr: 'افتح المهمة وأنهِ الإجراء المطلوب.',
        },
        dedupeKey: `actionable_${reminderType}_${optionalString(task.id) || document.id}_${recipient.uid}_${dateKey(todayStart)}`,
      });
      if (id) created += 1;
    }
  }

  for (const document of dealSnapshot.docs) {
    const deal = document.data() || {};
    const resolvedCompanyId = optionalString(deal.companyId) || companyIdFromScopedPath(document.ref.path);
    if (!resolvedCompanyId || (companyId && resolvedCompanyId !== companyId)) {
      continue;
    }
    if (deal.isActive === false) {
      continue;
    }
    const stage = normalizedWorkflowValue(deal.stage);
    if (['won', 'lost', 'closedwon', 'closedlost', 'closed'].includes(stage)) {
      continue;
    }
    if (!actorCanReceiveReminder({ actorUid, actor, companyId: resolvedCompanyId, record: deal })) {
      continue;
    }
    checked += 1;
    const recipients = await actionableReminderRecipients({
      companyId: resolvedCompanyId,
      record: deal,
      actorUid,
      actor,
      fallbackAdminForUnassigned: false,
    });
    for (const recipient of recipients) {
      const dealId = optionalString(deal.id) || document.id;
      const id = await createCompanyNotification({
        companyId: resolvedCompanyId,
        recipientUid: recipient.uid,
        recipientRole: recipient.role,
        type: 'systemInfo',
        module: 'deals',
        recordId: dealId,
        recordTitle: dealTitle(deal, dealId),
        recordSubtitle: optionalString(deal.propertyLocation) || optionalString(deal.clientPhone),
        route: `/deals/${dealId}`,
        actorUid: '',
        actorName: '',
        teamId: optionalString(deal.teamId),
        teamName: optionalString(deal.teamName),
        managerId: optionalString(deal.managerId),
        priority: 'high',
        actionState: 'actionNeeded',
        metadata: {
          rule: 'dealStuck',
          titleEn: 'Deal needs movement',
          titleAr: 'صفقة تحتاج تحريك',
          bodyEn: 'This deal has not moved for more than 7 days. Review the next step.',
          bodyAr: 'هذه الصفقة لم تتحرك منذ أكثر من 7 أيام. راجع الخطوة التالية.',
        },
        fallbackTitle: 'Deal needs movement',
        fallbackBody: 'This deal has not moved for more than 7 days. Review the next step.',
        dedupeKey: `actionable_dealStuck_${dealId}_${recipient.uid}_${dateKey(todayStart)}`,
      });
      if (id) created += 1;
    }
  }

  return { checked, created };
}

function reminderCollectionQuery({ companyId, collection }) {
  const cleanCompanyId = optionalString(companyId);
  if (cleanCompanyId) {
    return db.collection(`companies/${cleanCompanyId}/${collection}`);
  }
  return db.collectionGroup(collection);
}

function actorCanReceiveReminder({ actorUid, actor, record }) {
  if (!actor) {
    return true;
  }
  const role = optionalString(actor.role);
  if (role === 'admin') {
    return true;
  }
  if (role === 'manager') {
    const actorTeamId = optionalString(actor.teamId);
    return optionalString(record.assignedTo) === actorUid ||
      optionalString(record.managerId) === actorUid ||
      (actorTeamId && optionalString(record.teamId) === actorTeamId);
  }
  if (role === 'salesAgent' || role === 'marketing') {
    return optionalString(record.assignedTo) === actorUid;
  }
  return false;
}

async function actionableReminderRecipients({ companyId, record, actorUid, actor, fallbackAdminForUnassigned }) {
  const recipients = new Map();
  const addRecipient = async (uid) => {
    const cleanUid = optionalString(uid);
    if (!cleanUid) return;
    const user = await loadCompanyUserSafe(companyId, cleanUid);
    if (!user || user.isActive !== true) return;
    const role = optionalString(user.role);
    if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(role)) return;
    recipients.set(cleanUid, { uid: cleanUid, role });
  };

  if (actor) {
    const role = optionalString(actor.role);
    if (role === 'admin') {
      const assignedTo = optionalString(record.assignedTo);
      if (assignedTo) {
        await addRecipient(assignedTo);
      } else {
        await addRecipient(actorUid);
      }
    } else if (role === 'manager') {
      await addRecipient(optionalString(record.assignedTo) || actorUid);
      await addRecipient(actorUid);
    } else {
      await addRecipient(actorUid);
    }
  } else {
    await addRecipient(optionalString(record.assignedTo));
    await addRecipient(optionalString(record.managerId));
    if (recipients.size === 0 && fallbackAdminForUnassigned) {
      const admins = await db.collection(`companies/${companyId}/users`)
        .where('role', '==', 'admin')
        .where('isActive', '==', true)
        .limit(20)
        .get();
      for (const doc of admins.docs) {
        recipients.set(doc.id, { uid: doc.id, role: 'admin' });
      }
    }
  }
  return [...recipients.values()];
}

function timestampToDateSafe(value) {
  if (!value) return null;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (value.toDate && typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function companyIdFromScopedPath(path) {
  const parts = optionalString(path).split('/');
  const companiesIndex = parts.indexOf('companies');
  if (companiesIndex < 0 || companiesIndex + 1 >= parts.length) {
    return '';
  }
  return parts[companiesIndex + 1];
}

function dateKey(date) {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${year}${month}${day}`;
}

exports.refreshAppointmentTimingNotifications = onCall(
  { region: 'us-east1' },
  async (request) => {
    const actorUid = optionalString(request.auth && request.auth.uid);
    if (!actorUid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }
    const payload = request.data || {};
    const companyId = optionalString(payload.companyId);
    validateCompanyId(companyId);

    const actor = await loadCompanyUserSafe(companyId, actorUid);
    if (!actor || actor.isActive !== true) {
      throw new HttpsError('permission-denied', 'You do not have access to this company.');
    }

    const role = optionalString(actor.role);
    if (!['admin', 'manager', 'salesAgent', 'marketing'].includes(role)) {
      return { checked: 0, processed: 0 };
    }

    return refreshAppointmentTimingWindow({
      companyId,
      actorUid,
      actor,
      nowDate: new Date(),
      limit: 250,
    });
  },
);

exports.createDueAppointmentNotifications = onSchedule(
  {
    schedule: '* * * * *',
    timeZone: 'Africa/Cairo',
    region: 'us-east1',
  },
  async () => {
    await refreshAppointmentTimingWindow({
      nowDate: new Date(),
      limit: 500,
    });
  },
);

async function refreshAppointmentTimingWindow({
  companyId,
  actorUid,
  actor,
  nowDate,
  limit,
}) {
  const dueSoonDate = new Date(nowDate.getTime() + 10 * 60 * 1000);
  // Keep due-now recovery short enough to avoid turning very old missed
  // appointments into new unread notifications, but wide enough to recover
  // from scheduler/cold-start delay.
  const lookbackDate = new Date(nowDate.getTime() - 30 * 60 * 1000);
  const now = admin.firestore.Timestamp.fromDate(nowDate);
  const dueSoonCutoff = admin.firestore.Timestamp.fromDate(dueSoonDate);
  const lookback = admin.firestore.Timestamp.fromDate(lookbackDate);

  const dueQuery = appointmentTimingQuery(companyId)
    .where('scheduledAt', '>=', lookback)
    .where('scheduledAt', '<=', now)
    .limit(limit || 250);
  const dueSoonQuery = appointmentTimingQuery(companyId)
    .where('scheduledAt', '>', now)
    .where('scheduledAt', '<=', dueSoonCutoff)
    .limit(limit || 250);

  const [dueSnapshot, dueSoonSnapshot] = await Promise.all([
    dueQuery.get(),
    dueSoonQuery.get(),
  ]);

  const writes = [];
  let checked = 0;
  for (const document of [...dueSnapshot.docs, ...dueSoonSnapshot.docs]) {
    const appointment = document.data() || {};
    const resolvedCompanyId = optionalString(appointment.companyId) || companyIdFromAppointmentPath(document.ref.path);
    const appointmentId = optionalString(appointment.id) || document.id;
    const status = normalizedWorkflowValue(appointment.status);
    if (!resolvedCompanyId || !appointmentId || !['scheduled', 'rescheduled'].includes(status)) {
      continue;
    }
    if (companyId && resolvedCompanyId !== companyId) {
      continue;
    }
    if (actor && !canActorRefreshAppointmentTiming({ actorUid, actor, appointment })) {
      continue;
    }

    checked += 1;
    writes.push(createAppointmentTimingNotifications({
      companyId: resolvedCompanyId,
      appointmentId,
      appointment,
      now,
    }));
  }

  const settled = await Promise.allSettled(writes);
  const processed = settled.filter((item) => item.status === 'fulfilled').length;
  return { checked, processed };
}

function appointmentTimingQuery(companyId) {
  const cleanCompanyId = optionalString(companyId);
  if (cleanCompanyId) {
    return db.collection(`companies/${cleanCompanyId}/appointments`);
  }
  return db.collectionGroup('appointments');
}

function canActorRefreshAppointmentTiming({ actorUid, actor, appointment }) {
  const role = optionalString(actor.role);
  if (role === 'admin') {
    return true;
  }
  if (role === 'manager') {
    const actorTeamId = optionalString(actor.teamId);
    const appointmentTeamId = optionalString(appointment.teamId);
    const appointmentManagerId = optionalString(appointment.managerId);
    return optionalString(appointment.assignedTo) === actorUid ||
      appointmentManagerId === actorUid ||
      (actorTeamId && appointmentTeamId === actorTeamId);
  }
  if (role === 'salesAgent' || role === 'marketing') {
    return optionalString(appointment.assignedTo) === actorUid;
  }
  return false;
}

function companyIdFromAppointmentPath(path) {
  const parts = optionalString(path).split('/');
  const companiesIndex = parts.indexOf('companies');
  if (companiesIndex < 0 || companiesIndex + 1 >= parts.length) {
    return '';
  }
  return parts[companiesIndex + 1];
}

exports.createLeadAssignmentNotification = onDocumentWritten(
  'companies/{companyId}/leads/{leadId}',
  async (event) => {
    const companyId = optionalString(event.params.companyId);
    const leadId = optionalString(event.params.leadId);
    validateCompanyId(companyId);
    if (!event.data || !event.data.after.exists) {
      return;
    }
    const before = event.data.before.exists ? (event.data.before.data() || {}) : null;
    const after = event.data.after.data() || {};
    const afterCompanyId = optionalString(after.companyId);
    const afterRecordId = optionalString(after.id) || leadId;
    if ((afterCompanyId && afterCompanyId !== companyId) || afterRecordId !== leadId) {
      return;
    }
    if (after.isArchived === true || after.isActive === false) {
      return;
    }

    const previousAssignedTo = before ? optionalString(before.assignedTo) : '';
    const nextAssignedTo = optionalString(after.assignedTo);
    if (previousAssignedTo === nextAssignedTo) {
      await createLeadImportantStatusNotifications({
        companyId,
        leadId,
        actorUid: optionalString(after.updatedBy) || optionalString(after.createdBy),
        actor: await loadCompanyUserSafe(companyId, optionalString(after.updatedBy) || optionalString(after.createdBy)),
        existingLead: before,
        payload: after,
      }).catch(() => undefined);
      return;
    }

    const actorUid = optionalString(after.updatedBy) || optionalString(after.createdBy);
    const actor = await loadCompanyUserSafe(companyId, actorUid);
    const actorName = actor ? optionalString(actor.fullName) || optionalString(actor.email) : '';
    await createAssignmentNotificationsForRecord({
      companyId,
      module: 'leads',
      recordId: leadId,
      recordTitle: optionalString(after.fullName),
      recordSubtitle: optionalString(after.sourceDetails) || optionalString(after.source),
      route: `/leads/${leadId}`,
      previousRecord: before,
      nextRecord: after,
      actorUid,
      actorName,
      assignedType: previousAssignedTo ? 'leadReassigned' : 'leadAssigned',
      removedType: 'leadRemovedFromYou',
      priority: optionalString(after.priority) === 'high' ? 'high' : 'normal',
      metadata: {
        source: optionalString(after.source),
        status: optionalString(after.status),
        previousAssignedTo,
        assignedToName: optionalString(after.assignedToName),
      },
      dedupePrefix: `lead_${leadId}_${event.id}`,
    }).catch(() => undefined);
  },
);

exports.createTaskAssignmentNotification = onDocumentWritten(
  'companies/{companyId}/tasks/{taskId}',
  async (event) => {
    const companyId = optionalString(event.params.companyId);
    const taskId = optionalString(event.params.taskId);
    validateCompanyId(companyId);
    if (!event.data || !event.data.after.exists) {
      return;
    }

    const before = event.data.before.exists ? (event.data.before.data() || {}) : null;
    const after = event.data.after.data() || {};
    const afterCompanyId = optionalString(after.companyId);
    const afterRecordId = optionalString(after.id) || taskId;
    if ((afterCompanyId && afterCompanyId !== companyId) || afterRecordId !== taskId) {
      return;
    }
    if (after.isActive === false) {
      return;
    }

    const previousAssignedTo = before ? optionalString(before.assignedTo) : '';
    const nextAssignedTo = optionalString(after.assignedTo);
    const actorUid = optionalString(after.updatedBy) || optionalString(after.createdBy);
    const actor = await loadCompanyUserSafe(companyId, actorUid);
    const actorName = actor
      ? optionalString(actor.fullName) || optionalString(actor.email)
      : '';
    if (previousAssignedTo === nextAssignedTo) {
      await createTaskStatusNotifications({
        companyId,
        taskId,
        before,
        after,
        actorUid,
        actorName,
        eventId: event.id,
      }).catch(() => undefined);
      return;
    }

    await createAssignmentNotificationsForRecord({
      companyId,
      module: 'tasks',
      recordId: taskId,
      recordTitle: optionalString(after.title),
      recordSubtitle: optionalString(after.relatedTitle) || optionalString(after.relatedSubtitle),
      route: `/tasks/${taskId}/edit`,
      previousRecord: before,
      nextRecord: after,
      actorUid,
      actorName,
      assignedType: previousAssignedTo ? 'taskReassigned' : 'taskAssigned',
      removedType: 'taskRemovedFromYou',
      priority: optionalString(after.priority) === 'high' ? 'high' : 'normal',
      metadata: {
        status: optionalString(after.status),
        dueDate: firestoreTimestampToIso(after.dueDate),
        relatedType: optionalString(after.relatedType),
      },
      dedupePrefix: `task_${taskId}_${event.id}`,
    }).catch(() => undefined);
    return;
  },
);

exports.createClientAssignmentNotification = onDocumentWritten(
  'companies/{companyId}/clients/{clientId}',
  async (event) => {
    const companyId = optionalString(event.params.companyId);
    const clientId = optionalString(event.params.clientId);
    validateCompanyId(companyId);
    if (!event.data || !event.data.after.exists) {
      return;
    }
    const before = event.data.before.exists ? (event.data.before.data() || {}) : null;
    const after = event.data.after.data() || {};
    const afterCompanyId = optionalString(after.companyId);
    const afterRecordId = optionalString(after.id) || clientId;
    if ((afterCompanyId && afterCompanyId !== companyId) || afterRecordId !== clientId) {
      return;
    }
    if (after.isActive === false) {
      return;
    }
    const previousAssignedTo = before ? optionalString(before.assignedTo) : '';
    const nextAssignedTo = optionalString(after.assignedTo);
    if (previousAssignedTo === nextAssignedTo) {
      return;
    }
    const actorUid = optionalString(after.updatedBy) || optionalString(after.createdBy);
    const actor = await loadCompanyUserSafe(companyId, actorUid);
    const actorName = actor ? optionalString(actor.fullName) || optionalString(actor.email) : '';
    await createAssignmentNotificationsForRecord({
      companyId,
      module: 'clients',
      recordId: clientId,
      recordTitle: optionalString(after.fullName),
      recordSubtitle: optionalString(after.phone) || optionalString(after.email),
      route: `/clients/${clientId}`,
      previousRecord: before,
      nextRecord: after,
      actorUid,
      actorName,
      assignedType: previousAssignedTo ? 'clientReassigned' : 'clientAssigned',
      removedType: 'clientRemovedFromYou',
      priority: 'normal',
      metadata: {
        preferredLocation: optionalString(after.preferredLocation),
        preferredPropertyType: optionalString(after.preferredPropertyType),
      },
      dedupePrefix: `client_${clientId}_${event.id}`,
    }).catch(() => undefined);
  },
);

exports.createDealAssignmentNotification = onDocumentWritten(
  'companies/{companyId}/deals/{dealId}',
  async (event) => {
    const companyId = optionalString(event.params.companyId);
    const dealId = optionalString(event.params.dealId);
    validateCompanyId(companyId);
    if (!event.data || !event.data.after.exists) {
      return;
    }
    const before = event.data.before.exists ? (event.data.before.data() || {}) : null;
    const after = event.data.after.data() || {};
    const afterCompanyId = optionalString(after.companyId);
    const afterRecordId = optionalString(after.id) || dealId;
    if ((afterCompanyId && afterCompanyId !== companyId) || afterRecordId !== dealId) {
      return;
    }
    if (after.isActive === false) {
      return;
    }
    const previousAssignedTo = before ? optionalString(before.assignedTo) : '';
    const nextAssignedTo = optionalString(after.assignedTo);
    const actorUid = optionalString(after.updatedBy) || optionalString(after.createdBy);
    const actor = await loadCompanyUserSafe(companyId, actorUid);
    const actorName = actor ? optionalString(actor.fullName) || optionalString(actor.email) : '';

    if (previousAssignedTo !== nextAssignedTo) {
      await createAssignmentNotificationsForRecord({
        companyId,
        module: 'deals',
        recordId: dealId,
        recordTitle: dealTitle(after, dealId),
        recordSubtitle: optionalString(after.propertyLocation) || optionalString(after.clientPhone),
        route: `/deals/${dealId}`,
        previousRecord: before,
        nextRecord: after,
        actorUid,
        actorName,
        assignedType: previousAssignedTo ? 'dealReassigned' : 'dealAssigned',
        removedType: 'dealRemovedFromYou',
        priority: optionalString(after.stage) === 'won' ? 'high' : 'normal',
        metadata: {
          stage: optionalString(after.stage),
          expectedValue: typeof after.expectedValue === 'number' ? after.expectedValue : null,
        },
        dedupePrefix: `deal_${dealId}_${event.id}`,
      }).catch(() => undefined);
      return;
    }

    await createDealStageNotifications({
      companyId,
      dealId,
      before,
      after,
      actorUid,
      actorName,
      eventId: event.id,
    }).catch(() => undefined);
  },
);


exports.generateCompanyUserPasswordResetLink = onCall(async (request) => {
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  validateCompanyId(companyId);
  const actorUid = await requirePlatformOrCompanyAdmin(request, companyId);
  const isPlatformActor = await isActivePlatformAdminUid(actorUid);
  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  const company = companySnapshot.exists ? companySnapshot.data() || {} : {};
  enforceUserManagementFeature(company, isPlatformActor);

  const { companyUserSnapshot, userRecord } = await loadCompanyUserAndAuthUser({
    companyId,
    uid,
  });
  const companyUser = companyUserSnapshot.data() || {};
  if (!isPlatformActor) {
    assertCompanyAdminCanManageTarget({
      actorUid,
      targetUid: uid,
      targetUser: companyUser,
      nextActive: companyUser.isActive !== false,
    });
  }
  const email = normalizeEmail(userRecord.email || companyUser.email || '');
  if (!email) {
    throw new HttpsError('failed-precondition', 'Target user email was not found.');
  }

  const passwordResetLink = await auth.generatePasswordResetLink(email);
  await db.collection('platform_security_alerts').add({
    type: 'platformPasswordResetLinkGenerated',
    companyId,
    targetUid: uid,
    targetEmail: email,
    actorUid,
    createdAt: FieldValue.serverTimestamp(),
  });
  if (await isActivePlatformAdminUid(actorUid)) {
    const [actor, companySnapshot] = await Promise.all([
      platformActorSummary(actorUid),
      db.doc(`companies/${companyId}`).get(),
    ]);
    const company = companySnapshot.exists ? companySnapshot.data() || {} : {};
    await createPlatformNotificationSafely('generate_company_user_password_reset_link', {
      type: 'companyUserPasswordReset',
      title: 'Company user password action',
      message: `A password reset link was generated for ${companyUser.fullName || email}.`,
      severity: 'warning',
      source: 'user',
      route: '/platform',
      actorId: actor.actorId,
      actorName: actor.actorName,
      actorEmail: actor.actorEmail,
      companyId,
      companyName: companyNotificationName(companyId, company),
      metadata: {
        targetUid: uid,
        targetEmail: email,
        action: 'passwordResetLinkGenerated',
      },
    });
  }

  return { uid, companyId, email, passwordResetLink };
});

exports.createPlatformSupportNotification = onDocumentWritten(
  'support_tickets/{ticketId}',
  async (event) => {
    const before = event.data && event.data.before ? event.data.before : null;
    const after = event.data && event.data.after ? event.data.after : null;
    const ticketId = event.params.ticketId;
    if (!after || !after.exists) {
      return;
    }
    const ticket = after.data() || {};
    const previousTicket = before && before.exists ? before.data() || {} : null;
    const ticketType = optionalString(ticket.type);
    const priority = optionalString(ticket.priority);
    const status = optionalString(ticket.status);
    const companyId = optionalString(ticket.companyId);
    const companyName = sanitizePlainString(optionalString(ticket.companyName), 240);
    const actorId = sanitizePlainString(optionalString(ticket.userId), 160);
    const actorName = sanitizePlainString(optionalString(ticket.userName), 160);
    const actorEmail = sanitizePlainString(optionalString(ticket.userEmail), 180);
    const route = '/platform/support';

    if (!previousTicket) {
      if (ticketType === 'feedback') {
        await createPlatformNotificationSafely('support_feedback_created', {
          id: `feedback_${ticketId}`,
          type: 'feedbackSubmitted',
          title: 'Feedback submitted',
          message: 'A customer submitted feedback.',
          severity: 'info',
          source: 'support',
          route,
          actorId,
          actorName,
          actorEmail,
          companyId,
          companyName,
          metadata: {
            ticketId,
            category: ticket.category || '',
            rating: Number(ticket.rating || 0),
            type: ticketType,
          },
        });
        return;
      }

      const isUrgent = priority === 'urgent';
      await createPlatformNotificationSafely('support_ticket_created', {
        id: isUrgent ? `urgent_support_${ticketId}` : `support_${ticketId}`,
        type: isUrgent ? 'urgentSupportTicketCreated' : 'supportTicketCreated',
        title: isUrgent ? 'Urgent support ticket created' : 'Support ticket created',
        message: isUrgent ? 'An urgent support ticket was created.' : 'A support ticket was created.',
        severity: isUrgent ? 'urgent' : 'info',
        source: 'support',
        route,
        actorId,
        actorName,
        actorEmail,
        companyId,
        companyName,
        metadata: {
          ticketId,
          category: ticket.category || '',
          priority,
          status,
          type: ticketType || 'support',
        },
      });
      return;
    }

    const previousStatus = optionalString(previousTicket.status);
    if (previousStatus && status && previousStatus !== status) {
      await createPlatformNotificationSafely('support_ticket_status_changed', {
        type: 'supportTicketStatusChanged',
        title: 'Support status changed',
        message: `Support request status changed from ${previousStatus} to ${status}.`,
        severity: status === 'resolved' || status === 'closed' ? 'success' : 'info',
        source: 'support',
        route,
        actorId,
        actorName,
        actorEmail,
        companyId,
        companyName,
        metadata: {
          ticketId,
          previousStatus,
          status,
          type: ticketType || 'support',
        },
      });

      try {
        const requestKind = ticketType === 'feedback' ? 'feedback' : 'support request';
        await createCompanyNotification({
          companyId,
          recipientUid: actorId,
          recipientRole: optionalString(ticket.userRole),
          type: 'systemInfo',
          module: 'support',
          recordId: ticketId,
          recordTitle: sanitizePlainString(
            optionalString(ticket.title) || (ticketType === 'feedback' ? 'Feedback' : 'Support request'),
            240,
          ),
          recordSubtitle: sanitizePlainString(status, 120),
          route: '/support',
          actorUid: '',
          actorName: 'Masar Support',
          priority: status === 'resolved' || status === 'closed' ? 'normal' : 'high',
          metadata: {
            ticketId,
            previousStatus,
            status,
            type: ticketType || 'support',
          },
          fallbackTitle: 'Support request status updated',
          fallbackBody: `Your ${requestKind} status changed from ${previousStatus} to ${status}.`,
        });
      } catch (error) {
        console.error('support_status_user_notification_failed', {
          ticketId,
          companyId,
          recipientUid: actorId,
          code: error && error.code ? error.code : '',
          message: error && error.message ? error.message : '',
        });
      }
    }
  },
);

exports.recordLoginActivity = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const uid = request.auth.uid;
  const data = request.data || {};
  const companyId = optionalString(data.companyId);
  const clientInfo = {
    userAgent: sanitizeShortString(data.userAgent, 600),
    platform: sanitizeShortString(data.platform, 80),
    browser: sanitizeShortString(data.browser, 80),
    deviceType: sanitizeShortString(data.deviceType, 80),
    locale: sanitizeShortString(data.locale, 30),
    timezone: sanitizeShortString(data.timezone, 80),
    appVersion: sanitizeShortString(data.appVersion, 40),
  };
  const ipAddress = requestIpAddress(request);
  const authProvider = authProviderFromToken(request.auth.token);
  const userRecord = await auth.getUser(uid);

  if (companyId) {
    validateCompanyId(companyId);
    const companySnapshot = await db.doc(`companies/${companyId}`).get();
    if (!companySnapshot.exists) {
      throw new HttpsError('not-found', 'Company was not found.');
    }
    const company = companySnapshot.data() || {};
    if (company.isActive !== true || company.status === 'inactive') {
      throw new HttpsError('failed-precondition', 'Company is inactive.');
    }
    const companyUserRef = db.doc(`companies/${companyId}/users/${uid}`);
    const companyUserSnapshot = await companyUserRef.get();
    if (!companyUserSnapshot.exists) {
      throw new HttpsError('permission-denied', 'Company user was not found.');
    }
    const companyUser = companyUserSnapshot.data() || {};
    if (companyUser.isActive !== true) {
      throw new HttpsError('permission-denied', 'Company user is inactive.');
    }
    const event = loginActivityPayload({
      uid,
      companyId,
      email: userRecord.email || companyUser.email || '',
      role: companyUser.role || '',
      fullName: companyUser.fullName || userRecord.displayName || '',
      ipAddress,
      authProvider,
      clientInfo,
    });

    const eventRef = db.collection(`companies/${companyId}/login_activity`).doc();
    const batch = db.batch();
    batch.set(eventRef, event);
    batch.set(companyUserRef, lastLoginSummary(event), { merge: true });
    batch.set(db.doc(`users/${uid}`), lastLoginSummary(event), { merge: true });
    await batch.commit();
    return { uid, companyId };
  }

  const platformAdminRef = db.doc(`platform_admins/${uid}`);
  const platformAdminSnapshot = await platformAdminRef.get();
  if (!platformAdminSnapshot.exists || platformAdminSnapshot.get('isActive') !== true) {
    throw new HttpsError('permission-denied', 'Platform admin access required.');
  }

  const adminData = platformAdminSnapshot.data() || {};
  const event = loginActivityPayload({
    uid,
    companyId: '',
    email: userRecord.email || adminData.email || '',
    role: 'platformAdmin',
    fullName: adminData.fullName || userRecord.displayName || '',
    ipAddress,
    authProvider,
    clientInfo,
  });
  const eventRef = db.collection('platform_login_activity').doc();
  const batch = db.batch();
  batch.set(eventRef, event);
  batch.set(platformAdminRef, lastLoginSummary(event), { merge: true });
  batch.set(db.doc(`users/${uid}`), lastLoginSummary(event), { merge: true });
  await batch.commit();

  return { uid };
});

async function requireActivePlatformAdmin(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  if (!(await isActivePlatformAdminUid(request.auth.uid))) {
    throw new HttpsError('permission-denied', 'Platform admin access required.');
  }

  return request.auth.uid;
}

async function isActivePlatformAdminUid(uid) {
  const cleanUid = optionalString(uid);
  if (!cleanUid) {
    return false;
  }
  const snapshot = await db.doc(`platform_admins/${cleanUid}`).get();
  return snapshot.exists && snapshot.get('isActive') === true;
}

async function requirePlatformOrCompanyAdmin(request, companyId) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  if (await isActivePlatformAdminUid(request.auth.uid)) {
    return request.auth.uid;
  }

  return requireActiveCompanyAdmin(request, companyId);
}

async function requireActiveCompanyUser(request, companyId) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const [companySnapshot, companyUserSnapshot] = await Promise.all([
    db.doc(`companies/${companyId}`).get(),
    db.doc(`companies/${companyId}/users/${request.auth.uid}`).get(),
  ]);

  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  if (company.isActive !== true || company.status === 'inactive') {
    throw new HttpsError('failed-precondition', 'Company is inactive.');
  }

  if (!companyUserSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Company user was not found.');
  }
  const companyUser = companyUserSnapshot.data() || {};
  if (companyUser.companyId !== companyId || companyUser.isActive !== true) {
    throw new HttpsError('permission-denied', 'Company user is inactive.');
  }

  return companyUser;
}

async function requireActiveCompanyAdmin(request, companyId) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const [companySnapshot, companyUserSnapshot] = await Promise.all([
    db.doc(`companies/${companyId}`).get(),
    db.doc(`companies/${companyId}/users/${request.auth.uid}`).get(),
  ]);

  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  if (company.isActive !== true || company.status === 'inactive') {
    throw new HttpsError('failed-precondition', 'Company is inactive.');
  }

  if (!companyUserSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Only company admins can manage team members.');
  }
  const companyUser = companyUserSnapshot.data() || {};
  if (companyUser.companyId !== companyId || companyUser.isActive !== true) {
    throw new HttpsError('permission-denied', 'Only active company admins can manage team members.');
  }
  if (companyUser.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only company admins can manage team members.');
  }

  return request.auth.uid;
}

async function assertAdminEmailNotUsedInAuth(email) {
  try {
    await auth.getUserByEmail(email);
  } catch (error) {
    const code = optionalString(error && error.code);
    if (code === 'auth/user-not-found') {
      return;
    }
    if (code === 'auth/invalid-email') {
      throw registrationError('invalid-argument', 'invalid-admin-email');
    }
    throw registrationError('internal', 'unable-to-complete-registration');
  }
  throw registrationError('already-exists', 'admin-email-already-exists');
}

async function assertEmailNotUsedInGlobalProfiles(email) {
  const normalized = normalizeEmail(email);
  const globalUserSnapshot = await db.collection('users')
    .where('email', '==', normalized)
    .limit(1)
    .get();
  if (!globalUserSnapshot.empty) {
    throw registrationError('already-exists', 'admin-email-already-exists');
  }
}

async function assertEmailNotUsedInCompanyUserProfiles(email) {
  // Firebase Auth and the global users collection are the source of truth for
  // login-email uniqueness during registration. Avoid a broad collectionGroup
  // scan here because it can require an index and fail with FAILED_PRECONDITION.
  return;
}

async function getOrCreateUserForInvitation({ email, displayName, temporaryPassword = '' }) {
  let userRecord;
  let created = false;
  const cleanTemporaryPassword = optionalPassword(temporaryPassword);
  const usesTemporaryPassword = cleanTemporaryPassword.length > 0;

  try {
    userRecord = await auth.getUserByEmail(email);
    if (usesTemporaryPassword) {
      throw new HttpsError(
        'already-exists',
        'Company user already exists.',
      );
    }
    const update = {};
    if (!userRecord.displayName && displayName) {
      update.displayName = displayName;
    }
    if (userRecord.disabled) {
      update.disabled = false;
    }
    if (Object.keys(update).length > 0) {
      userRecord = await auth.updateUser(userRecord.uid, update);
    }
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }

    userRecord = await auth.createUser({
      email,
      displayName,
      password: usesTemporaryPassword ? cleanTemporaryPassword : undefined,
      emailVerified: false,
      disabled: false,
    });
    created = true;
  }

  const passwordResetLink = usesTemporaryPassword
    ? ''
    : await auth.generatePasswordResetLink(email);
  return { userRecord, passwordResetLink, created };
}

function writeGlobalUser(batch, uid, data) {
  batch.set(
    db.doc(`users/${uid}`),
    {
      uid,
      email: data.email,
      fullName: data.fullName,
      phone: data.phone,
      isActive: data.isActive,
      ...(typeof data.mustChangePassword === 'boolean'
        ? { mustChangePassword: data.mustChangePassword }
        : {}),
      ...(data.passwordSetupMethod
        ? { passwordSetupMethod: data.passwordSetupMethod }
        : {}),
      createdAt: data.now,
      updatedAt: data.now,
    },
    { merge: true },
  );
}

function writeCompanyUser(batch, companyId, uid, data) {
  batch.set(
    db.doc(`companies/${companyId}/users/${uid}`),
    {
      uid,
      companyId,
      fullName: data.fullName,
      email: data.email,
      phone: data.phone,
      role: data.role,
      isActive: data.isActive,
      ...(typeof data.mustChangePassword === 'boolean'
        ? { mustChangePassword: data.mustChangePassword }
        : {}),
      ...(data.passwordSetupMethod
        ? { passwordSetupMethod: data.passwordSetupMethod }
        : {}),
      createdAt: data.now,
      createdBy: data.actorUid,
      updatedAt: data.now,
      updatedBy: data.actorUid,
      teamId: '',
      teamName: '',
      managerId: '',
      managerName: '',
    },
    { merge: true },
  );
}

function writeMembership(batch, uid, companyId, data) {
  batch.set(
    db.doc(`users/${uid}/memberships/${companyId}`),
    {
      companyId,
      companyName: data.companyName,
      role: data.role,
      isActive: data.isActive,
      status: data.status || (data.isActive ? 'active' : 'inactive'),
      createdAt: data.now,
      updatedAt: data.now,
    },
    { merge: true },
  );
}


async function requireDataHealthActor({
  request,
  companyId,
  allowPlatform,
  allowCompanyAdmin,
  allowManager,
}) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  if (allowPlatform) {
    const platformSnapshot = await db.doc(`platform_admins/${request.auth.uid}`).get();
    if (platformSnapshot.exists && platformSnapshot.get('isActive') === true) {
      const platformAdmin = platformSnapshot.data() || {};
      return {
        uid: request.auth.uid,
        role: 'platformAdmin',
        isPlatform: true,
        user: platformAdmin,
        teamId: '',
      };
    }
  }

  const companyUser = await requireActiveCompanyUser(request, companyId);
  if (companyUser.role === 'admin' && allowCompanyAdmin) {
    return {
      uid: request.auth.uid,
      role: 'admin',
      isPlatform: false,
      user: companyUser,
      teamId: optionalString(companyUser.teamId),
    };
  }
  if (companyUser.role === 'manager' && allowManager) {
    return {
      uid: request.auth.uid,
      role: 'manager',
      isPlatform: false,
      user: companyUser,
      teamId: optionalString(companyUser.teamId),
    };
  }

  throw new HttpsError('permission-denied', 'Data health access is not allowed.');
}

function canActorInspectDataHealthRecord({ actor, record }) {
  if (actor.role === 'platformAdmin' || actor.role === 'admin') {
    return true;
  }
  return canActorRepairDataHealthRecord({ actor, record });
}

function canActorRepairDataHealthRecord({ actor, record }) {
  if (actor.role === 'platformAdmin' || actor.role === 'admin') {
    return true;
  }
  if (actor.role !== 'manager') {
    return false;
  }
  const actorTeamId = optionalString(actor.user.teamId || actor.teamId);
  return optionalString(record.managerId) === actor.uid ||
    (actorTeamId && optionalString(record.teamId) === actorTeamId) ||
    optionalString(record.assignedTo) === actor.uid;
}

function canActorAssignDataHealthUser({ actor, assignee }) {
  if (actor.role === 'admin') {
    return true;
  }
  if (actor.role !== 'manager') {
    return false;
  }
  const actorTeamId = optionalString(actor.user.teamId || actor.teamId);
  return optionalString(assignee.managerId) === actor.uid ||
    (actorTeamId && optionalString(assignee.teamId) === actorTeamId);
}

async function writeDataHealthAuditLog({
  companyId,
  actor,
  module,
  recordId,
  record,
  policy,
  update,
  metadata,
}) {
  const auditRef = db.collection(`companies/${companyId}/audit_logs`).doc();
  await auditRef.set({
    id: auditRef.id,
    companyId,
    actorId: actor.uid,
    actorName: optionalString(actor.user.fullName) || optionalString(actor.user.email) || actor.role,
    actorEmail: optionalString(actor.user.email),
    actorRole: actor.role,
    action: 'update',
    module,
    recordId,
    recordTitle: assignedRecordTitle(record, policy, recordId),
    recordSubtitle: 'Data health repair',
    assignedTo: optionalString(update.assignedTo) || optionalString(record.assignedTo),
    teamId: optionalString(update.teamId) || optionalString(record.teamId),
    teamName: optionalString(update.teamName) || optionalString(record.teamName),
    managerId: optionalString(update.managerId) || optionalString(record.managerId),
    managerName: optionalString(update.managerName) || optionalString(record.managerName),
    createdAt: FieldValue.serverTimestamp(),
    metadata,
  });
}

async function writeLeadDataHealthReassignTimeline({
  companyId,
  leadId,
  actor,
  previousAssignedToName,
  nextAssignedToName,
}) {
  const timelineRef = db.collection(`companies/${companyId}/leads/${leadId}/timeline`).doc();
  await timelineRef.set({
    id: timelineRef.id,
    leadId,
    type: 'reassigned',
    title: 'Lead reassigned from data health',
    description: 'assignedTo',
    oldValue: previousAssignedToName,
    newValue: nextAssignedToName,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: actor.uid,
    createdByName: optionalString(actor.user.fullName) || optionalString(actor.user.email) || actor.role,
  });
}

function dataHealthPolicyFor(module) {
  const policy = DATA_HEALTH_MODULE_POLICIES[module];
  if (!policy) {
    throw new HttpsError('invalid-argument', 'Module is not supported for data health repair.');
  }
  return policy;
}

function assignmentSnapshotFromAssignee(assignedTo, assignee) {
  return {
    assignedTo,
    assignedToName: optionalString(assignee.fullName),
    assignedToEmail: optionalString(assignee.email),
    teamId: optionalString(assignee.teamId),
    teamName: optionalString(assignee.teamName),
    managerId: optionalString(assignee.managerId),
    managerName: optionalString(assignee.managerName),
  };
}

function changedSnapshotFields(record, update) {
  const changed = {};
  for (const [field, nextValue] of Object.entries(update)) {
    const previousValue = optionalString(record[field]);
    if (previousValue !== nextValue) {
      changed[field] = {
        from: previousValue,
        to: nextValue,
      };
    }
  }
  return changed;
}

function assignedRecordTitle(record, policy, fallbackId) {
  return optionalString(record[policy.titleField]) ||
    optionalString(record[policy.fallbackTitleField]) ||
    fallbackId;
}

function dataHealthRecordRoute(module, recordId) {
  const cleanId = encodeURIComponent(recordId);
  switch (module) {
    case 'leads':
      return `/leads/${cleanId}`;
    case 'clients':
      return `/clients/${cleanId}`;
    case 'tasks':
      return `/tasks/${cleanId}/edit`;
    case 'deals':
      return `/deals/${cleanId}`;
    case 'properties':
      return `/properties/${cleanId}`;
    default:
      return '/dashboard';
  }
}

function dataHealthManagerCanOpenRecord({ managerId, manager, record, assignee }) {
  const managerTeamId = optionalString(manager && manager.teamId);
  if (optionalString(record.managerId) === managerId ||
      optionalString(assignee && assignee.managerId) === managerId) {
    return true;
  }
  return Boolean(managerTeamId) && (
    optionalString(record.teamId) === managerTeamId ||
    optionalString(assignee && assignee.teamId) === managerTeamId
  );
}

function dataHealthIssueNotificationLabel(issueType) {
  switch (issueType) {
    case 'missingAssignee':
      return 'missing assignee';
    case 'missingSnapshots':
      return 'missing assignment snapshots';
    case 'inactiveAssignee':
      return 'inactive assignee';
    case 'ineligibleAssignee':
      return 'ineligible assignee';
    case 'staleSnapshots':
      return 'stale assignment snapshots';
    default:
      return 'assignment snapshot';
  }
}

function inspectAssignedRecord({
  companyId,
  modulePolicy,
  doc,
  users,
  issues,
  counts,
}) {
  const record = doc.data() || {};
  const assignedTo = optionalString(record.assignedTo);
  if (!assignedTo) {
    if (modulePolicy.onlyWhenAssigned) {
      return;
    }
    return;
  }

  const title = optionalString(record[modulePolicy.titleField]) ||
    optionalString(record[modulePolicy.fallbackTitleField]) ||
    doc.id;
  const assignee = users.get(assignedTo);
  if (!assignee) {
    counts.invalidAssignees += 1;
    addDataHealthIssue({
      issues,
      module: modulePolicy.module,
      recordId: doc.id,
      title,
      assignedTo,
      assignedToName: optionalString(record.assignedToName),
      managerId: optionalString(record.managerId),
      managerName: optionalString(record.managerName),
      issueType: 'missingAssignee',
      suggestedAction: 'Reassign this record to an active eligible user.',
      canBackfill: false,
    });
    return;
  }

  const assignedToName = optionalString(record.assignedToName);
  const teamId = optionalString(record.teamId);
  const managerId = optionalString(record.managerId);
  if (!assignedToName || !teamId || !managerId) {
    counts.missingSnapshots += 1;
    addDataHealthIssue({
      issues,
      module: modulePolicy.module,
      recordId: doc.id,
      title,
      assignedTo,
      assignedToName: assignedToName || optionalString(assignee.fullName),
      managerId: managerId || optionalString(assignee.managerId),
      managerName: optionalString(record.managerName) ||
        optionalString(assignee.managerName),
      issueType: 'missingSnapshots',
      suggestedAction: 'Backfill snapshots from current assignee profile.',
      canBackfill: true,
    });
  }

  if (assignee.isActive !== true) {
    counts.inactiveAssignees += 1;
    addDataHealthIssue({
      issues,
      module: modulePolicy.module,
      recordId: doc.id,
      title,
      assignedTo,
      assignedToName: assignedToName || optionalString(assignee.fullName),
      managerId: managerId || optionalString(assignee.managerId),
      managerName: optionalString(record.managerName) ||
        optionalString(assignee.managerName),
      issueType: 'inactiveAssignee',
      suggestedAction: 'Activate the user or reassign this record.',
      canBackfill: false,
    });
  }

  if (!modulePolicy.allowedRoles.has(assignee.role)) {
    counts.invalidAssignees += 1;
    addDataHealthIssue({
      issues,
      module: modulePolicy.module,
      recordId: doc.id,
      title,
      assignedTo,
      assignedToName: assignedToName || optionalString(assignee.fullName),
      managerId: managerId || optionalString(assignee.managerId),
      managerName: optionalString(record.managerName) ||
        optionalString(assignee.managerName),
      issueType: 'ineligibleAssignee',
      suggestedAction: 'Reassign this record to an eligible operational user.',
      canBackfill: false,
    });
  }

  const stale =
    assignedToName !== optionalString(assignee.fullName) ||
    optionalString(record.assignedToEmail) !== optionalString(assignee.email) ||
    teamId !== optionalString(assignee.teamId) ||
    optionalString(record.teamName) !== optionalString(assignee.teamName) ||
    managerId !== optionalString(assignee.managerId) ||
    optionalString(record.managerName) !== optionalString(assignee.managerName);
  if (stale) {
    counts.staleTeamSnapshots += 1;
    addDataHealthIssue({
      issues,
      module: modulePolicy.module,
      recordId: doc.id,
      title,
      assignedTo,
      assignedToName: assignedToName || optionalString(assignee.fullName),
      managerId: managerId || optionalString(assignee.managerId),
      managerName: optionalString(record.managerName) ||
        optionalString(assignee.managerName),
      issueType: 'staleSnapshots',
      suggestedAction: 'Backfill snapshots from current assignee profile.',
      canBackfill: true,
    });
  }
}

function addDataHealthIssue({
  issues,
  module,
  recordId,
  title,
  assignedTo,
  assignedToName,
  managerId,
  managerName,
  issueType,
  suggestedAction,
  canBackfill,
}) {
  issues.push({
    module,
    recordId,
    title,
    assignedTo,
    assignedToName,
    managerId: optionalString(managerId),
    managerName: optionalString(managerName),
    issueType,
    suggestedAction,
    canBackfill,
  });
}

function requiredString(value, field) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

function optionalString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function requiredPassword(value, field) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value;
}

function optionalPassword(value) {
  return typeof value === 'string' ? value : '';
}

function requiredBoolean(value, field) {
  if (typeof value !== 'boolean') {
    throw new HttpsError('invalid-argument', `${field} must be true or false.`);
  }
  return value;
}

function requiredObject(value, field) {
  if (
    value === null ||
    typeof value !== 'object' ||
    Array.isArray(value)
  ) {
    throw new HttpsError('invalid-argument', `${field} must be an object.`);
  }
  return value;
}

function validatePassword(password) {
  if (
    typeof password !== 'string' ||
    password.trim() === '' ||
    password.length < 8 ||
    !/[a-z]/.test(password) ||
    !/[A-Z]/.test(password) ||
    !/\d/.test(password)
  ) {
    throw new HttpsError(
      'invalid-argument',
      'Password is too weak.',
    );
  }
}

function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

function normalizeLeadEmail(email) {
  return optionalString(email).toLowerCase();
}

function normalizeLeadPhone(phone) {
  return optionalString(phone).replace(/[()\-\s]/g, '');
}

function validateEmail(email) {
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new HttpsError('invalid-argument', 'Email is invalid.');
  }
}


function sanitizeProfileName(value) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', 'Full name is required.');
  }
  const fullName = value.trim();
  if (fullName.length < 2 || fullName.length > 120 || /[<>]/.test(fullName)) {
    throw new HttpsError('invalid-argument', 'Full name is invalid.');
  }
  return fullName;
}

function sanitizeProfileUrl(value) {
  if (typeof value !== 'string') {
    return '';
  }
  const url = value.trim();
  if (url.length > 2048 || /[<>]/.test(url)) {
    throw new HttpsError('invalid-argument', 'Profile image URL is invalid.');
  }
  return url;
}

function validateOwnedProfileStoragePath({ companyId, uid, path }) {
  const cleanPath = optionalString(path);
  if (!cleanPath) {
    return;
  }
  const expectedPrefix = companyId
    ? `companies/${companyId}/users/${uid}/profile/`
    : `platform_admins/${uid}/profile/`;
  if (!cleanPath.startsWith(expectedPrefix) || cleanPath.includes('..')) {
    throw new HttpsError('permission-denied', 'Profile image path is not allowed.');
  }
}

async function deleteOwnedProfileStoragePath({ companyId, uid, path }) {
  const cleanPath = optionalString(path);
  if (!cleanPath) {
    return;
  }
  validateOwnedProfileStoragePath({ companyId, uid, path: cleanPath });
  try {
    await admin.storage().bucket().file(cleanPath).delete({ ignoreNotFound: true });
  } catch (error) {
    console.warn('Unable to delete old profile image.', {
      companyId,
      uid,
      path: cleanPath,
      error: error && error.message ? error.message : String(error),
    });
  }
}

function validateCompanyId(companyId) {
  if (!COMPANY_ID_PATTERN.test(companyId)) {
    throw new HttpsError('invalid-argument', 'Company ID is invalid.');
  }
}

function validateLocale(locale) {
  if (!LOCALES.has(locale)) {
    throw new HttpsError('invalid-argument', 'Locale is invalid.');
  }
}

function validateTimezone(timezone) {
  if (typeof timezone !== 'string' || timezone.trim() === '') {
    throw new HttpsError('invalid-argument', 'Timezone is required.');
  }
  if (timezone.length > 80 || /[<>]/.test(timezone)) {
    throw new HttpsError('invalid-argument', 'Timezone is invalid.');
  }
}

function validateCompanyStatus(status) {
  if (!COMPANY_STATUSES.has(status)) {
    throw new HttpsError('invalid-argument', 'Company status is invalid.');
  }
}

function validateCompanySettings(settings) {
  const allowed = new Set(['locale', 'timezone']);
  const validated = {};
  for (const [key, value] of Object.entries(settings)) {
    if (!allowed.has(key)) {
      throw new HttpsError('invalid-argument', `${key} is not editable.`);
    }
    if (key === 'locale') {
      const locale = requiredString(value, 'locale');
      validateLocale(locale);
      validated.locale = locale;
    }
    if (key === 'timezone') {
      const timezone = requiredString(value, 'timezone');
      validateTimezone(timezone);
      validated.timezone = timezone;
    }
  }
  return validated;
}

function validateCompanyLimits(limits) {
  const allowed = new Set(['users', 'storageMb']);
  const validated = {};
  for (const [key, value] of Object.entries(limits)) {
    if (!allowed.has(key)) {
      throw new HttpsError('invalid-argument', `${key} is not editable.`);
    }
    validated[key] = positiveInteger(value, key);
  }
  return validated;
}

function validateCompanyFeatures(features) {
  const validated = {};
  for (const [key, value] of Object.entries(features)) {
    if (!FEATURE_KEYS.has(key)) {
      throw new HttpsError('invalid-argument', `${key} is not editable.`);
    }
    if (typeof value !== 'boolean') {
      throw new HttpsError(
        'invalid-argument',
        `${key} must be true or false.`,
      );
    }
    validated[key] = value;
  }
  return validated;
}

function companyFeatureEnabled(company, feature) {
  const features = company && typeof company.features === 'object' ? company.features : {};
  return features[feature] !== false;
}

async function requireCompanyExportsEnabled(companyId) {
  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data() || {};
  if (!companyFeatureEnabled(company, 'exports')) {
    throw new HttpsError(
      'failed-precondition',
      'Exports are disabled for this company.',
    );
  }
  return company;
}

function enforceUserManagementFeature(company, isPlatformActor) {
  if (!isPlatformActor && !companyFeatureEnabled(company, 'userManagement')) {
    throw new HttpsError(
      'failed-precondition',
      'User Management is disabled for this company.',
    );
  }
}

function assertCompanyAdminCanManageTarget({ actorUid, targetUid, targetUser, nextActive }) {
  const role = optionalString(targetUser.role);
  if (role === 'admin') {
    throw new HttpsError(
      'permission-denied',
      'Only platform owner support can manage company admins.',
    );
  }
  if (actorUid === targetUid && nextActive === false) {
    throw new HttpsError('permission-denied', 'You cannot deactivate your own user account.');
  }
}

function positiveInteger(value, field) {
  if (!Number.isInteger(value) || value <= 0 || value > 1000000) {
    throw new HttpsError(
      'invalid-argument',
      `${field} must be a positive whole number.`,
    );
  }
  return value;
}

function optionalPositiveInteger(value, field) {
  if (value === null || typeof value === 'undefined' || value === '') {
    return 0;
  }
  return positiveInteger(value, field);
}

function trialDatesFromDays(trialDays) {
  return trialDatesFromDuration(trialDays, 'days');
}

function trialDatesFromDuration(value, unit) {
  const durationValue = Number.isInteger(value) ? value : Number.parseInt(value, 10);
  const durationUnit = normalizeTrialUnit(unit);
  if (!Number.isInteger(durationValue) || durationValue <= 0) {
    return {
      status: 'active',
      trialStartedAt: null,
      trialEndsAt: null,
      trialDurationValue: 0,
      trialDurationUnit: durationUnit,
      trialDays: 0,
    };
  }
  const now = new Date();
  return {
    status: 'trial',
    trialStartedAt: now,
    trialEndsAt: new Date(now.getTime() + durationValue * trialUnitMs(durationUnit)),
    trialDurationValue: durationValue,
    trialDurationUnit: durationUnit,
    trialDays: trialApproxDays(durationValue, durationUnit),
  };
}

function normalizeTrialUnit(unit) {
  const clean = optionalString(unit).toLowerCase();
  if (clean === 'minutes' || clean === 'hours' || clean === 'days') {
    return clean;
  }
  return 'days';
}

function trialUnitMs(unit) {
  if (unit === 'minutes') return 60 * 1000;
  if (unit === 'hours') return 60 * 60 * 1000;
  return 24 * 60 * 60 * 1000;
}

function trialApproxDays(value, unit) {
  if (!Number.isInteger(value) || value <= 0) return 0;
  if (unit === 'minutes') return Math.max(1, Math.ceil(value / (60 * 24)));
  if (unit === 'hours') return Math.max(1, Math.ceil(value / 24));
  return value;
}

function trialPayload(data) {
  const legacyDays = optionalPositiveInteger(data.trialDays, 'trialDays');
  const value = optionalPositiveInteger(data.trialDurationValue, 'trialDurationValue') || legacyDays;
  const unit = Object.prototype.hasOwnProperty.call(data, 'trialDurationUnit')
    ? normalizeTrialUnit(data.trialDurationUnit)
    : 'days';
  return trialDatesFromDuration(value, unit);
}

function normalizePaymentStatus(value) {
  const status = optionalString(value);
  if (!PAYMENT_STATUSES.has(status)) {
    throw new HttpsError('invalid-argument', 'Payment status is invalid.');
  }
  return status;
}

function normalizePaymentCycle(value) {
  const cycle = optionalString(value) || 'monthly';
  if (!PAYMENT_CYCLES.has(cycle)) {
    throw new HttpsError('invalid-argument', 'Payment cycle is invalid.');
  }
  return cycle;
}

function normalizeCurrency(value, allowEmpty = false) {
  const clean = optionalString(value).toUpperCase();
  if (!clean && allowEmpty) {
    return '';
  }
  if (!/^[A-Z]{3}$/.test(clean)) {
    throw new HttpsError('invalid-argument', 'Payment currency is invalid.');
  }
  return clean;
}

function paymentAmountValue(value, allowEmpty = false) {
  if ((value === null || typeof value === 'undefined' || value === '') && allowEmpty) {
    return 0;
  }
  const amount = typeof value === 'number' ? value : Number.parseFloat(optionalString(value));
  if (!Number.isFinite(amount) || amount < 0 || amount > 1000000000) {
    throw new HttpsError('invalid-argument', 'Payment amount is invalid.');
  }
  return Math.round(amount * 100) / 100;
}

function paymentStatusForCompany(company) {
  const explicit = optionalString(company && company.paymentStatus);
  if (PAYMENT_STATUSES.has(explicit)) {
    return explicit;
  }
  const status = optionalString(company && company.status);
  if (status === 'trial') return 'trial';
  if (status === 'trialExpired') return 'trialExpired';
  if (status === 'inactive' || (company && company.isActive === false)) return 'inactive';
  return 'paid';
}

function paymentHistoryActionForStatus(status, previousStatus, notes) {
  if (status === 'suspended') return 'suspended';
  if (status === 'paid' && previousStatus === 'suspended') return 'reactivated';
  if (status === 'paid') return 'reactivated';
  if (notes && status === previousStatus) return 'noteAdded';
  return 'statusChanged';
}

function platformPaymentNotificationType(status, action) {
  if (action === 'reactivated') return 'paymentReactivated';
  if (status === 'suspended') return 'paymentSuspended';
  if (status === 'gracePeriod') return 'paymentGraceEnding';
  if (status === 'overdue') return 'paymentOverdue';
  if (status === 'dueSoon') return 'paymentDueSoon';
  if (status === 'paid') return 'paymentMarkedPaid';
  return 'companySettingsChanged';
}

function platformPaymentNotificationTitle(status, action) {
  if (action === 'reactivated') return 'Company reactivated';
  if (status === 'suspended') return 'Company suspended';
  if (status === 'gracePeriod') return 'Company moved to grace period';
  if (status === 'overdue') return 'Payment overdue';
  if (status === 'dueSoon') return 'Payment due soon';
  if (status === 'paid') return 'Payment marked paid';
  return 'Payment status changed';
}

function addPaymentHistoryToBatch(batch, {
  companyId,
  companyName,
  action,
  amount,
  currency,
  paymentDate,
  nextPaymentDueAt,
  previousStatus,
  newStatus,
  notes,
  actor = {},
  now,
}) {
  const cleanAction = PAYMENT_HISTORY_ACTIONS.has(action) ? action : 'statusChanged';
  const historyRef = db.collection(`companies/${companyId}/payment_history`).doc();
  batch.set(historyRef, {
    id: historyRef.id,
    companyId,
    companyName: sanitizePlainString(companyName, 240),
    action: cleanAction,
    amount: typeof amount === 'number' ? amount : 0,
    currency: sanitizePlainString(currency, 12),
    paymentDate: paymentDate || null,
    nextPaymentDueAt: nextPaymentDueAt || null,
    previousStatus: sanitizePlainString(previousStatus, 40),
    newStatus: sanitizePlainString(newStatus, 40),
    notes: sanitizePlainString(notes, 500),
    actorUid: sanitizePlainString(actor.actorId, 160),
    actorName: sanitizePlainString(actor.actorName, 160),
    actorEmail: sanitizePlainString(actor.actorEmail, 180),
    createdAt: now || FieldValue.serverTimestamp(),
  });
}

async function createPlatformPaymentNotification({
  type,
  title,
  message,
  companyId,
  companyName,
  actor = {},
  metadata = {},
}) {
  const locale = await platformNotificationLocale();
  const text = platformPaymentNotificationText(locale, {
    type,
    title,
    message,
    companyName,
  });
  return createPlatformNotificationSafely('payment_follow_up', {
    type,
    title: text.title,
    message: text.message,
    severity: type === 'paymentSuspended' || type === 'paymentOverdue' ? 'urgent' : 'warning',
    source: 'company',
    route: '/platform',
    actorId: actor.actorId || '',
    actorName: actor.actorName || '',
    actorEmail: actor.actorEmail || '',
    companyId,
    companyName,
    metadata,
  });
}

function platformPaymentNotificationText(locale, {
  type,
  title,
  message,
  companyName,
}) {
  const lang = normalizeNotificationLocale(locale);
  if (lang !== 'ar') {
    return { title, message };
  }
  const name = optionalString(companyName);
  const prefix = name ? `${name}: ` : '';
  if (type === 'paymentDueSoon') {
    return {
      title: 'دفعة مستحقة قريبًا',
      message: `${prefix}توجد دفعة مستحقة قريبًا.`,
    };
  }
  if (type === 'paymentOverdue') {
    return {
      title: 'الدفع متأخر',
      message: `${prefix}توجد دفعة متأخرة تحتاج إلى متابعة.`,
    };
  }
  if (type === 'paymentGraceEnding') {
    const movedToGrace = optionalString(title).toLowerCase().includes('moved');
    return {
      title: movedToGrace ? 'تم نقل الشركة إلى فترة سماح' : 'فترة السماح أوشكت على الانتهاء',
      message: movedToGrace
        ? `${prefix}تم نقل الشركة إلى فترة سماح للدفع.`
        : `${prefix}فترة السماح للدفع أوشكت على الانتهاء.`,
    };
  }
  if (type === 'paymentSuspended') {
    return {
      title: 'تم إيقاف الشركة',
      message: `${prefix}تم إيقاف الوصول بسبب حالة الدفع.`,
    };
  }
  if (type === 'paymentReactivated') {
    return {
      title: 'تمت إعادة تفعيل الشركة',
      message: `${prefix}تمت إعادة تفعيل الشركة بعد تحديث حالة الدفع.`,
    };
  }
  if (type === 'paymentMarkedPaid') {
    return {
      title: 'تم تسجيل الدفع',
      message: `${prefix}تم تسجيل الشركة كمدفوعة.`,
    };
  }
  return {
    title: 'تم تحديث حالة الدفع',
    message: `${prefix}تم تحديث حالة دفع الشركة.`,
  };
}

function paymentCompanyMessage(locale, paymentStatus) {
  const lang = normalizeNotificationLocale(locale);
  if (lang === 'ar') {
    if (paymentStatus === 'suspended') {
      return {
        title: 'تم إيقاف الشركة مؤقتًا',
        body: 'تم إيقاف الوصول مؤقتًا بسبب حالة الدفع. يرجى التواصل مع الدعم أو مالك المنصة لإعادة التفعيل.',
      };
    }
    if (paymentStatus === 'gracePeriod') {
      return {
        title: 'الشركة في فترة سماح',
        body: 'الشركة تعمل خلال فترة سماح للدفع. يرجى التواصل مع الدعم أو مالك المنصة لتجنب إيقاف الوصول.',
      };
    }
    if (paymentStatus === 'overdue') {
      return {
        title: 'الدفع متأخر',
        body: 'يوجد مبلغ مستحق على الشركة. يرجى التواصل مع الدعم أو مالك المنصة لتحديث حالة الدفع.',
      };
    }
    return {
      title: 'تم تحديث حالة الدفع',
      body: 'تم تحديث حالة دفع الشركة.',
    };
  }
  if (paymentStatus === 'suspended') {
    return {
      title: 'Company suspended',
      body: 'Access is temporarily suspended because of payment status. Please contact support or the platform owner to reactivate the company.',
    };
  }
  if (paymentStatus === 'gracePeriod') {
    return {
      title: 'Company is in grace period',
      body: 'The company is working during a payment grace period. Please contact support or the platform owner to avoid access suspension.',
    };
  }
  if (paymentStatus === 'overdue') {
    return {
      title: 'Payment overdue',
      body: 'A company payment is overdue. Please contact support or the platform owner to update the payment status.',
    };
  }
  return {
    title: 'Payment status updated',
    body: 'The company payment status was updated.',
  };
}

async function notifyCompanyAdminsForPaymentState({
  companyId,
  company,
  paymentStatus,
  dedupeSuffix,
}) {
  if (!['overdue', 'gracePeriod', 'suspended'].includes(paymentStatus)) {
    return;
  }
  const admins = await listCompanyAdminUsers(companyId);
  for (const admin of admins) {
    const locale = notificationLocaleForCompanyUser(company, admin);
    const text = paymentCompanyMessage(locale, paymentStatus);
    await createCompanyNotification({
      companyId,
      recipientUid: admin.uid,
      recipientRole: 'admin',
      type: 'systemInfo',
      module: 'company',
      recordId: companyId,
      recordTitle: text.title,
      recordSubtitle: text.body,
      route: '/dashboard',
      actorUid: 'system:payment',
      actorName: 'Masar CRM',
      priority: paymentStatus === 'suspended' ? 'urgent' : 'high',
      metadata: { paymentStatus },
      fallbackTitle: text.title,
      fallbackBody: text.body,
      dedupeKey: `payment_${companyId}_${admin.uid}_${dedupeSuffix}`,
    });
  }
}

function serializeExportValue(value) {
  if (value === null || typeof value === 'undefined') {
    return null;
  }
  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  if (Array.isArray(value)) {
    return value.map(serializeExportValue);
  }
  if (typeof value === 'object') {
    const result = {};
    for (const [key, child] of Object.entries(value)) {
      if (key === 'phoneNormalized' || key === 'emailNormalized') {
        continue;
      }
      result[key] = serializeExportValue(child);
    }
    return result;
  }
  return value;
}


async function enforceUserLimit(companyId, company) {
  const limits = company.limits || {};
  const limit = limits.users;
  if (!Number.isInteger(limit) || limit <= 0) {
    return;
  }

  const usersSnapshot = await db
    .collection(`companies/${companyId}/users`)
    .count()
    .get();
  const userCount = usersSnapshot.data().count || 0;
  if (userCount >= limit) {
    throw new HttpsError('failed-precondition', 'Company user limit reached.');
  }
}

async function loadCompanyUserAndAuthUser({ companyId, uid }) {
  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }

  const companyUserSnapshot = await db
    .doc(`companies/${companyId}/users/${uid}`)
    .get();
  if (!companyUserSnapshot.exists) {
    throw new HttpsError('not-found', 'Company user was not found.');
  }

  let userRecord;
  try {
    userRecord = await auth.getUser(uid);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      throw new HttpsError('not-found', 'Firebase Auth user was not found.');
    }
    throw error;
  }

  return { companyUserSnapshot, userRecord };
}

async function listCompanyUserIds(companyId) {
  const snapshot = await db.collection(`companies/${companyId}/users`).select().get();
  return snapshot.docs
    .map((doc) => optionalString(doc.id))
    .filter((uid) => uid.length > 0);
}

async function listCompanyAdminUsers(companyId) {
  const snapshot = await db
    .collection(`companies/${companyId}/users`)
    .where('role', '==', 'admin')
    .limit(50)
    .get();
  return snapshot.docs
    .map((doc) => ({
      uid: doc.id,
      ...(doc.data() || {}),
    }))
    .filter((user) => user.isActive === true);
}

function trialNotificationMilestone({ start, end, now }) {
  if (!start || !end) {
    return 0;
  }
  const totalMs = end.getTime() - start.getTime();
  if (totalMs <= 0) {
    return 3;
  }
  const elapsedMs = now.getTime() - start.getTime();
  if (elapsedMs < 0 || now.getTime() >= end.getTime()) {
    return now.getTime() >= end.getTime() ? 3 : 0;
  }
  const finalWarningAt = Math.max(1, Math.floor(totalMs * 0.90));
  if (elapsedMs >= finalWarningAt) return 3;
  if (elapsedMs >= totalMs * 2 / 3) return 2;
  if (elapsedMs >= totalMs / 3) return 1;
  return 0;
}

function normalizeNotificationLocale(value) {
  const clean = optionalString(value).toLowerCase();
  if (clean.startsWith('ar')) return 'ar';
  return 'en';
}

function notificationLocaleForCompany(company) {
  const settings = company && typeof company.settings === 'object' ? company.settings : {};
  return normalizeNotificationLocale(
    optionalString(settings.locale) ||
      optionalString(company && company.locale) ||
      optionalString(company && company.lastLoginLocale),
  );
}

function notificationLocaleForCompanyUser(company, user) {
  return normalizeNotificationLocale(
    optionalString(user && user.locale) ||
      optionalString(user && user.lastLoginLocale) ||
      notificationLocaleForCompany(company),
  );
}

async function platformNotificationLocale() {
  try {
    const snapshot = await db
      .collection('platform_admins')
      .where('isActive', '==', true)
      .limit(20)
      .get();
    for (const doc of snapshot.docs) {
      const adminData = doc.data() || {};
      const locale = optionalString(adminData.locale) || optionalString(adminData.lastLoginLocale);
      if (normalizeNotificationLocale(locale) === 'ar') {
        return 'ar';
      }
    }
  } catch (_) {
    return 'en';
  }
  return 'en';
}

function trialRemainingText(end, now, locale) {
  if (!end || !now) {
    return locale === 'ar' ? 'وقت قصير' : 'a short time';
  }
  const remainingMs = Math.max(0, end.getTime() - now.getTime());
  const minutes = Math.max(1, Math.ceil(remainingMs / (60 * 1000)));
  if (minutes < 60) {
    return locale === 'ar'
      ? `${minutes} ${minutes === 1 ? 'دقيقة' : 'دقائق'}`
      : `${minutes} ${minutes === 1 ? 'minute' : 'minutes'}`;
  }
  const hours = Math.ceil(minutes / 60);
  if (hours < 24) {
    return locale === 'ar'
      ? `${hours} ${hours === 1 ? 'ساعة' : 'ساعات'}`
      : `${hours} ${hours === 1 ? 'hour' : 'hours'}`;
  }
  const days = Math.ceil(hours / 24);
  return locale === 'ar'
    ? `${days} ${days === 1 ? 'يوم' : 'أيام'}`
    : `${days} ${days === 1 ? 'day' : 'days'}`;
}

function trialNotificationText({
  locale,
  milestone,
  remaining = '',
  companyName = '',
  expired = false,
}) {
  const lang = normalizeNotificationLocale(locale);
  const cleanCompanyName = optionalString(companyName);
  if (expired) {
    if (lang === 'ar') {
      const body = 'انتهت فترة التجربة. يرجى التواصل مع الدعم أو الاشتراك لإعادة تفعيل الشركة.';
      return {
        title: 'انتهت فترة التجربة',
        body,
        platformBody: cleanCompanyName
          ? `${cleanCompanyName}: انتهت فترة التجربة.`
          : body,
      };
    }
    const body = 'The trial period has ended. Please contact support or subscribe to reactivate the company.';
    return {
      title: 'Trial ended',
      body,
      platformBody: cleanCompanyName
        ? `${cleanCompanyName} trial ended.`
        : body,
    };
  }

  const isFinal = milestone === 3;
  if (lang === 'ar') {
    const title = isFinal ? 'فترة التجربة أوشكت على الانتهاء' : 'تنبيه فترة التجربة';
    const body = `تبقى تقريبًا ${remaining || 'وقت قصير'} على انتهاء فترة التجربة. يرجى التواصل مع الدعم أو الاشتراك للاستمرار في استخدام مسار.`;
    return {
      title,
      body,
      platformBody: cleanCompanyName ? `${cleanCompanyName}: ${body}` : body,
    };
  }

  const title = isFinal ? 'Trial is about to end' : 'Trial checkpoint reached';
  const body = `About ${remaining || 'a short time'} remains before the trial ends. Please contact support or subscribe to continue using Masar.`;
  return {
    title,
    body,
    platformBody: cleanCompanyName ? `${cleanCompanyName}: ${body}` : body,
  };
}

function trialLocalizedNotificationMetadata({
  milestone,
  trialEndsAt = '',
  trialStartedAt = '',
  remainingEn = '',
  remainingAr = '',
  companyName = '',
  expired = false,
  extra = {},
}) {
  const english = trialNotificationText({
    locale: 'en',
    milestone,
    remaining: remainingEn,
    companyName,
    expired,
  });
  const arabic = trialNotificationText({
    locale: 'ar',
    milestone,
    remaining: remainingAr,
    companyName,
    expired,
  });
  return {
    ...extra,
    milestone,
    trialEndsAt,
    trialStartedAt,
    titleEn: english.title,
    bodyEn: english.body,
    messageEn: english.platformBody,
    titleAr: arabic.title,
    bodyAr: arabic.body,
    messageAr: arabic.platformBody,
  };
}

async function notifyTrialMilestone({ companyId, company, milestone, trialEndsAt, now }) {
  if (!milestone || milestone < 1 || milestone > 3) {
    return;
  }
  const trialStartedAt = dateFromCallableValue(company.trialStartedAt);
  const startKey = trialStartedAt ? trialStartedAt.getTime() : 'unknown';
  const companyName = companyNotificationName(companyId, company);
  const endIso = trialEndsAt ? trialEndsAt.toISOString() : '';
  const platformLocale = await platformNotificationLocale();
  const platformText = trialNotificationText({
    locale: platformLocale,
    milestone,
    remaining: trialRemainingText(trialEndsAt, now, platformLocale),
    companyName,
  });
  await createPlatformNotificationSafely(`trial_${milestone}_platform_${companyId}`, {
    id: `trial_milestone_${companyId}_${startKey}_${milestone}`,
    type: 'trialEndingSoon',
    title: platformText.title,
    message: platformText.platformBody,
    severity: milestone === 3 ? 'urgent' : 'warning',
    source: 'company',
    route: '/platform',
    companyId,
    companyName,
    metadata: trialLocalizedNotificationMetadata({
      milestone,
      trialEndsAt: endIso,
      trialStartedAt: trialStartedAt ? trialStartedAt.toISOString() : '',
      remainingEn: trialRemainingText(trialEndsAt, now, 'en'),
      remainingAr: trialRemainingText(trialEndsAt, now, 'ar'),
      companyName,
    }),
  });

  const admins = await listCompanyAdminUsers(companyId);
  for (const admin of admins) {
    const locale = notificationLocaleForCompanyUser(company, admin);
    const text = trialNotificationText({
      locale,
      milestone,
      remaining: trialRemainingText(trialEndsAt, now, locale),
    });
    await createCompanyNotification({
      companyId,
      recipientUid: admin.uid,
      recipientRole: 'admin',
      type: 'systemInfo',
      module: 'company',
      recordId: companyId,
      recordTitle: text.title,
      recordSubtitle: text.body,
      route: '/dashboard',
      actorUid: 'system:trial',
      actorName: 'Masar CRM',
      priority: milestone === 3 ? 'urgent' : 'high',
      metadata: trialLocalizedNotificationMetadata({
        milestone,
        trialEndsAt: endIso,
        trialStartedAt: trialStartedAt ? trialStartedAt.toISOString() : '',
        remainingEn: trialRemainingText(trialEndsAt, now, 'en'),
        remainingAr: trialRemainingText(trialEndsAt, now, 'ar'),
        companyName,
      }),
      fallbackTitle: text.title,
      fallbackBody: text.body,
      dedupeKey: `trial_milestone_${companyId}_${startKey}_${milestone}_admin_${admin.uid}`,
    });
  }
}

async function revokeRefreshTokensForUids(uids) {
  const uniqueUids = [...new Set((uids || []).map(optionalString).filter(Boolean))];
  for (const uid of uniqueUids) {
    await revokeRefreshTokensForUid(uid);
  }
}

async function revokeRefreshTokensForUid(uid) {
  const cleanUid = optionalString(uid);
  if (!cleanUid) {
    return;
  }
  try {
    await auth.revokeRefreshTokens(cleanUid);
  } catch (error) {
    if (error && error.code === 'auth/user-not-found') {
      return;
    }
    throw error;
  }
}

async function syncGlobalUserActiveStatuses(uids) {
  const uniqueUids = [...new Set((uids || []).map(optionalString).filter(Boolean))];
  for (const uid of uniqueUids) {
    await syncGlobalUserActiveStatus(uid);
  }
}

async function syncGlobalUserActiveStatus(uid) {
  const cleanUid = optionalString(uid);
  if (!cleanUid) {
    return;
  }
  const isActive = await userHasActiveAccess(cleanUid);
  await db.doc(`users/${cleanUid}`).set({
    isActive,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function userHasActiveAccess(uid) {
  if (await isActivePlatformAdminUid(uid)) {
    return true;
  }

  const membershipsSnapshot = await db.collection(`users/${uid}/memberships`).get();
  for (const membershipDocument of membershipsSnapshot.docs) {
    const membership = membershipDocument.data() || {};
    const companyId = optionalString(membership.companyId) || membershipDocument.id;
    if (
      !companyId ||
      membership.isActive !== true ||
      optionalString(membership.status) === 'inactive'
    ) {
      continue;
    }

    const companySnapshot = await db.doc(`companies/${companyId}`).get();
    if (!companySnapshot.exists) {
      continue;
    }
    const company = companySnapshot.data() || {};
    if (company.isActive === true && optionalString(company.status) !== 'inactive') {
      return true;
    }
  }

  return false;
}

function requestIpAddress(request) {
  const headers = (request.rawRequest && request.rawRequest.headers) || {};
  const forwardedFor = headers['x-forwarded-for'];
  if (typeof forwardedFor === 'string' && forwardedFor.trim()) {
    return forwardedFor.split(',')[0].trim();
  }
  const realIp = headers['x-real-ip'];
  if (typeof realIp === 'string') {
    return realIp.trim();
  }
  const firebaseForwarded = headers['fastly-client-ip'];
  if (typeof firebaseForwarded === 'string') {
    return firebaseForwarded.trim();
  }
  return '';
}

function sanitizeShortString(value, maxLength) {
  if (typeof value !== 'string') {
    return '';
  }
  return value.trim().slice(0, maxLength);
}

function authProviderFromToken(token) {
  const provider = token && token.firebase && token.firebase.sign_in_provider;
  return typeof provider === 'string' ? provider : '';
}

function loginActivityPayload({
  uid,
  companyId,
  email,
  role,
  fullName,
  ipAddress,
  authProvider,
  clientInfo,
}) {
  const payload = {
    uid,
    email,
    role,
    fullName,
    loginAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
    ipAddress,
    userAgent: clientInfo.userAgent,
    platform: clientInfo.platform,
    browser: clientInfo.browser,
    deviceType: clientInfo.deviceType,
    locale: clientInfo.locale,
    timezone: clientInfo.timezone,
    authProvider,
    appVersion: clientInfo.appVersion,
  };
  if (companyId) {
    payload.companyId = companyId;
  }
  return payload;
}

function lastLoginSummary(event) {
  return {
    lastLoginAt: FieldValue.serverTimestamp(),
    lastLoginIp: event.ipAddress || '',
    lastLoginUserAgent: event.userAgent || '',
    lastLoginPlatform: event.platform || '',
    lastLoginBrowser: event.browser || '',
    lastLoginDeviceType: event.deviceType || '',
    lastLoginLocale: event.locale || '',
    lastLoginTimezone: event.timezone || '',
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function updateMembershipCompanyNames(companyId, companyName) {
  const usersSnapshot = await db.collection(`companies/${companyId}/users`).get();
  let batch = db.batch();
  let operationCount = 0;

  for (const doc of usersSnapshot.docs) {
    batch.set(
      db.doc(`users/${doc.id}/memberships/${companyId}`),
      {
        companyName,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    operationCount += 1;

    if (operationCount === 450) {
      await batch.commit();
      batch = db.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    await batch.commit();
  }
}

async function refreshTeamMemberCount({ companyId, teamId, actorUid }) {
  const cleanTeamId = optionalString(teamId);
  if (!cleanTeamId) {
    return;
  }

  const teamRef = db.doc(`companies/${companyId}/teams/${cleanTeamId}`);
  const teamSnapshot = await teamRef.get();
  if (!teamSnapshot.exists) {
    return;
  }

  const countSnapshot = await db
    .collection(`companies/${companyId}/users`)
    .where('teamId', '==', cleanTeamId)
    .count()
    .get();
  await teamRef.update({
    memberCount: countSnapshot.data().count || 0,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  });
}


async function backfillAssignedRecordsForUser({ companyId, uid, assignee, actorUid }) {
  const update = {
    ...assignmentSnapshotFromAssignee(uid, assignee),
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  };
  const modules = ['leads', 'clients', 'tasks', 'deals', 'appointments', 'properties'];
  const result = { total: 0, byModule: {} };

  for (const module of modules) {
    let lastDoc = null;
    let repairedForModule = 0;
    do {
      let query = db.collection(`companies/${companyId}/${module}`)
        .where('assignedTo', '==', uid)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(400);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }
      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }
      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.set(doc.ref, update, { merge: true });
        repairedForModule += 1;
      });
      await batch.commit();
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < 400) {
        break;
      }
    } while (lastDoc);

    if (repairedForModule > 0) {
      result.byModule[module] = repairedForModule;
      result.total += repairedForModule;
    }
  }

  console.info('assigned_record_snapshot_backfill_completed', {
    companyId,
    uid,
    repairedRecords: result.total,
    byModule: result.byModule,
  });

  return result;
}

function isPropertyImagePath(filePath) {
  return /^companies\/[^/]+\/properties\/[^/]+\/images\/[^/]+$/.test(filePath);
}

function detectImageContentType(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 4) {
    return '';
  }

  if (
    buffer.length >= 3 &&
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff
  ) {
    return 'image/jpeg';
  }

  if (
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return 'image/png';
  }

  if (
    buffer.length >= 12 &&
    buffer.toString('ascii', 0, 4) === 'RIFF' &&
    buffer.toString('ascii', 8, 12) === 'WEBP'
  ) {
    return 'image/webp';
  }

  if (
    buffer.length >= 6 &&
    (buffer.toString('ascii', 0, 6) === 'GIF87a' ||
      buffer.toString('ascii', 0, 6) === 'GIF89a')
  ) {
    return 'image/gif';
  }

  return '';
}

async function deleteSpoofedImageAndLog({
  bucketName,
  filePath,
  declaredContentType,
  detectedContentType,
  reason,
}) {
  await admin.storage().bucket(bucketName).file(filePath).delete({ ignoreNotFound: true });

  await db.collection('platform_security_alerts').add({
    type: 'storageMimeSpoofing',
    severity: 'high',
    bucket: bucketName,
    path: filePath,
    declaredContentType,
    detectedContentType,
    reason,
    createdAt: FieldValue.serverTimestamp(),
  });

  console.warn('Deleted spoofed image upload.', {
    bucketName,
    filePath,
    declaredContentType,
    detectedContentType,
    reason,
  });
}



function buildLeadPayload({
  companyId,
  leadId,
  leadInput,
  assignedTo,
  assignee,
  actorUid,
  now,
  existingLead,
  isCreate,
}) {
  const source = enumValue(leadInput.source, LEAD_SOURCES, 'source');
  const status = enumValue(leadInput.status, LEAD_STATUSES, 'status');
  const priority = enumValue(leadInput.priority, LEAD_PRIORITIES, 'priority');
  const isClosedLeadStatus = status === 'won' || status === 'lost';

  const phone = sanitizePlainString(requiredString(leadInput.phone, 'phone'), 80);
  const email = sanitizePlainString(optionalString(leadInput.email), 160);
  const budgetMin = numberValue(leadInput.budgetMin, 'budgetMin');
  const budgetMax = numberValue(leadInput.budgetMax, 'budgetMax');
  if (budgetMin < 0 || budgetMax < 0) {
    throw new HttpsError('invalid-argument', 'Budget cannot be negative.');
  }
  if (budgetMin > 0 && budgetMax > 0 && budgetMax < budgetMin) {
    throw new HttpsError('invalid-argument', 'Maximum budget cannot be less than minimum budget.');
  }

  const payload = {
    id: leadId,
    companyId,
    fullName: sanitizePlainString(requiredString(leadInput.fullName, 'fullName'), 160),
    phone,
    phoneNormalized: normalizeLeadPhone(phone),
    email,
    emailNormalized: normalizeLeadEmail(email),
    source,
    sourceDetails: sanitizePlainString(optionalString(leadInput.sourceDetails), 200),
    status,
    priority,
    budgetMin,
    budgetMax,
    preferredLocation: sanitizePlainString(optionalString(leadInput.preferredLocation), 200),
    preferredPropertyType: sanitizePlainString(optionalString(leadInput.preferredPropertyType), 120),
    assignedTo,
    assignedToName: assignee ? optionalString(assignee.fullName) : '',
    assignedToEmail: assignee ? optionalString(assignee.email) : '',
    teamId: assignee ? optionalString(assignee.teamId) : '',
    teamName: assignee ? optionalString(assignee.teamName) : '',
    managerId: assignee ? optionalString(assignee.managerId) : '',
    managerName: assignee ? optionalString(assignee.managerName) : '',
    notes: sanitizePlainString(optionalString(leadInput.notes), 4000),
    updatedAt: now,
    updatedBy: actorUid,
    lastContactAt: optionalCallableTimestamp(leadInput.lastContactAt),
    nextFollowUpAt: isClosedLeadStatus
      ? null
      : optionalCallableTimestamp(leadInput.nextFollowUpAt),
    isArchived: existingLead && existingLead.isArchived === true ? true : false,
    archivedAt: existingLead && existingLead.archivedAt ? existingLead.archivedAt : null,
    archivedBy: existingLead ? optionalString(existingLead.archivedBy) : '',
    archivedByName: existingLead ? optionalString(existingLead.archivedByName) : '',
    archiveReason: existingLead ? optionalString(existingLead.archiveReason) : '',
    restoredAt: existingLead && existingLead.restoredAt ? existingLead.restoredAt : null,
    restoredBy: existingLead ? optionalString(existingLead.restoredBy) : '',
    restoredByName: existingLead ? optionalString(existingLead.restoredByName) : '',
  };

  if (isCreate) {
    payload.createdAt = now;
    payload.createdBy = actorUid;
    payload.isArchived = false;
    payload.archivedAt = null;
    payload.archivedBy = '';
    payload.archivedByName = '';
    payload.archiveReason = '';
    payload.restoredAt = null;
    payload.restoredBy = '';
    payload.restoredByName = '';
  }

  return payload;
}

async function hasDuplicateLeadRecord({ companyId, phone, email, excludeLeadId = '' }) {
  const normalizedPhone = normalizeLeadPhone(phone);
  const normalizedEmail = normalizeLeadEmail(email);
  if (!normalizedPhone && !normalizedEmail) {
    return false;
  }

  const cleanExcludeLeadId = optionalString(excludeLeadId);
  const leadsCollection = db.collection(`companies/${companyId}/leads`);
  const checks = [];
  const cleanPhone = optionalString(phone);
  const cleanEmail = optionalString(email);

  if (normalizedPhone) {
    checks.push({
      field: 'phoneNormalized',
      value: normalizedPhone,
      target: normalizedPhone,
      normalizer: (lead) => normalizeLeadPhone(lead.phoneNormalized || lead.phone),
    });
    if (cleanPhone) {
      checks.push({
        field: 'phone',
        value: cleanPhone,
        target: normalizedPhone,
        normalizer: (lead) => normalizeLeadPhone(lead.phone),
      });
    }
    if (cleanPhone !== normalizedPhone) {
      checks.push({
        field: 'phone',
        value: normalizedPhone,
        target: normalizedPhone,
        normalizer: (lead) => normalizeLeadPhone(lead.phone),
      });
    }
  }

  if (normalizedEmail) {
    checks.push({
      field: 'emailNormalized',
      value: normalizedEmail,
      target: normalizedEmail,
      normalizer: (lead) => normalizeLeadEmail(lead.emailNormalized || lead.email),
    });
    if (cleanEmail) {
      checks.push({
        field: 'email',
        value: cleanEmail,
        target: normalizedEmail,
        normalizer: (lead) => normalizeLeadEmail(lead.email),
      });
    }
    if (cleanEmail !== normalizedEmail) {
      checks.push({
        field: 'email',
        value: normalizedEmail,
        target: normalizedEmail,
        normalizer: (lead) => normalizeLeadEmail(lead.email),
      });
    }
  }

  const seenLeadIds = new Set();
  for (const check of checks) {
    const snapshot = await leadsCollection
      .where(check.field, '==', check.value)
      .where('isArchived', '==', false)
      .limit(5)
      .get();

    for (const document of snapshot.docs) {
      if (document.id === cleanExcludeLeadId || seenLeadIds.has(document.id)) {
        continue;
      }
      seenLeadIds.add(document.id);
      const lead = document.data() || {};
      if (optionalString(lead.companyId) !== companyId || lead.isArchived === true) {
        continue;
      }
      if (check.normalizer(lead) === check.target) {
        return true;
      }
    }
  }

  return false;
}

async function updateCrmArchiveState(request, archive) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  const actorUid = request.auth.uid;
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const module = requiredString(data.module, 'module');
  const recordId = requiredString(data.recordId, 'recordId');
  const reason = sanitizePlainString(optionalString(data.reason), 500);
  validateCompanyId(companyId);

  const policy = CRM_ARCHIVE_MODULE_POLICIES[module];
  if (!policy) {
    throw new HttpsError('invalid-argument', 'Archive module is invalid.');
  }

  const actor = await requireActiveCompanyUser(request, companyId);
  const actorRole = optionalString(actor.role);
  if (!['admin', 'manager'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'You do not have permission to archive records.');
  }

  const recordRef = db.doc(`companies/${companyId}/${module}/${recordId}`);
  const recordSnapshot = await recordRef.get();
  if (!recordSnapshot.exists) {
    throw new HttpsError('not-found', 'Record was not found.');
  }
  const record = recordSnapshot.data() || {};
  if (optionalString(record.companyId) !== companyId) {
    throw new HttpsError('permission-denied', 'Record belongs to another company.');
  }
  if (actorRole === 'manager' && !managerCanAccessRecord(actorUid, actor, record)) {
    throw new HttpsError('permission-denied', 'Managers can archive only their team records.');
  }

  const actorName = optionalString(actor.fullName) || optionalString(actor.email) || actorRole;
  const now = FieldValue.serverTimestamp();
  const update = archive
    ? {
        isArchived: true,
        archivedAt: now,
        archivedBy: actorUid,
        archivedByName: actorName,
        archiveReason: reason,
        updatedAt: now,
        updatedBy: actorUid,
      }
    : {
        isArchived: false,
        restoredAt: now,
        restoredBy: actorUid,
        restoredByName: actorName,
        updatedAt: now,
        updatedBy: actorUid,
      };

  if (policy.usesIsActive) {
    update.isActive = !archive;
  }

  const batch = db.batch();
  const auditRef = db.collection(`companies/${companyId}/audit_logs`).doc();
  batch.set(recordRef, update, { merge: true });
  batch.set(
    auditRef,
    crmArchiveAuditPayload({
      auditId: auditRef.id,
      companyId,
      actorUid,
      actor,
      action: archive ? 'archive' : 'restore',
      module,
      recordId,
      record,
      policy,
      reason,
      now,
    }),
  );
  await batch.commit();

  return { companyId, module, recordId, isArchived: archive };
}

function managerCanAccessRecord(actorUid, actor, record) {
  const teamId = optionalString(actor.teamId);
  return optionalString(record.assignedTo) === actorUid ||
    optionalString(record.managerId) === actorUid ||
    (teamId && optionalString(record.teamId) === teamId);
}

function crmArchiveAuditPayload({
  auditId,
  companyId,
  actorUid,
  actor,
  action,
  module,
  recordId,
  record,
  policy,
  reason,
  now,
}) {
  const actorName = optionalString(actor.fullName) || optionalString(actor.email) || optionalString(actor.role);
  const title = sanitizePlainString(
    optionalString(record[policy.titleField]) ||
      optionalString(record[policy.fallbackTitleField]) ||
      policy.fallbackTitle ||
      recordId,
    240,
  );
  return {
    id: auditId,
    companyId,
    actorId: actorUid,
    actorName,
    actorEmail: optionalString(actor.email),
    actorRole: optionalString(actor.role),
    action,
    module,
    recordId,
    recordTitle: title,
    recordSubtitle: crmArchiveRecordSubtitle(module, record),
    assignedTo: optionalString(record.assignedTo),
    teamId: optionalString(record.teamId),
    teamName: optionalString(record.teamName),
    managerId: optionalString(record.managerId),
    managerName: optionalString(record.managerName),
    createdAt: now,
    metadata: {
      module,
      recordId,
      recordTitle: title,
      assignedTo: optionalString(record.assignedTo),
      assignedToName: optionalString(record.assignedToName),
      teamId: optionalString(record.teamId),
      teamName: optionalString(record.teamName),
      managerId: optionalString(record.managerId),
      managerName: optionalString(record.managerName),
      archiveReason: reason,
    },
  };
}

function crmArchiveRecordSubtitle(module, record) {
  if (module === 'leads' || module === 'clients') {
    return sanitizePlainString(optionalString(record.phone) || optionalString(record.email), 240);
  }
  if (module === 'deals') {
    return sanitizePlainString(optionalString(record.propertyTitle) || optionalString(record.stage), 240);
  }
  if (module === 'properties') {
    return sanitizePlainString(optionalString(record.location) || optionalString(record.status), 240);
  }
  return '';
}

async function appointmentRelatedSnapshot({
  companyId,
  actor,
  actorUid,
  actorRole,
  relatedType,
  relatedId,
}) {
  const type = enumValue(relatedType || 'general', new Set([
    'lead',
    'client',
    'property',
    'deal',
    'general',
  ]), 'relatedType');
  const id = optionalString(relatedId);
  if (type === 'general') {
    return {
      relatedType: type,
      relatedId: '',
      relatedTitle: '',
      relatedSubtitle: '',
    };
  }
  if (!id) {
    throw new HttpsError('failed-precondition', 'Related record is required.');
  }

  const collection = {
    lead: 'leads',
    client: 'clients',
    property: 'properties',
    deal: 'deals',
  }[type];
  const snapshot = await db.doc(`companies/${companyId}/${collection}/${id}`).get();
  if (!snapshot.exists) {
    throw new HttpsError('not-found', 'Related record was not found.');
  }
  const record = snapshot.data() || {};
  if (optionalString(record.companyId) !== companyId) {
    throw new HttpsError('permission-denied', 'Related record belongs to another company.');
  }
  if (type === 'lead' && record.isArchived === true) {
    throw new HttpsError('failed-precondition', 'Related lead is archived.');
  }
  if ((type === 'client' || type === 'deal') && record.isActive === false) {
    throw new HttpsError('failed-precondition', 'Related record is inactive.');
  }
  if (type === 'property' && optionalString(record.status) === 'inactive') {
    throw new HttpsError('failed-precondition', 'Related property is inactive.');
  }

  if (actorRole === 'manager') {
    const managerTeamId = optionalString(actor.teamId);
    const canRead = optionalString(record.assignedTo) === actorUid ||
      optionalString(record.managerId) === actorUid ||
      (managerTeamId && optionalString(record.teamId) === managerTeamId);
    if (!canRead) {
      throw new HttpsError('permission-denied', 'You cannot link records outside your team.');
    }
  } else if (actorRole === 'salesAgent' || actorRole === 'marketing') {
    if (optionalString(record.assignedTo) !== actorUid) {
      throw new HttpsError('permission-denied', 'You cannot link another user record.');
    }
  }

  return {
    relatedType: type,
    relatedId: id,
    relatedTitle: appointmentRelatedTitle(type, record, id),
    relatedSubtitle: appointmentRelatedSubtitle(type, record),
  };
}

function appointmentRelatedTitle(type, record, fallbackId) {
  if (type === 'lead' || type === 'client') {
    return sanitizePlainString(optionalString(record.fullName) || fallbackId, 240);
  }
  if (type === 'property') {
    return sanitizePlainString(optionalString(record.title) || fallbackId, 240);
  }
  if (type === 'deal') {
    const clientName = optionalString(record.clientName);
    const propertyTitle = optionalString(record.propertyTitle);
    const title = clientName
      ? (propertyTitle ? `${clientName} - ${propertyTitle}` : clientName)
      : propertyTitle;
    return sanitizePlainString(title || fallbackId, 240);
  }
  return '';
}

function appointmentRelatedSubtitle(type, record) {
  if (type === 'lead') {
    return sanitizePlainString(optionalString(record.phone) || optionalString(record.status), 240);
  }
  if (type === 'client') {
    return sanitizePlainString(
      optionalString(record.phone) || optionalString(record.preferredLocation),
      240,
    );
  }
  if (type === 'property') {
    return sanitizePlainString(optionalString(record.location), 240);
  }
  if (type === 'deal') {
    return sanitizePlainString(optionalString(record.stage), 240);
  }
  return '';
}

function buildAppointmentPayload({
  companyId,
  appointmentId,
  appointmentInput,
  assignedTo,
  assignee,
  relatedSnapshot,
  actorUid,
  now,
  existingAppointment,
  isCreate,
}) {
  const type = enumValue(appointmentInput.type, APPOINTMENT_TYPES, 'type');
  let status = enumValue(appointmentInput.status || 'scheduled', APPOINTMENT_STATUSES, 'status');
  const scheduledAt = requiredCallableTimestamp(appointmentInput.scheduledAt, 'scheduledAt');
  const endAt = requiredCallableTimestamp(appointmentInput.endAt, 'endAt');
  const durationMinutes = numberValue(appointmentInput.durationMinutes, 'durationMinutes');
  if (durationMinutes <= 0 || durationMinutes > 1440) {
    throw new HttpsError('invalid-argument', 'Appointment duration is invalid.');
  }
  if (endAt.toMillis() <= scheduledAt.toMillis()) {
    throw new HttpsError('invalid-argument', 'Appointment end time must be after start time.');
  }

  const previousScheduledAt = existingAppointment && existingAppointment.scheduledAt
    ? existingAppointment.scheduledAt
    : null;
  const previousEndAt = existingAppointment && existingAppointment.endAt
    ? existingAppointment.endAt
    : null;
  const scheduleChanged = existingAppointment &&
    previousScheduledAt &&
    previousScheduledAt.toMillis &&
    previousScheduledAt.toMillis() !== scheduledAt.toMillis();
  if (scheduleChanged && !['completed', 'cancelled'].includes(normalizedWorkflowValue(status))) {
    status = 'rescheduled';
  }
  const cleanOutcomeInput = optionalString(appointmentInput.outcome);
  const outcome = cleanOutcomeInput
    ? enumValue(cleanOutcomeInput, APPOINTMENT_OUTCOMES, 'outcome')
    : '';
  const cancellationReason = sanitizePlainString(
    optionalString(appointmentInput.cancellationReason),
    1000,
  );

  const assigneeRole = optionalString(assignee.role);
  const assigneeIsManager = assigneeRole === 'manager';
  const resolvedManagerId = assigneeIsManager ? assignedTo : optionalString(assignee.managerId);
  const resolvedManagerName = assigneeIsManager
    ? optionalString(assignee.fullName)
    : optionalString(assignee.managerName);

  const payload = {
    id: appointmentId,
    companyId,
    title: sanitizePlainString(requiredString(appointmentInput.title, 'title'), 180),
    type,
    status,
    scheduledAt,
    endAt,
    durationMinutes,
    assignedTo,
    assignedToName: optionalString(assignee.fullName),
    assignedToEmail: optionalString(assignee.email),
    teamId: optionalString(assignee.teamId),
    teamName: optionalString(assignee.teamName),
    managerId: resolvedManagerId,
    managerName: resolvedManagerName,
    relatedType: relatedSnapshot.relatedType,
    relatedId: relatedSnapshot.relatedId,
    relatedTitle: relatedSnapshot.relatedTitle,
    relatedSubtitle: relatedSnapshot.relatedSubtitle,
    location: sanitizePlainString(optionalString(appointmentInput.location), 240),
    notes: sanitizePlainString(optionalString(appointmentInput.notes), 4000),
    outcome: status === 'completed' ? outcome : '',
    outcomeNotes: sanitizePlainString(optionalString(appointmentInput.outcomeNotes), 4000),
    cancellationReason: status === 'cancelled' ? cancellationReason : '',
    updatedAt: now,
    updatedBy: actorUid,
    completedAt: existingAppointment && existingAppointment.completedAt ? existingAppointment.completedAt : null,
    completedBy: existingAppointment ? optionalString(existingAppointment.completedBy) : '',
    cancelledAt: existingAppointment && existingAppointment.cancelledAt ? existingAppointment.cancelledAt : null,
    cancelledBy: existingAppointment ? optionalString(existingAppointment.cancelledBy) : '',
    missedAt: existingAppointment && existingAppointment.missedAt ? existingAppointment.missedAt : null,
    missedBy: existingAppointment ? optionalString(existingAppointment.missedBy) : '',
    rescheduledFrom: existingAppointment && existingAppointment.rescheduledFrom
      ? existingAppointment.rescheduledFrom
      : null,
    previousScheduledAt: existingAppointment && existingAppointment.previousScheduledAt
      ? existingAppointment.previousScheduledAt
      : null,
    previousEndAt: existingAppointment && existingAppointment.previousEndAt
      ? existingAppointment.previousEndAt
      : null,
  };

  if (status === 'completed' && optionalString(payload.completedBy) === '') {
    payload.completedAt = now;
    payload.completedBy = actorUid;
    if (!payload.outcome) {
      payload.outcome = 'other';
    }
  }
  if (status === 'cancelled' && optionalString(payload.cancelledBy) === '') {
    payload.cancelledAt = now;
    payload.cancelledBy = actorUid;
  }
  if (status === 'missed' && optionalString(payload.missedBy) === '') {
    payload.missedAt = now;
    payload.missedBy = actorUid;
  }
  if (scheduleChanged) {
    payload.rescheduledFrom = previousScheduledAt;
    payload.previousScheduledAt = previousScheduledAt;
    payload.previousEndAt = previousEndAt;
    if (status === 'scheduled' || status === 'rescheduled') {
      payload.completedAt = null;
      payload.completedBy = '';
      payload.cancelledAt = null;
      payload.cancelledBy = '';
      payload.missedAt = null;
      payload.missedBy = '';
      payload.outcome = '';
      payload.cancellationReason = '';
    }
  }

  if (isCreate) {
    payload.createdAt = now;
    payload.createdBy = actorUid;
    payload.completedAt = status === 'completed' ? now : null;
    payload.completedBy = status === 'completed' ? actorUid : '';
    payload.cancelledAt = status === 'cancelled' ? now : null;
    payload.cancelledBy = status === 'cancelled' ? actorUid : '';
    payload.missedAt = status === 'missed' ? now : null;
    payload.missedBy = status === 'missed' ? actorUid : '';
    payload.rescheduledFrom = null;
    payload.previousScheduledAt = null;
    payload.previousEndAt = null;
  }

  return payload;
}

async function createAppointmentAssignmentNotifications({
  companyId,
  appointmentId,
  operation,
  actorUid,
  actorName,
  existingAppointment,
  payload,
}) {
  const previousAssignedTo = existingAppointment
    ? optionalString(existingAppointment.assignedTo)
    : '';
  const nextAssignedTo = optionalString(payload.assignedTo);
  await createAssignmentNotificationsForRecord({
    companyId,
    module: 'appointments',
    recordId: appointmentId,
    recordTitle: optionalString(payload.title),
    recordSubtitle: appointmentRecordSubtitle(payload),
    route: '/appointments',
    previousRecord: operation === 'create' ? null : existingAppointment,
    nextRecord: payload,
    actorUid,
    actorName,
    assignedType: previousAssignedTo ? 'appointmentReassigned' : 'appointmentAssigned',
    removedType: 'appointmentRemovedFromYou',
    priority: 'normal',
    metadata: {
      assignedToName: optionalString(payload.assignedToName),
      relatedTitle: optionalString(payload.relatedTitle),
      scheduledAt: firestoreTimestampToIso(payload.scheduledAt),
    },
    dedupePrefix: `appointment_assignment_${appointmentId}_${previousAssignedTo}_${nextAssignedTo}`,
    managerAssignedType: 'teamAppointmentAssigned',
    managerReassignedType: 'teamAppointmentReassigned',
  });
}

async function createAppointmentStatusNotifications({
  companyId,
  appointmentId,
  actorUid,
  actorName,
  before,
  after,
}) {
  if (!before) {
    return;
  }
  const previousStatus = optionalString(before.status);
  const nextStatus = optionalString(after.status);
  const scheduleChanged = appointmentScheduleChanged(before, after);
  if (!nextStatus || (previousStatus === nextStatus && !scheduleChanged)) {
    return;
  }
  const effectiveStatus = scheduleChanged && previousStatus === nextStatus
    ? 'rescheduled'
    : nextStatus;
  const userType = appointmentStatusNotificationType(effectiveStatus);
  const teamType = teamAppointmentStatusNotificationType(effectiveStatus);
  if (!userType || !teamType) {
    return;
  }
  const eventId = Date.now().toString(36);
  const base = {
    companyId,
    module: 'appointments',
    recordId: appointmentId,
    recordTitle: optionalString(after.title),
    recordSubtitle: appointmentRecordSubtitle(after),
    route: '/appointments',
    actorUid,
    actorName,
    teamId: optionalString(after.teamId),
    teamName: optionalString(after.teamName),
    managerId: optionalString(after.managerId),
    priority: effectiveStatus === 'cancelled' || effectiveStatus === 'missed' || effectiveStatus === 'rescheduled' ? 'high' : 'normal',
    metadata: {
      previousStatus,
      newStatus: effectiveStatus,
      assignedToName: optionalString(after.assignedToName),
      scheduledAt: firestoreTimestampToIso(after.scheduledAt),
      previousScheduledAt: firestoreTimestampToIso(after.previousScheduledAt),
      outcome: optionalString(after.outcome),
      cancellationReason: optionalString(after.cancellationReason),
    },
  };
  const assignedTo = optionalString(after.assignedTo);
  if (assignedTo && assignedTo !== actorUid) {
    await createCompanyNotification({
      ...base,
      recipientUid: assignedTo,
      recipientRole: '',
      type: userType,
      dedupeKey: `appointment_status_${appointmentId}_${eventId}_${assignedTo}`,
    });
  }
  const managerId = optionalString(after.managerId);
  if (managerId && managerId !== actorUid) {
    await createCompanyNotification({
      ...base,
      recipientUid: managerId,
      recipientRole: 'manager',
      type: teamType,
      dedupeKey: `appointment_status_${appointmentId}_${eventId}_manager_${managerId}`,
    });
  }
  await notifyCompanyAdminsForImportantRecordEvent({
    companyId,
    base: {
      ...base,
      type: teamType,
    },
    actorUid,
    dedupeKey: `appointment_status_${appointmentId}_${eventId}`,
  });
}

async function resolveStaleAppointmentTimingNotifications({
  companyId,
  appointmentId,
  appointment,
}) {
  const status = normalizedWorkflowValue(appointment.status);
  const scheduledAtIso = firestoreTimestampToIso(appointment.scheduledAt);
  const openSchedule = ['scheduled', 'rescheduled'].includes(status);
  const actionTypes = new Set([
    'appointmentDueSoon',
    'appointmentDueNow',
    'appointmentMissed',
    'teamAppointmentDueSoon',
    'teamAppointmentDueNow',
    'teamAppointmentMissed',
  ]);
  const snapshot = await db
    .collection(`companies/${companyId}/notifications`)
    .where('recordId', '==', appointmentId)
    .limit(80)
    .get();
  if (snapshot.empty) {
    return;
  }

  const batch = db.batch();
  let writes = 0;
  for (const document of snapshot.docs) {
    const notification = document.data() || {};
    const type = optionalString(notification.type);
    if (optionalString(notification.module) !== 'appointments' ||
        !actionTypes.has(type) ||
        optionalString(notification.actionState) !== 'actionNeeded') {
      continue;
    }
    const metadata = notification.metadata || {};
    const notificationScheduledAt = optionalString(metadata.scheduledAt);
    const stillCurrentOpenReminder = openSchedule &&
      scheduledAtIso &&
      notificationScheduledAt === scheduledAtIso;
    if (stillCurrentOpenReminder) {
      continue;
    }
    batch.update(document.ref, {
      isRead: true,
      actionState: 'resolved',
      resolvedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    writes += 1;
  }
  if (writes > 0) {
    await batch.commit();
  }
}

async function createAppointmentTimingNotifications({
  companyId,
  appointmentId,
  appointment,
  now,
}) {
  await Promise.allSettled([
    createAppointmentDueSoonNotifications({
      companyId,
      appointmentId,
      appointment,
      now,
    }),
    createAppointmentDueNotifications({
      companyId,
      appointmentId,
      appointment,
      now,
    }),
  ]);
}

async function createAppointmentDueSoonNotifications({
  companyId,
  appointmentId,
  appointment,
  now,
}) {
  const status = normalizedWorkflowValue(appointment.status);
  if (!['scheduled', 'rescheduled'].includes(status)) {
    return;
  }
  const scheduledAt = appointment.scheduledAt;
  if (!scheduledAt || typeof scheduledAt.toMillis !== 'function') {
    return;
  }
  const msUntilStart = scheduledAt.toMillis() - now.toMillis();
  if (msUntilStart <= 0 || msUntilStart > 10 * 60 * 1000) {
    return;
  }
  await createAppointmentTimingNotificationPair({
    companyId,
    appointmentId,
    appointment,
    notificationType: 'appointmentDueSoon',
    teamNotificationType: 'teamAppointmentDueSoon',
    dedupePrefix: 'appointment_due_soon',
    fallbackTitle: 'Appointment in 10 minutes',
    fallbackBody: `${optionalString(appointment.title) || appointmentId} starts in about 10 minutes.`,
    teamFallbackTitle: 'Team appointment in 10 minutes',
    teamFallbackBody: `${optionalString(appointment.title) || appointmentId} starts soon for ${optionalString(appointment.assignedToName) || 'a team member'}.`,
    priority: 'high',
  });
}

async function createAppointmentDueNotifications({
  companyId,
  appointmentId,
  appointment,
  now,
}) {
  const status = normalizedWorkflowValue(appointment.status);
  if (!['scheduled', 'rescheduled'].includes(status)) {
    return;
  }
  const scheduledAt = appointment.scheduledAt;
  if (!scheduledAt || typeof scheduledAt.toMillis !== 'function') {
    return;
  }
  if (scheduledAt.toMillis() > now.toMillis()) {
    return;
  }
  await createAppointmentTimingNotificationPair({
    companyId,
    appointmentId,
    appointment,
    notificationType: 'appointmentDueNow',
    teamNotificationType: 'teamAppointmentDueNow',
    dedupePrefix: 'appointment_due',
    fallbackTitle: 'Appointment due now',
    fallbackBody: `${optionalString(appointment.title) || appointmentId} is due now.`,
    teamFallbackTitle: 'Team appointment due now',
    teamFallbackBody: `${optionalString(appointment.title) || appointmentId} is due now for ${optionalString(appointment.assignedToName) || 'a team member'}.`,
    priority: 'high',
  });
}

async function createAppointmentTimingNotificationPair({
  companyId,
  appointmentId,
  appointment,
  notificationType,
  teamNotificationType,
  dedupePrefix,
  fallbackTitle,
  fallbackBody,
  teamFallbackTitle,
  teamFallbackBody,
  priority,
}) {
  const scheduledAt = appointment.scheduledAt;
  if (!scheduledAt || typeof scheduledAt.toMillis !== 'function') {
    return;
  }
  const assignedTo = optionalString(appointment.assignedTo);
  const managerId = optionalString(appointment.managerId);
  const title = optionalString(appointment.title) || appointmentId;
  const subtitle = appointmentRecordSubtitle(appointment);
  const scheduledAtIso = firestoreTimestampToIso(scheduledAt);
  const dueDedupeKey = appointmentDueDedupeKeySegment(scheduledAt);
  const metadata = {
    scheduledAt: scheduledAtIso,
    assignedToName: optionalString(appointment.assignedToName),
    relatedTitle: optionalString(appointment.relatedTitle),
  };
  const base = {
    companyId,
    module: 'appointments',
    recordId: appointmentId,
    recordTitle: title,
    recordSubtitle: subtitle,
    route: '/appointments',
    actorUid: '',
    actorName: '',
    teamId: optionalString(appointment.teamId),
    teamName: optionalString(appointment.teamName),
    managerId,
    priority,
    metadata,
  };
  const writes = [];

  if (assignedTo) {
    writes.push(createCompanyNotification({
      ...base,
      recipientUid: assignedTo,
      recipientRole: '',
      type: notificationType,
      fallbackTitle,
      fallbackBody,
      dedupeKey: `${dedupePrefix}_${companyId}_${appointmentId}_${assignedTo}_${dueDedupeKey}`,
    }));
  }

  if (managerId && managerId !== assignedTo) {
    writes.push(createCompanyNotification({
      ...base,
      recipientUid: managerId,
      recipientRole: 'manager',
      type: teamNotificationType,
      fallbackTitle: teamFallbackTitle,
      fallbackBody: teamFallbackBody,
      dedupeKey: `${dedupePrefix}_${companyId}_${appointmentId}_manager_${managerId}_${dueDedupeKey}`,
    }));
  }

  await Promise.all(writes);
}

function appointmentDueDedupeKeySegment(scheduledAt) {
  if (!scheduledAt || typeof scheduledAt.toMillis !== 'function') {
    return 'unknown_due_time';
  }
  return scheduledAt.toMillis().toString();
}

function appointmentScheduleChanged(before, after) {
  return appointmentTimestampMillis(before && before.scheduledAt) !== appointmentTimestampMillis(after && after.scheduledAt) ||
    appointmentTimestampMillis(before && before.endAt) !== appointmentTimestampMillis(after && after.endAt);
}

function appointmentTimestampMillis(value) {
  if (!value || typeof value.toMillis !== 'function') {
    return 0;
  }
  return value.toMillis();
}

function appointmentStatusNotificationType(status) {
  if (status === 'rescheduled') {
    return 'appointmentRescheduled';
  }
  if (status === 'cancelled') {
    return 'appointmentCancelled';
  }
  if (status === 'completed') {
    return 'appointmentCompleted';
  }
  if (status === 'missed') {
    return 'appointmentMissed';
  }
  return '';
}

function teamAppointmentStatusNotificationType(status) {
  if (status === 'rescheduled') {
    return 'teamAppointmentRescheduled';
  }
  if (status === 'cancelled') {
    return 'teamAppointmentCancelled';
  }
  if (status === 'completed') {
    return 'teamAppointmentCompleted';
  }
  if (status === 'missed') {
    return 'teamAppointmentMissed';
  }
  return '';
}

function appointmentRecordSubtitle(appointment) {
  return optionalString(appointment.relatedTitle) ||
    optionalString(appointment.relatedSubtitle) ||
    firestoreTimestampToIso(appointment.scheduledAt);
}

async function createLeadAssignmentNotifications({
  companyId,
  leadId,
  operation,
  actorUid,
  actor,
  existingLead,
  payload,
}) {
  const previousAssignedTo = existingLead ? optionalString(existingLead.assignedTo) : '';
  const nextAssignedTo = optionalString(payload.assignedTo);
  if (previousAssignedTo === nextAssignedTo) {
    return;
  }

  const actorName = optionalString(actor.fullName) || optionalString(actor.email);
  await createAssignmentNotificationsForRecord({
    companyId,
    module: 'leads',
    recordId: leadId,
    recordTitle: optionalString(payload.fullName),
    recordSubtitle: optionalString(payload.sourceDetails) || optionalString(payload.source),
    route: `/leads/${leadId}`,
    previousRecord: existingLead,
    nextRecord: payload,
    actorUid,
    actorName,
    assignedType: operation === 'create' || !previousAssignedTo ? 'leadAssigned' : 'leadReassigned',
    removedType: 'leadRemovedFromYou',
    priority: optionalString(payload.priority) === 'high' ? 'high' : 'normal',
    metadata: {
      source: optionalString(payload.source),
      status: optionalString(payload.status),
      previousAssignedTo,
      assignedToName: optionalString(payload.assignedToName),
    },
    dedupePrefix: `lead_${leadId}_${operation}_${previousAssignedTo}_${nextAssignedTo}`,
  });
}

async function createLeadImportantStatusNotifications({
  companyId,
  leadId,
  actorUid,
  actor,
  existingLead,
  payload,
}) {
  if (!existingLead) {
    return;
  }
  const previousAssignedTo = optionalString(existingLead.assignedTo);
  const nextAssignedTo = optionalString(payload.assignedTo);
  if (previousAssignedTo !== nextAssignedTo) {
    return;
  }
  const previousStatus = optionalString(existingLead.status);
  const nextStatus = optionalString(payload.status);
  if (!nextStatus || previousStatus === nextStatus || !isImportantLeadStatus(nextStatus)) {
    return;
  }

  const actorName = optionalString(actor.fullName) || optionalString(actor.email);
  const base = {
    companyId,
    type: 'leadImportantStatusChanged',
    module: 'leads',
    recordId: leadId,
    recordTitle: optionalString(payload.fullName),
    recordSubtitle: optionalString(payload.sourceDetails) || optionalString(payload.source),
    route: `/leads/${leadId}`,
    actorUid,
    actorName,
    teamId: optionalString(payload.teamId),
    teamName: optionalString(payload.teamName),
    managerId: optionalString(payload.managerId),
    priority: nextStatus === 'won' || nextStatus === 'lost' ? 'high' : 'normal',
    metadata: {
      previousStatus,
      newStatus: effectiveStatus,
    },
  };

  const assignedTo = optionalString(payload.assignedTo);
  if (assignedTo && assignedTo !== actorUid) {
    await createCompanyNotification({
      ...base,
      recipientUid: assignedTo,
      recipientRole: '',
      dedupeKey: `lead_status_${leadId}_${previousStatus}_${nextStatus}_${assignedTo}`,
    });
  }
  const managerId = optionalString(payload.managerId);
  if (managerId && managerId !== actorUid) {
    await createCompanyNotification({
      ...base,
      recipientUid: managerId,
      recipientRole: 'manager',
      type: 'teamLeadStatusChanged',
      dedupeKey: `lead_status_${leadId}_${previousStatus}_${nextStatus}_manager_${managerId}`,
    });
  }
  await notifyCompanyAdminsForImportantRecordEvent({
    companyId,
    base: {
      ...base,
      type: 'teamLeadStatusChanged',
    },
    actorUid,
    dedupeKey: `lead_status_${leadId}_${previousStatus}_${nextStatus}`,
  });
}

async function createAssignmentNotificationsForRecord({
  companyId,
  module,
  recordId,
  recordTitle,
  recordSubtitle,
  route,
  previousRecord,
  nextRecord,
  actorUid,
  actorName,
  assignedType,
  removedType,
  priority,
  metadata,
  dedupePrefix,
  managerAssignedType,
  managerReassignedType,
  managerRemovedType,
}) {
  const previousAssignedTo = previousRecord ? optionalString(previousRecord.assignedTo) : '';
  const nextAssignedTo = optionalString(nextRecord.assignedTo);
  if (previousAssignedTo === nextAssignedTo) {
    return;
  }

  const previousAssignee = await loadCompanyUserSafe(companyId, previousAssignedTo);
  const nextAssignee = await loadCompanyUserSafe(companyId, nextAssignedTo);
  const previousSnapshot = assigneeNotificationSnapshot(previousAssignee, previousRecord);
  const nextSnapshot = assigneeNotificationSnapshot(nextAssignee, nextRecord);

  if (nextAssignedTo && nextAssignedTo !== actorUid) {
    await createCompanyNotification({
      companyId,
      recipientUid: nextAssignedTo,
      recipientRole: optionalString(nextAssignee && nextAssignee.role),
      type: assignedType,
      module,
      recordId,
      recordTitle,
      recordSubtitle,
      route,
      actorUid,
      actorName,
      teamId: nextSnapshot.teamId,
      teamName: nextSnapshot.teamName,
      managerId: nextSnapshot.managerId,
      priority: assignmentPushPriority(assignedType, priority),
      metadata: {
        ...safeNotificationMetadata(metadata),
        assignedToName: nextSnapshot.name,
        previousAssignedToName: previousSnapshot.name,
      },
      dedupeKey: `${dedupePrefix}_${nextAssignedTo}`,
    });
  }

  if (previousAssignedTo && previousAssignedTo !== nextAssignedTo && previousAssignedTo !== actorUid) {
    await createCompanyNotification({
      companyId,
      recipientUid: previousAssignedTo,
      recipientRole: '',
      type: removedType,
      module,
      recordId,
      recordTitle,
      recordSubtitle,
      route: '/dashboard',
      actorUid,
      actorName,
      teamId: previousSnapshot.teamId,
      teamName: previousSnapshot.teamName,
      managerId: previousSnapshot.managerId,
      priority: 'normal',
      metadata: {
        ...safeNotificationMetadata(metadata),
        newAssignedTo: nextAssignedTo,
        assignedToName: nextSnapshot.name,
        previousAssignedToName: previousSnapshot.name,
      },
      dedupeKey: `${dedupePrefix}_removed_${previousAssignedTo}`,
    });
  }

  await createManagerAssignmentNotificationsForRecord({
    companyId,
    module,
    recordId,
    recordTitle,
    recordSubtitle,
    route,
    actorUid,
    actorName,
    previousAssignedTo,
    nextAssignedTo,
    previousSnapshot,
    nextSnapshot,
    priority,
    metadata,
    dedupePrefix,
    managerAssignedType,
    managerReassignedType,
    managerRemovedType,
  });
}

function assignmentPushPriority(type, priority) {
  const cleanPriority = optionalString(priority);
  if (['high', 'urgent', 'critical'].includes(cleanPriority)) {
    return cleanPriority;
  }
  return [
    'leadAssigned',
    'leadReassigned',
    'taskAssigned',
    'taskReassigned',
    'appointmentAssigned',
    'appointmentReassigned',
    'clientAssigned',
    'clientReassigned',
    'dealAssigned',
    'dealReassigned',
  ].includes(optionalString(type))
    ? 'high'
    : cleanPriority || 'normal';
}

function assigneeNotificationSnapshot(user, record) {
  const source = record || {};
  const cleanUser = user || {};
  return {
    name: optionalString(cleanUser.fullName) ||
      optionalString(source.assignedToName) ||
      optionalString(cleanUser.email) ||
      optionalString(source.assignedToEmail),
    email: optionalString(cleanUser.email) || optionalString(source.assignedToEmail),
    role: optionalString(cleanUser.role),
    teamId: optionalString(cleanUser.teamId) || optionalString(source.teamId),
    teamName: optionalString(cleanUser.teamName) || optionalString(source.teamName),
    managerId: optionalString(cleanUser.managerId) || optionalString(source.managerId),
    managerName: optionalString(cleanUser.managerName) || optionalString(source.managerName),
  };
}

async function createManagerAssignmentNotificationsForRecord({
  companyId,
  module,
  recordId,
  recordTitle,
  recordSubtitle,
  route,
  actorUid,
  actorName,
  previousAssignedTo,
  nextAssignedTo,
  previousSnapshot,
  nextSnapshot,
  priority,
  metadata,
  dedupePrefix,
  managerAssignedType,
  managerReassignedType,
  managerRemovedType,
}) {
  const notificationsByManager = new Map();

  if (nextAssignedTo && nextSnapshot.managerId && nextSnapshot.managerId !== actorUid) {
    notificationsByManager.set(nextSnapshot.managerId, {
      type: previousAssignedTo
        ? optionalString(managerReassignedType) || 'teamMemberReassigned'
        : optionalString(managerAssignedType) || 'teamMemberAssigned',
      teamId: nextSnapshot.teamId,
      teamName: nextSnapshot.teamName,
      managerId: nextSnapshot.managerId,
      route,
      assignedToName: nextSnapshot.name,
      previousAssignedToName: previousSnapshot.name,
    });
  }

  if (
    previousAssignedTo &&
    previousAssignedTo !== nextAssignedTo &&
    previousSnapshot.managerId &&
    previousSnapshot.managerId !== actorUid
  ) {
    const existing = notificationsByManager.get(previousSnapshot.managerId);
    notificationsByManager.set(previousSnapshot.managerId, {
      type: existing
        ? optionalString(managerReassignedType) || 'teamMemberReassigned'
        : optionalString(managerRemovedType) || 'teamMemberRemovedFromRecord',
      teamId: existing ? existing.teamId : previousSnapshot.teamId,
      teamName: existing ? existing.teamName : previousSnapshot.teamName,
      managerId: previousSnapshot.managerId,
      route: existing ? existing.route : '/dashboard',
      assignedToName: existing ? existing.assignedToName : nextSnapshot.name,
      previousAssignedToName: previousSnapshot.name,
    });
  }

  for (const [managerUid, item] of notificationsByManager.entries()) {
    await createCompanyNotification({
      companyId,
      recipientUid: managerUid,
      recipientRole: 'manager',
      type: item.type,
      module,
      recordId,
      recordTitle,
      recordSubtitle,
      route: item.route,
      actorUid,
      actorName,
      teamId: item.teamId,
      teamName: item.teamName,
      managerId: item.managerId,
      priority,
      metadata: {
        ...safeNotificationMetadata(metadata),
        assignedToName: item.assignedToName,
        previousAssignedToName: item.previousAssignedToName,
      },
      dedupeKey: `${dedupePrefix}_manager_${managerUid}`,
    });
  }
}

async function createTaskStatusNotifications({
  companyId,
  taskId,
  before,
  after,
  actorUid,
  actorName,
  eventId,
}) {
  if (!before) {
    return;
  }
  const previousStatus = optionalString(before.status);
  const nextStatus = optionalString(after.status);
  if (!nextStatus || previousStatus === nextStatus || !isImportantTaskStatus(nextStatus)) {
    return;
  }

  const base = {
    companyId,
    module: 'tasks',
    recordId: taskId,
    recordTitle: optionalString(after.title),
    recordSubtitle: optionalString(after.relatedTitle) || optionalString(after.relatedSubtitle),
    route: `/tasks/${taskId}/edit`,
    actorUid,
    actorName,
    teamId: optionalString(after.teamId),
    teamName: optionalString(after.teamName),
    managerId: optionalString(after.managerId),
    priority: nextStatus === 'cancelled' || nextStatus === 'canceled' ? 'high' : 'normal',
    metadata: {
      previousStatus,
      newStatus: effectiveStatus,
      assignedToName: optionalString(after.assignedToName),
    },
  };

  const assignedTo = optionalString(after.assignedTo);
  if (assignedTo && assignedTo !== actorUid) {
    await createCompanyNotification({
      ...base,
      recipientUid: assignedTo,
      recipientRole: '',
      type: 'taskStatusChanged',
      dedupeKey: `task_status_${taskId}_${eventId}_${assignedTo}`,
    });
  }

  const managerId = optionalString(after.managerId);
  if (managerId && managerId !== actorUid) {
    await createCompanyNotification({
      ...base,
      recipientUid: managerId,
      recipientRole: 'manager',
      type: 'teamTaskStatusChanged',
      dedupeKey: `task_status_${taskId}_${eventId}_manager_${managerId}`,
    });
  }
  await notifyCompanyAdminsForImportantRecordEvent({
    companyId,
    base: {
      ...base,
      type: 'teamTaskStatusChanged',
    },
    actorUid,
    dedupeKey: `task_status_${taskId}_${eventId}`,
  });
}

async function createDealStageNotifications({
  companyId,
  dealId,
  before,
  after,
  actorUid,
  actorName,
  eventId,
}) {
  if (!before) {
    return;
  }
  const previousStage = optionalString(before.stage);
  const nextStage = optionalString(after.stage);
  if (!nextStage || previousStage === nextStage) {
    return;
  }

  const important = isImportantDealStage(nextStage);
  const majorOutcome = isMajorDealOutcome(nextStage);
  const type = nextStage === 'won' || nextStage === 'closedWon'
    ? 'dealWon'
    : nextStage === 'lost' || nextStage === 'closedLost'
      ? 'dealLost'
      : important
        ? 'dealImportantStatusChanged'
        : 'dealStageChanged';
  const priority = majorOutcome ? 'high' : 'normal';
  const base = {
    companyId,
    type,
    module: 'deals',
    recordId: dealId,
    recordTitle: dealTitle(after, dealId),
    recordSubtitle: optionalString(after.propertyLocation) || optionalString(after.clientPhone),
    route: `/deals/${dealId}`,
    actorUid,
    actorName,
    teamId: optionalString(after.teamId),
    teamName: optionalString(after.teamName),
    managerId: optionalString(after.managerId),
    priority,
    metadata: {
      previousStage,
      newStage: nextStage,
      newStatus: nextStage,
      expectedValue: typeof after.expectedValue === 'number' ? after.expectedValue : null,
    },
  };

  const recipients = new Set();
  const assignedTo = optionalString(after.assignedTo);
  if (assignedTo && assignedTo !== actorUid) {
    recipients.add(assignedTo);
  }
  if (important) {
    const managerId = optionalString(after.managerId);
    if (managerId && managerId !== actorUid) {
      await createCompanyNotification({
        ...base,
        recipientUid: managerId,
        recipientRole: 'manager',
        type: 'teamDealStageChanged',
        dedupeKey: `deal_stage_${dealId}_${eventId}_manager_${managerId}`,
      });
    }
  }

  for (const recipientUid of recipients) {
    await createCompanyNotification({
      ...base,
      recipientUid,
      recipientRole: '',
      dedupeKey: `deal_stage_${dealId}_${eventId}_${recipientUid}`,
    });
  }

  if (majorOutcome) {
    await notifyCompanyAdminsForDealOutcome({
      companyId,
      base,
      actorUid,
      dealId,
      eventId,
    });
    await createPlatformDealOutcomeNotification({
      companyId,
      dealId,
      actorUid,
      before,
      after,
      type,
      nextStage,
      eventId,
    });
  }
}


async function createPlatformDealOutcomeNotification({
  companyId,
  dealId,
  actorUid,
  before,
  after,
  type,
  nextStage,
  eventId,
}) {
  const companySnapshot = await db.doc(`companies/${companyId}`).get();
  const company = companySnapshot.exists ? companySnapshot.data() || {} : {};
  const actor = await notificationActorSummary(companyId, actorUid);
  const isWon = type === 'dealWon';
  const title = isWon ? 'Deal won' : 'Deal lost';
  const amount = typeof after.expectedValue === 'number' ? after.expectedValue : null;
  await createPlatformNotificationSafely('deal_outcome', {
    id: `platform_deal_outcome_${companyId}_${dealId}_${eventId}`,
    type: isWon ? 'dealWon' : 'dealLost',
    title,
    message: `${dealTitle(after, dealId)} moved from ${optionalString(before && before.stage) || 'previous stage'} to ${nextStage} in ${companyNotificationName(companyId, company)} by ${actor.actorName || actor.actorEmail || actorUid}.`,
    severity: isWon ? 'success' : 'warning',
    source: 'company',
    route: '/platform',
    actorId: actor.actorId,
    actorName: actor.actorName,
    actorEmail: actor.actorEmail,
    companyId,
    companyName: companyNotificationName(companyId, company),
    metadata: {
      dealId,
      dealTitle: dealTitle(after, dealId),
      previousStage: optionalString(before && before.stage),
      newStage: nextStage,
      expectedValue: amount,
      assignedTo: optionalString(after.assignedTo),
      assignedToName: optionalString(after.assignedToName),
      managerId: optionalString(after.managerId),
      teamId: optionalString(after.teamId),
    },
  });
}

async function notifyCompanyAdminsForImportantRecordEvent({
  companyId,
  base,
  actorUid,
  dedupeKey,
}) {
  const adminsSnapshot = await db.collection(`companies/${companyId}/users`)
    .where('role', '==', 'admin')
    .where('isActive', '==', true)
    .limit(20)
    .get();
  for (const document of adminsSnapshot.docs) {
    const adminUid = document.id;
    if (!adminUid || adminUid === actorUid) {
      continue;
    }
    await createCompanyNotification({
      ...base,
      recipientUid: adminUid,
      recipientRole: 'admin',
      dedupeKey: `${dedupeKey}_admin_${adminUid}`,
    });
  }
}

async function notifyCompanyAdminsForDealOutcome({
  companyId,
  base,
  actorUid,
  dealId,
  eventId,
}) {
  const adminsSnapshot = await db.collection(`companies/${companyId}/users`)
    .where('role', '==', 'admin')
    .where('isActive', '==', true)
    .limit(20)
    .get();
  for (const document of adminsSnapshot.docs) {
    const adminUid = document.id;
    if (!adminUid || adminUid === actorUid) {
      continue;
    }
    await createCompanyNotification({
      ...base,
      recipientUid: adminUid,
      recipientRole: 'admin',
      dedupeKey: `deal_outcome_${dealId}_${eventId}_admin_${adminUid}`,
    });
  }
}

function normalizedWorkflowValue(value) {
  return optionalString(value).replace(/[\s_-]/g, '').toLowerCase();
}

function setHasWorkflowValue(values, value) {
  const key = normalizedWorkflowValue(value);
  for (const item of values) {
    if (normalizedWorkflowValue(item) === key) {
      return true;
    }
  }
  return false;
}

function isImportantLeadStatus(value) {
  return setHasWorkflowValue(IMPORTANT_LEAD_STATUSES, value);
}

function isImportantDealStage(value) {
  return setHasWorkflowValue(IMPORTANT_DEAL_STAGES, value);
}

function isMajorDealOutcome(value) {
  return setHasWorkflowValue(MAJOR_DEAL_OUTCOMES, value);
}

function isImportantTaskStatus(value) {
  return setHasWorkflowValue(IMPORTANT_TASK_STATUSES, value);
}

function dealTitle(record, fallbackId) {
  const clientName = optionalString(record.clientName);
  const propertyTitle = optionalString(record.propertyTitle);
  if (clientName && propertyTitle) {
    return `${clientName} - ${propertyTitle}`;
  }
  return clientName || propertyTitle || fallbackId;
}

function assertReportExportAllowed({ actorRole, exportType, reportType, exportScope }) {
  if (actorRole === 'viewer') {
    throw new HttpsError('permission-denied', 'This role cannot export reports.');
  }
  if (exportType === 'platformCompanyExport') {
    throw new HttpsError('permission-denied', 'Platform export tracking is not available here.');
  }
  if (exportType === 'auditLogsExport' && !['admin', 'manager'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'This role cannot export audit logs.');
  }
  if (reportType === 'properties' && actorRole !== 'admin') {
    throw new HttpsError('permission-denied', 'This role cannot export properties.');
  }
  if (['teamPerformance', 'auditSummary'].includes(reportType) &&
      !['admin', 'manager'].includes(actorRole)) {
    throw new HttpsError('permission-denied', 'This role cannot export this report.');
  }
  const expectedScope = exportScopeForRole(actorRole);
  if (exportScope !== expectedScope) {
    throw new HttpsError('permission-denied', 'Export scope does not match your role.');
  }
}

function exportScopeForRole(role) {
  if (role === 'admin') {
    return 'companyWide';
  }
  if (role === 'manager') {
    return 'teamOnly';
  }
  if (role === 'salesAgent' || role === 'marketing') {
    return 'assignedOnly';
  }
  return 'restricted';
}

function boundedExportInteger(value, fallback, max) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return fallback;
  }
  return Math.max(0, Math.min(Math.floor(value), max));
}

function safeStringList(value, maxItems, maxLength) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => sanitizeLogText(optionalString(item), maxLength))
    .filter(Boolean)
    .slice(0, maxItems);
}

async function resolveExportActorScope({ companyId, actor, actorUid, actorRole, actorName }) {
  let teamId = optionalString(actor.teamId);
  let teamName = sanitizeLogText(optionalString(actor.teamName), 160);
  let managerId = actorRole === 'manager' ? actorUid : optionalString(actor.managerId);
  let managerName = actorRole === 'manager'
    ? actorName
    : sanitizeLogText(optionalString(actor.managerName), 160);

  if ((!managerId || !managerName || !teamName) && teamId) {
    const teamSnapshot = await db.doc(`companies/${companyId}/teams/${teamId}`).get();
    if (teamSnapshot.exists) {
      const team = teamSnapshot.data() || {};
      teamName = teamName || sanitizeLogText(optionalString(team.name), 160);
      managerId = managerId || optionalString(team.managerId);
      managerName = managerName || sanitizeLogText(optionalString(team.managerName), 160);
    }
  }

  if ((actorRole === 'salesAgent' || actorRole === 'marketing') && !managerId && teamId) {
    const managerSnapshot = await db.collection(`companies/${companyId}/users`)
      .where('role', '==', 'manager')
      .where('teamId', '==', teamId)
      .where('isActive', '==', true)
      .limit(1)
      .get();
    if (!managerSnapshot.empty) {
      const managerDoc = managerSnapshot.docs[0];
      const manager = managerDoc.data() || {};
      managerId = managerDoc.id;
      managerName = managerName || sanitizeLogText(
        optionalString(manager.fullName) || optionalString(manager.email),
        160,
      );
    }
  }

  return { teamId, teamName, managerId, managerName };
}

async function createExportSupervisorNotifications({
  companyId,
  actorUid,
  actorRole,
  actorName,
  actorEmail,
  teamId,
  teamName,
  managerId,
  auditLogId,
  exportType,
  reportType,
  reportTypeLabel,
  exportedModules = [],
  exportedModuleLabels = [],
  dateRangeLabel,
  exportedAtLabel,
  exportScope,
  rowCount,
}) {
  let notifiedAdminCount = 0;
  let notifiedManagerCount = 0;
  const cleanAuditLogId = optionalString(auditLogId);
  const route = cleanAuditLogId ? `/audit-logs?focus=${encodeURIComponent(cleanAuditLogId)}` : '/audit-logs';
  const titleEn = exportType === 'auditLogsExport'
    ? 'Audit logs export'
    : 'Report export';
  const titleAr = exportType === 'auditLogsExport'
    ? 'تصدير سجل النشاط'
    : 'تنبيه تصدير';
  const bodyEn = sanitizeLogText(exportNotificationBody({
    locale: 'en',
    actorName,
    actorRole,
    reportTypeLabel,
    dateRangeLabel,
    exportedAtLabel,
    exportScope,
  }), 220);
  const bodyAr = sanitizeLogText(exportNotificationBody({
    locale: 'ar',
    actorName,
    actorRole,
    reportTypeLabel,
    dateRangeLabel,
    exportedAtLabel,
    exportScope,
  }), 220);
  const metadata = {
    titleEn,
    titleAr,
    bodyEn,
    bodyAr,
    exportType,
    reportType,
    exportedModules,
    exportedModuleLabels,
    exportScope,
    dateRangeLabel,
    exportedAtLabel,
    rowCount,
    actorRole,
    auditLogId: cleanAuditLogId,
  };

  if (exportType !== 'platformCompanyExport') {
    const adminsSnapshot = await db.collection(`companies/${companyId}/users`)
      .where('role', '==', 'admin')
      .where('isActive', '==', true)
      .limit(100)
      .get();
    for (const document of adminsSnapshot.docs) {
      const id = await createCompanyNotification({
        companyId,
        recipientUid: document.id,
        recipientRole: 'admin',
        type: 'systemInfo',
        module: 'exports',
        recordId: reportType,
        recordTitle: reportTypeLabel,
        recordSubtitle: dateRangeLabel,
        route,
        actorUid,
        actorName,
        teamId,
        teamName,
        managerId,
        priority: 'normal',
        actionState: 'none',
        metadata,
        fallbackTitle: titleEn,
        fallbackBody: bodyEn,
      });
      if (id) {
        notifiedAdminCount += 1;
      }
    }
  }

  // Export supervision notifications are Admin-only. Managers can still see
  // operational team activity, but export activity is a company-admin privilege.


  return { notifiedAdminCount, notifiedManagerCount };
}

function exportNotificationBody({
  locale,
  actorName,
  actorRole,
  reportTypeLabel,
  dateRangeLabel,
  exportedAtLabel,
  exportScope,
}) {
  const actor = actorName || actorRole;
  const timeEn = exportedAtLabel ? ` at ${exportedAtLabel}` : '';
  const timeAr = exportedAtLabel ? ` في ${exportedAtLabel}` : '';
  if (locale === 'ar') {
    return `تم تصدير ${reportTypeLabel} بواسطة ${actor} (${exportRoleLabel(actorRole, 'ar')}) ضمن نطاق ${exportScopeLabel(exportScope, 'ar')} لفترة ${dateRangeLabel}${timeAr}.`;
  }
  return `${exportRoleLabel(actorRole, 'en')} ${actor} exported ${reportTypeLabel} for ${dateRangeLabel} (${exportScopeLabel(exportScope, 'en')})${timeEn}.`;
}

function exportRoleLabel(role, locale) {
  if (locale === 'ar') {
    return {
      admin: 'مدير الشركة',
      manager: 'مدير الفريق',
      salesAgent: 'مسؤول المبيعات',
      marketing: 'التسويق',
      viewer: 'مشاهد',
    }[role] || role;
  }
  return {
    admin: 'Admin',
    manager: 'Manager',
    salesAgent: 'Sales Agent',
    marketing: 'Marketing user',
    viewer: 'Viewer',
  }[role] || role;
}

function exportScopeLabel(scope, locale) {
  if (locale === 'ar') {
    return {
      companyWide: 'الشركة',
      teamOnly: 'فريق العمل فقط',
      assignedOnly: 'السجلات المسندة فقط',
      restricted: 'محدود',
    }[scope] || scope;
  }
  return {
    companyWide: 'company-wide',
    teamOnly: 'team-only',
    assignedOnly: 'assigned records',
    restricted: 'restricted',
  }[scope] || scope;
}


function sanitizeNotificationToken(value) {
  const token = requiredString(value, 'token');
  if (token.length < 20 || token.length > 4096 || /[<>\s]/.test(token)) {
    throw new HttpsError('invalid-argument', 'Notification token is invalid.');
  }
  return token;
}

function notificationTokenHash(token) {
  return hashText(token);
}

function sanitizeNotificationTokenPlatform(value) {
  const platform = optionalString(value).toLowerCase();
  if (platform === 'web' || platform === 'android') {
    return platform;
  }
  throw new HttpsError('failed-precondition', 'Notification token platform is not supported yet.');
}

function sanitizeNotificationTokenLocale(value) {
  const locale = optionalString(value).toLowerCase();
  return locale === 'ar' ? 'ar' : 'en';
}

async function deactivateNotificationTokenEverywhere({ tokenHash, keepPath, reason }) {
  const cleanHash = sanitizeHash(tokenHash);
  if (!cleanHash) {
    return;
  }

  const now = FieldValue.serverTimestamp();
  const write = {
    isActive: false,
    updatedAt: now,
    deactivatedAt: now,
    deactivatedReason: sanitizePlainString(optionalString(reason) || 'replaced-token-owner', 120),
  };

  let batch = db.batch();
  let count = 0;
  const commitIfNeeded = async () => {
    if (count === 0) {
      return;
    }
    await batch.commit();
    batch = db.batch();
    count = 0;
  };
  const addWrite = (ref) => {
    if (ref.path === keepPath) {
      return;
    }
    batch.set(ref, write, { merge: true });
    count += 1;
  };

  const companyTokenSnapshots = await db
    .collectionGroup('notification_tokens')
    .where('tokenHash', '==', cleanHash)
    .get();
  for (const document of companyTokenSnapshots.docs) {
    addWrite(document.ref);
    if (count >= 450) {
      await commitIfNeeded();
    }
  }

  const platformRef = db.collection('platform_notification_tokens').doc(cleanHash);
  const platformSnapshot = await platformRef.get();
  if (platformSnapshot.exists) {
    addWrite(platformRef);
  }

  await commitIfNeeded();
}

async function bestEffortDeactivateNotificationTokenEverywhere({
  tokenHash,
  keepPath,
  reason,
  scope,
  companyId,
  uid,
}) {
  try {
    await deactivateNotificationTokenEverywhere({ tokenHash, keepPath, reason });
  } catch (error) {
    // Token registration must not fail just because stale-token cleanup failed.
    // The current token write below is the source of truth. Cleanup can be retried
    // by a later registration/sign-out cycle or an admin maintenance task.
    console.error('notification_token_cleanup_failed', {
      scope: optionalString(scope),
      companyId: optionalString(companyId),
      uid: optionalString(uid),
      code: error && error.code ? error.code : '',
      message: error && error.message ? sanitizeLogText(error.message, 240) : '',
    });
  }
}

async function sendPushForCompanyNotification({
  companyId,
  notificationId,
  notification,
  notificationRef,
}) {
  try {
    if (!isCompanyPushEligible(notification)) {
      return { sent: 0, skipped: true };
    }

    const cleanCompanyId = optionalString(companyId);
    const cleanNotificationId = optionalString(notificationId);
    const recipientUid = optionalString(notification.recipientUid);
    if (!cleanCompanyId || !cleanNotificationId || !recipientUid) {
      return { sent: 0, skipped: true };
    }

    const locked = await reserveNotificationPushAttempt(notificationRef);
    if (!locked) {
      return { sent: 0, duplicate: true };
    }

    const tokensSnapshot = await db
      .collection(`companies/${cleanCompanyId}/notification_tokens`)
      .where('uid', '==', recipientUid)
      .where('isActive', '==', true)
      .where('platform', 'in', ['android', 'web'])
      .limit(50)
      .get();

    const tokenDocs = activePushTokenDocs(tokensSnapshot.docs, {
      companyId: cleanCompanyId,
      uid: recipientUid,
      scope: 'company',
    });
    if (tokenDocs.length === 0) {
      await notificationRef.set({
        push: {
          status: 'skipped',
          skippedReason: 'no-active-token',
          tokenCount: 0,
          successCount: 0,
          failureCount: 0,
          finishedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return { sent: 0, skipped: true };
    }

    const result = await sendNotificationPushBatch({
      tokenDocs,
      message: buildCompanyPushMessage(notification, tokenDocs[0].data()),
    });

    await notificationRef.set({
      push: {
        status: result.successCount > 0 ? 'sent' : 'failed',
        tokenCount: tokenDocs.length,
        successCount: result.successCount,
        failureCount: result.failureCount,
        invalidTokenCount: result.invalidTokenCount,
        webSuccessCount: result.webSuccessCount || 0,
        androidSuccessCount: result.androidSuccessCount || 0,
        tokenResults: (result.tokenResults || []).slice(0, 25),
        sentAt: result.successCount > 0 ? FieldValue.serverTimestamp() : null,
        finishedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return { sent: result.successCount, failed: result.failureCount };
  } catch (error) {
    await markPushFailed(notificationRef, error);
    console.error('company_notification_push_failed', {
      companyId: optionalString(companyId),
      notificationId: optionalString(notificationId),
      type: notification && notification.type ? notification.type : '',
      code: error && error.code ? error.code : '',
      message: error && error.message ? error.message : '',
    });
    return { sent: 0, failed: true };
  }
}

async function sendPushForPlatformNotification({
  notificationId,
  notification,
  notificationRef,
}) {
  try {
    if (!isPlatformPushEligible(notification)) {
      return { sent: 0, skipped: true };
    }

    const cleanNotificationId = optionalString(notificationId);
    if (!cleanNotificationId) {
      return { sent: 0, skipped: true };
    }

    const locked = await reserveNotificationPushAttempt(notificationRef);
    if (!locked) {
      return { sent: 0, duplicate: true };
    }

    const tokensSnapshot = await db
      .collection('platform_notification_tokens')
      .where('isActive', '==', true)
      .where('platform', 'in', ['android', 'web'])
      .limit(100)
      .get();

    const tokenDocs = activePushTokenDocs(tokensSnapshot.docs, {
      scope: 'platformOwner',
    });
    if (tokenDocs.length === 0) {
      await notificationRef.set({
        push: {
          status: 'skipped',
          skippedReason: 'no-active-token',
          tokenCount: 0,
          successCount: 0,
          failureCount: 0,
          finishedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return { sent: 0, skipped: true };
    }

    const result = await sendNotificationPushBatch({
      tokenDocs,
      message: buildPlatformPushMessage(notification, tokenDocs[0].data()),
    });

    await notificationRef.set({
      push: {
        status: result.successCount > 0 ? 'sent' : 'failed',
        tokenCount: tokenDocs.length,
        successCount: result.successCount,
        failureCount: result.failureCount,
        invalidTokenCount: result.invalidTokenCount,
        webSuccessCount: result.webSuccessCount || 0,
        androidSuccessCount: result.androidSuccessCount || 0,
        tokenResults: (result.tokenResults || []).slice(0, 25),
        sentAt: result.successCount > 0 ? FieldValue.serverTimestamp() : null,
        finishedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return { sent: result.successCount, failed: result.failureCount };
  } catch (error) {
    await markPushFailed(notificationRef, error);
    console.error('platform_notification_push_failed', {
      notificationId: optionalString(notificationId),
      type: notification && notification.type ? notification.type : '',
      code: error && error.code ? error.code : '',
      message: error && error.message ? error.message : '',
    });
    return { sent: 0, failed: true };
  }
}

function isCompanyPushEligible(notification) {
  if (!notification || typeof notification !== 'object') {
    return false;
  }
  if (optionalString(notification.deliveryMode) !== 'pushEligible') {
    return false;
  }
  const priority = optionalString(notification.priority);
  if (!['high', 'urgent', 'critical'].includes(priority)) {
    return false;
  }
  const module = optionalString(notification.module);
  if (module === 'exports' || module === 'audit_logs' || module === 'auditLogs') {
    return false;
  }
  const type = optionalString(notification.type);
  if (module === 'company' && type === 'systemInfo') {
    return ['high', 'urgent', 'critical'].includes(priority);
  }
  return [
    'leadAssigned',
    'leadReassigned',
    'taskAssigned',
    'taskReassigned',
    'appointmentAssigned',
    'appointmentReassigned',
    'clientAssigned',
    'clientReassigned',
    'dealAssigned',
    'dealReassigned',
    'appointmentDueSoon',
    'appointmentDueNow',
    'appointmentMissed',
    'teamAppointmentDueSoon',
    'teamAppointmentDueNow',
    'teamAppointmentMissed',
    'followUpOverdue',
    'taskOverdue',
    'leadImportantStatusChanged',
    'dealImportantStatusChanged',
    'dealWon',
    'dealLost',
    'trialEndingSoon',
    'trialExpired',
    'paymentDueSoon',
    'paymentOverdue',
    'paymentGraceEnding',
    'paymentSuspended',
  ].includes(type);
}

function isPlatformPushEligible(notification) {
  if (!notification || typeof notification !== 'object') {
    return false;
  }
  if (optionalString(notification.deliveryMode) !== 'pushEligible') {
    return false;
  }
  const severity = optionalString(notification.severity);
  const type = optionalString(notification.type);
  const importantType = [
    'urgentSupportTicketCreated',
    'platformFunctionFailed',
    'trialExpired',
    'paymentOverdue',
    'paymentGraceEnding',
    'paymentSuspended',
    'storageNearLimit',
  ].includes(type);
  return optionalString(notification.recipientScope) === 'platformOwner' &&
    (severity === 'urgent' || importantType);
}

async function reserveNotificationPushAttempt(notificationRef) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(notificationRef);
    if (!snapshot.exists) {
      return false;
    }
    const data = snapshot.data() || {};
    const push = data.push && typeof data.push === 'object' ? data.push : {};
    if (push.startedAt || push.sentAt || push.status === 'sent') {
      return false;
    }
    transaction.set(notificationRef, {
      push: {
        status: 'sending',
        startedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return true;
  });
}

function activePushTokenDocs(documents, expected) {
  const scope = optionalString(expected.scope);
  const companyId = optionalString(expected.companyId);
  const uid = optionalString(expected.uid);
  return documents.filter((document) => {
    const data = document.data() || {};
    const platform = optionalString(data.platform);
    if (!['android', 'web'].includes(platform)) {
      return false;
    }
    if (data.isActive !== true || optionalString(data.token).length < 20) {
      return false;
    }
    if (scope && optionalString(data.scope) !== scope) {
      return false;
    }
    if (companyId && optionalString(data.companyId) !== companyId) {
      return false;
    }
    if (uid && optionalString(data.uid) !== uid) {
      return false;
    }
    return true;
  });
}

async function sendNotificationPushBatch({ tokenDocs, message }) {
  const tokenPairs = tokenDocs
    .map((document) => ({ document, token: optionalString(document.get('token')) }))
    .filter((item) => item.token);
  const tokens = tokenPairs.map((item) => item.token);
  if (tokens.length === 0) {
    return {
      successCount: 0,
      failureCount: 0,
      invalidTokenCount: 0,
      webSuccessCount: 0,
      androidSuccessCount: 0,
      tokenResults: [],
    };
  }

  const response = await messaging.sendEachForMulticast({
    ...message,
    tokens,
  });
  const invalidTokenRefs = [];
  const tokenResults = [];
  let webSuccessCount = 0;
  let androidSuccessCount = 0;
  response.responses.forEach((item, index) => {
    const pair = tokenPairs[index];
    const document = pair.document;
    const data = document.data() || {};
    const platform = optionalString(data.platform);
    const success = item.success === true;
    if (success && platform === 'web') {
      webSuccessCount += 1;
    }
    if (success && platform === 'android') {
      androidSuccessCount += 1;
    }
    if (!success && isInvalidMessagingTokenError(item.error)) {
      invalidTokenRefs.push(document.ref);
    }
    tokenResults.push({
      tokenHash: optionalString(data.tokenHash) || document.id,
      platform,
      scope: optionalString(data.scope),
      webOrigin: sanitizeShortString(data.webOrigin, 240),
      appVersion: sanitizeShortString(data.appVersion, 40),
      buildNumber: sanitizeShortString(data.buildNumber, 20),
      success,
      errorCode: success ? '' : optionalString(item.error && item.error.code),
      errorMessage: success ? '' : sanitizeLogText(optionalString(item.error && item.error.message), 180),
    });
  });
  await deactivateInvalidPushTokens(invalidTokenRefs);
  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokenCount: invalidTokenRefs.length,
    webSuccessCount,
    androidSuccessCount,
    tokenResults,
  };
}

function buildCompanyPushMessage(notification, tokenData) {
  const locale = notificationLocale(tokenData);
  const text = companyPushText(notification, locale);
  const data = safePushData({
    notificationId: notification.id,
    companyId: notification.companyId,
    module: notification.module,
    recordId: notification.recordId,
    route: notification.route,
    type: notification.type,
    dedupeKey: notification.dedupeKey,
    priority: notification.priority,
    deliveryMode: notification.deliveryMode,
    platform: 'company',
    title: text.title,
    body: text.body,
  });
  const link = webPushLink(data.route, tokenData);
  return {
    notification: {
      title: text.title,
      body: text.body,
    },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'masar_crm_notifications',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    webpush: {
      headers: {
        Urgency: 'high',
        TTL: '3600',
      },
      fcmOptions: {
        link,
      },
      notification: {
        title: text.title,
        body: text.body,
        tag: data.dedupeKey || data.notificationId,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        renotify: true,
        requireInteraction: false,
        data: {
          ...data,
          type: 'MASAR_FCM_NOTIFICATION_CLICK',
          route: data.route || '/notifications',
          url: link,
        },
      },
    },
  };
}

function buildPlatformPushMessage(notification, tokenData) {
  const locale = notificationLocale(tokenData);
  const title = localizedMetadataText(notification.metadata, locale, 'title') ||
    optionalString(notification.title) ||
    'Masar CRM';
  const body = localizedMetadataText(notification.metadata, locale, 'body') ||
    optionalString(notification.message) ||
    'Open Masar CRM to review the latest platform alert.';
  const data = safePushData({
    notificationId: notification.id,
    companyId: notification.companyId,
    module: 'platform',
    recordId: '',
    route: notification.route || '/platform/notifications',
    type: notification.type,
    dedupeKey: notification.dedupeKey || notification.id,
    priority: notification.priority,
    deliveryMode: notification.deliveryMode,
    platform: 'platformOwner',
    title,
    body,
  });
  const link = webPushLink(data.route, tokenData);
  return {
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'masar_crm_notifications',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    webpush: {
      headers: {
        Urgency: 'high',
        TTL: '3600',
      },
      fcmOptions: {
        link,
      },
      notification: {
        title,
        body,
        tag: data.dedupeKey || data.notificationId,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        renotify: true,
        requireInteraction: false,
        data: {
          ...data,
          type: 'MASAR_FCM_NOTIFICATION_CLICK',
          route: data.route || '/platform/notifications',
          url: link,
        },
      },
    },
  };
}

function companyPushText(notification, locale) {
  const metadata = notification.metadata || {};
  const title = localizedMetadataText(metadata, locale, 'title') ||
    optionalString(notification.fallbackTitle) ||
    defaultCompanyPushTitle(notification.type);
  const body = localizedMetadataText(metadata, locale, 'body') ||
    optionalString(notification.fallbackBody) ||
    defaultCompanyPushBody(notification);
  return {
    title: sanitizePushText(title, 120) || 'Masar CRM',
    body: sanitizePushText(body, 220),
  };
}

function localizedMetadataText(metadata, locale, field) {
  const source = metadata && typeof metadata === 'object' ? metadata : {};
  const preferredKey = locale === 'ar' ? `${field}Ar` : `${field}En`;
  const fallbackKey = locale === 'ar' ? `${field}En` : `${field}Ar`;
  return optionalString(source[preferredKey]) || optionalString(source[fallbackKey]);
}

function defaultCompanyPushTitle(type) {
  switch (optionalString(type)) {
    case 'leadAssigned':
    case 'leadReassigned':
      return 'Lead assigned';
    case 'taskAssigned':
    case 'taskReassigned':
      return 'Task assigned';
    case 'appointmentAssigned':
    case 'appointmentReassigned':
      return 'Appointment assigned';
    case 'clientAssigned':
    case 'clientReassigned':
      return 'Client assigned';
    case 'dealAssigned':
    case 'dealReassigned':
      return 'Deal assigned';
    case 'appointmentDueSoon':
    case 'teamAppointmentDueSoon':
      return 'Appointment in 10 minutes';
    case 'appointmentDueNow':
    case 'teamAppointmentDueNow':
      return 'Appointment due now';
    case 'appointmentMissed':
    case 'teamAppointmentMissed':
      return 'Appointment missed';
    case 'taskOverdue':
    case 'followUpOverdue':
      return 'Follow-up overdue';
    case 'dealWon':
      return 'Deal won';
    case 'dealLost':
      return 'Deal lost';
    case 'paymentOverdue':
    case 'paymentSuspended':
      return 'Payment needs attention';
    case 'trialExpired':
      return 'Trial expired';
    case 'trialEndingSoon':
      return 'Trial ending soon';
    default:
      return 'Masar CRM';
  }
}

function defaultCompanyPushBody(notification) {
  const recordTitle = optionalString(notification.recordTitle) ||
    optionalString(notification.recordSubtitle) ||
    'Open Masar CRM';
  return `${recordTitle} needs your attention.`;
}

function notificationLocale(tokenData) {
  return optionalString(tokenData && tokenData.locale).toLowerCase() === 'ar' ? 'ar' : 'en';
}

function safePushData(source) {
  const data = {};
  for (const [key, value] of Object.entries(source || {})) {
    const cleanKey = sanitizePlainString(optionalString(key), 40);
    if (!cleanKey) {
      continue;
    }
    data[cleanKey] = sanitizePushText(value, 240);
  }
  return data;
}

function sanitizePushText(value, maxLength) {
  return optionalString(value)
    .replace(/[<>]/g, '')
    .slice(0, maxLength);
}

function webPushLink(route, tokenData) {
  const cleanRoute = optionalString(route) || '/dashboard';
  const hashRoute = cleanRoute.startsWith('/#') ? cleanRoute : `/#${cleanRoute.startsWith('/') ? cleanRoute : `/${cleanRoute}`}`;
  const origin = optionalString(tokenData && tokenData.webOrigin);
  if (origin.startsWith('https://')) {
    return `${origin}${hashRoute}`;
  }
  return `https://masarcrm.web.app${hashRoute}`;
}

function isInvalidMessagingTokenError(error) {
  const code = optionalString(error && error.code);
  return [
    'messaging/invalid-argument',
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
    'messaging/third-party-auth-error',
  ].includes(code);
}

async function deactivateInvalidPushTokens(tokenRefs) {
  if (!tokenRefs || tokenRefs.length === 0) {
    return;
  }
  let batch = db.batch();
  let count = 0;
  const commitIfNeeded = async () => {
    if (count === 0) {
      return;
    }
    await batch.commit();
    batch = db.batch();
    count = 0;
  };
  for (const ref of tokenRefs) {
    batch.set(ref, {
      isActive: false,
      updatedAt: FieldValue.serverTimestamp(),
      deactivatedAt: FieldValue.serverTimestamp(),
      deactivatedReason: 'fcm-invalid-token',
    }, { merge: true });
    count += 1;
    if (count >= 450) {
      await commitIfNeeded();
    }
  }
  await commitIfNeeded();
}

async function markPushFailed(notificationRef, error) {
  try {
    await notificationRef.set({
      push: {
        status: 'failed',
        errorCode: sanitizePushText(error && error.code ? error.code : '', 80),
        finishedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  } catch (_) {
    // Push metadata is best effort; never let this break notification creation.
  }
}

async function createCompanyNotification({
  companyId,
  recipientUid,
  recipientRole,
  type,
  module,
  recordId,
  recordTitle,
  recordSubtitle,
  route,
  actorUid,
  actorName,
  teamId,
  teamName,
  managerId,
  priority,
  actionState,
  metadata,
  fallbackTitle,
  fallbackBody,
  deliveryMode,
  recipientScope,
  dedupeKey,
}) {
  validateCompanyId(companyId);
  const cleanRecipientUid = optionalString(recipientUid);
  if (!cleanRecipientUid) {
    return null;
  }
  const cleanType = optionalString(type);
  if (!NOTIFICATION_TYPES.has(cleanType)) {
    return null;
  }

  const recipient = await loadCompanyUserSafe(companyId, cleanRecipientUid);
  if (!recipient || recipient.isActive !== true) {
    return null;
  }

  const notificationRef = dedupeKey
    ? db.collection(`companies/${companyId}/notifications`).doc(safeDocumentId(dedupeKey))
    : db.collection(`companies/${companyId}/notifications`).doc();
  if (dedupeKey) {
    const existingNotification = await notificationRef.get();
    if (existingNotification.exists) {
      return notificationRef.id;
    }
  }
  const cleanPriority = NOTIFICATION_PRIORITIES.has(optionalString(priority))
    ? optionalString(priority)
    : 'normal';
  const cleanModule = sanitizePlainString(optionalString(module) || 'system', 40);
  const cleanRecipientRole = optionalString(recipientRole) || optionalString(recipient.role);
  const cleanDeliveryMode = notificationDeliveryModeOrDefault({
    deliveryMode,
    type: cleanType,
    module: cleanModule,
    priority: cleanPriority,
  });
  const cleanRecipientScope = notificationRecipientScopeOrDefault({
    recipientScope,
    type: cleanType,
    recipientRole: cleanRecipientRole,
  });
  const cleanActionState = notificationActionStateOrDefault(actionState, cleanType);
  const cleanDedupeKey = dedupeKey ? safeDocumentId(dedupeKey) : '';
  const cleanRecordId = sanitizePlainString(optionalString(recordId), 160);
  const cleanRecordTitle = sanitizePlainString(
    optionalString(recordTitle) || optionalString(recordSubtitle) || cleanRecordId || 'CRM notification',
    240,
  );
  const now = FieldValue.serverTimestamp();
  const payload = {
    id: notificationRef.id,
    companyId,
    recipientUid: cleanRecipientUid,
    recipientRole: cleanRecipientRole,
    type: cleanType,
    module: cleanModule,
    recordId: cleanRecordId,
    recordTitle: cleanRecordTitle,
    recordSubtitle: sanitizePlainString(optionalString(recordSubtitle), 240),
    route: sanitizePlainString(optionalString(route) || '/dashboard', 240),
    actorUid: sanitizePlainString(optionalString(actorUid), 160),
    actorName: sanitizePlainString(optionalString(actorName), 160),
    teamId: sanitizePlainString(optionalString(teamId), 160),
    teamName: sanitizePlainString(optionalString(teamName), 160),
    managerId: sanitizePlainString(optionalString(managerId), 160),
    priority: cleanPriority,
    deliveryMode: cleanDeliveryMode,
    recipientScope: cleanRecipientScope,
    dedupeKey: cleanDedupeKey,
    isRead: false,
    readAt: null,
    actionState: cleanActionState,
    resolvedAt: null,
    dismissedAt: null,
    createdAt: now,
    updatedAt: now,
    metadata: safeNotificationMetadata(metadata),
    fallbackTitle: sanitizePlainString(optionalString(fallbackTitle), 240),
    fallbackBody: sanitizePlainString(optionalString(fallbackBody), 360),
  };

  await notificationRef.set(payload, { merge: false });
  await sendPushForCompanyNotification({
    companyId,
    notificationId: notificationRef.id,
    notification: payload,
    notificationRef,
  });
  return notificationRef.id;
}


function notificationActionStateOrDefault(actionState, type) {
  const cleanState = optionalString(actionState);
  if (NOTIFICATION_ACTION_STATES.has(cleanState)) {
    return cleanState;
  }
  return notificationTypeNeedsAction(type) ? 'actionNeeded' : 'none';
}

function notificationDeliveryModeOrDefault({ deliveryMode, type, module, priority }) {
  const cleanDeliveryMode = optionalString(deliveryMode);
  if (NOTIFICATION_DELIVERY_MODES.has(cleanDeliveryMode)) {
    return cleanDeliveryMode;
  }
  return defaultCompanyNotificationDeliveryMode({ type, module, priority });
}

function defaultCompanyNotificationDeliveryMode({ type, module, priority }) {
  const cleanType = optionalString(type);
  const cleanModule = optionalString(module);
  const cleanPriority = optionalString(priority);
  if (cleanModule === 'exports') {
    return 'inAppOnly';
  }
  if (cleanModule === 'audit_logs' || cleanModule === 'auditLogs') {
    return 'auditOnly';
  }
  if ([
    'leadAssigned',
    'leadReassigned',
    'taskAssigned',
    'taskReassigned',
    'appointmentAssigned',
    'appointmentReassigned',
    'clientAssigned',
    'clientReassigned',
    'dealAssigned',
    'dealReassigned',
  ].includes(cleanType)) {
    return 'pushEligible';
  }
  if ([
    'appointmentDueNow',
    'appointmentMissed',
    'appointmentCancelled',
    'appointmentRescheduled',
    'teamAppointmentDueNow',
    'teamAppointmentMissed',
    'teamAppointmentCancelled',
    'teamAppointmentRescheduled',
    'dealWon',
    'dealLost',
  ].includes(cleanType)) {
    return 'pushEligible';
  }
  if (['high', 'urgent'].includes(cleanPriority) && [
    'leadImportantStatusChanged',
    'teamLeadStatusChanged',
    'dealImportantStatusChanged',
    'teamDealStageChanged',
    'taskAssigned',
    'taskReassigned',
    'taskStatusChanged',
    'teamTaskStatusChanged',
  ].includes(cleanType)) {
    return 'pushEligible';
  }
  if (cleanModule === 'company' && ['high', 'urgent'].includes(cleanPriority)) {
    return 'pushEligible';
  }
  return 'inAppOnly';
}

function notificationRecipientScopeOrDefault({ recipientScope, type, recipientRole }) {
  const cleanRecipientScope = optionalString(recipientScope);
  if (NOTIFICATION_RECIPIENT_SCOPES.has(cleanRecipientScope)) {
    return cleanRecipientScope;
  }
  const cleanRole = optionalString(recipientRole);
  const cleanType = optionalString(type);
  if (cleanRole === 'admin') {
    return 'admins';
  }
  if (cleanRole === 'manager' || cleanType.startsWith('team')) {
    return 'managerTeam';
  }
  return 'user';
}

function notificationTypeNeedsAction(type) {
  return [
    'followUpDueToday',
    'followUpOverdue',
    'taskDueToday',
    'taskOverdue',
    'appointmentDueSoon',
    'appointmentDueNow',
    'appointmentMissed',
    'teamAppointmentDueSoon',
    'teamAppointmentDueNow',
    'teamAppointmentMissed',
    'dataHealthIssue',
  ].includes(optionalString(type));
}

async function loadCompanyUserSafe(companyId, uid) {
  const cleanUid = optionalString(uid);
  if (!cleanUid) {
    return null;
  }
  const snapshot = await db.doc(`companies/${companyId}/users/${cleanUid}`).get();
  if (!snapshot.exists) {
    return null;
  }
  const data = snapshot.data() || {};
  if (optionalString(data.companyId) && optionalString(data.companyId) !== companyId) {
    return null;
  }
  return data;
}

function safeNotificationMetadata(metadata) {
  const clean = {};
  const source = metadata && typeof metadata === 'object' ? metadata : {};
  for (const [key, value] of Object.entries(source)) {
    const cleanKey = sanitizePlainString(optionalString(key), 80);
    if (!cleanKey) {
      continue;
    }
    if (typeof value === 'string') {
      clean[cleanKey] = sanitizePlainString(value, 240);
    } else if (typeof value === 'number' || typeof value === 'boolean' || value === null) {
      clean[cleanKey] = value;
    }
  }
  return clean;
}

function enumValueOrDefault(value, allowedValues, fallback) {
  const clean = optionalString(value);
  return allowedValues.has(clean) ? clean : fallback;
}

function sanitizeHash(value) {
  return optionalString(value).replace(/[^A-Za-z0-9_-]/g, '').slice(0, 64);
}

function hashText(value) {
  return crypto.createHash('sha256').update(optionalString(value)).digest('hex');
}

function sanitizeLogText(value, maxLength) {
  let clean = optionalString(value);
  clean = clean.replace(/[<>]/g, '');
  clean = clean.replace(
    /(password|token|secret|reset[_-]?link|invitation[_-]?code)\s*[:=]\s*[^\s,;]+/gi,
    '$1=[redacted]',
  );
  clean = clean.replace(
    /https?:\/\/\S*(token|secret|signature|alt=media)\S*/gi,
    '[redacted-url]',
  );
  if (clean.length <= maxLength) {
    return clean;
  }
  return clean.slice(0, maxLength);
}

function sanitizeLogMetadata(metadata) {
  const clean = {};
  const source = metadata && typeof metadata === 'object' && !Array.isArray(metadata)
    ? metadata
    : {};
  for (const [key, value] of Object.entries(source)) {
    const cleanKey = sanitizeLogText(key, 80);
    if (!cleanKey) {
      continue;
    }
    if (/password|token|secret|reset|invitation/i.test(cleanKey)) {
      continue;
    }
    if (typeof value === 'string') {
      clean[cleanKey] = sanitizeLogText(value, 240);
    } else if (typeof value === 'number' || typeof value === 'boolean' || value === null) {
      clean[cleanKey] = value;
    }
  }
  return clean;
}

async function resolveErrorReporterContext({ uid, requestedCompanyId }) {
  const cleanUid = optionalString(uid);
  const isPlatform = await isActivePlatformAdminUid(cleanUid);
  const userRecord = await auth.getUser(cleanUid).catch(() => null);
  let companyId = '';
  let companyName = '';
  let userEmail = sanitizeLogText(optionalString(userRecord && userRecord.email), 180);
  let userRole = isPlatform ? 'platformAdmin' : '';
  const candidateCompanyId = optionalString(requestedCompanyId);

  if (candidateCompanyId && COMPANY_ID_PATTERN.test(candidateCompanyId)) {
    const [companySnapshot, companyUserSnapshot] = await Promise.all([
      db.doc(`companies/${candidateCompanyId}`).get(),
      db.doc(`companies/${candidateCompanyId}/users/${cleanUid}`).get(),
    ]);
    const companyUser = companyUserSnapshot.exists
      ? companyUserSnapshot.data() || {}
      : {};
    const canUseCompany =
      isPlatform ||
      (companyUserSnapshot.exists &&
        optionalString(companyUser.companyId) === candidateCompanyId);
    if (canUseCompany) {
      const company = companySnapshot.exists ? companySnapshot.data() || {} : {};
      companyId = candidateCompanyId;
      companyName = companyNotificationName(candidateCompanyId, company);
      userEmail = sanitizeLogText(optionalString(companyUser.email) || userEmail, 180);
      userRole = sanitizeLogText(optionalString(companyUser.role) || userRole, 80);
    }
  }

  return {
    companyId,
    companyName,
    userEmail,
    userRole,
  };
}

function shouldNotifyOwnerForError({
  severity,
  module,
  occurrenceCount,
  errorCode = '',
}) {
  const cleanModule = optionalString(module).toLowerCase();
  const cleanErrorCode = optionalString(errorCode).toLowerCase();
  const isImportantModule = [...IMPORTANT_ERROR_MODULES].some((important) => {
    return cleanModule === important || cleanModule.includes(important);
  });
  const isPermissionProblem =
    cleanErrorCode === 'permission-denied' ||
    cleanModule.includes('permission');
  if (severity === 'fatal') {
    return true;
  }
  if (severity === 'error' && (occurrenceCount >= 3 || isImportantModule)) {
    return true;
  }
  if (
    severity === 'warning' &&
    occurrenceCount >= 5 &&
    (isImportantModule || isPermissionProblem)
  ) {
    return true;
  }
  return false;
}

async function logCloudFunctionError({
  functionName,
  module,
  companyId = '',
  error,
  metadata = {},
}) {
  try {
    const cleanCompanyId = optionalString(companyId);
    const hasCompanyId = cleanCompanyId && COMPANY_ID_PATTERN.test(cleanCompanyId);
    const companySnapshot = hasCompanyId
      ? await db.doc(`companies/${cleanCompanyId}`).get()
      : null;
    const company = companySnapshot && companySnapshot.exists
      ? companySnapshot.data() || {}
      : {};
    const companyName = hasCompanyId ? companyNotificationName(cleanCompanyId, company) : '';
    const source = 'cloud_function';
    const severity = 'error';
    const cleanModule = sanitizeLogText(optionalString(module) || optionalString(functionName), 100);
    const message = sanitizeLogText(
      optionalString(error && error.message) || `${functionName} failed`,
      500,
    );
    const errorCode = sanitizeLogText(optionalString(error && error.code), 100);
    const shortStack = sanitizeLogText(optionalString(error && error.stack), 1800);
    const stackHash = hashText(`${functionName}|${message}|${shortStack}`).slice(0, 32);
    const logRef = db.collection('platform_error_logs').doc(
      safeDocumentId(`fn_${hashText([
        cleanCompanyId,
        functionName,
        cleanModule,
        stackHash,
      ].join('|')).slice(0, 36)}`),
    );
    const now = FieldValue.serverTimestamp();
    const occurrenceCount = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(logRef);
      if (snapshot.exists) {
        const nextCount = Number(snapshot.get('occurrenceCount') || 0) + 1;
        transaction.set(logRef, {
          id: logRef.id,
          companyId: hasCompanyId ? cleanCompanyId : '',
          companyName,
          source,
          severity,
          module: cleanModule,
          message,
          errorCode,
          stackHash,
          shortStack,
          occurrenceCount: nextCount,
          lastSeenAt: now,
          resolved: false,
          resolvedBy: '',
          resolvedByEmail: '',
          resolvedAt: null,
          metadata: sanitizeLogMetadata({
            functionName,
            ...metadata,
          }),
        }, { merge: true });
        return nextCount;
      }
      transaction.set(logRef, {
        id: logRef.id,
        companyId: hasCompanyId ? cleanCompanyId : '',
        companyName,
        userId: '',
        userEmail: '',
        userRole: '',
        route: '',
        module: cleanModule,
        source,
        severity,
        message,
        errorCode,
        stackHash,
        shortStack,
        occurrenceCount: 1,
        firstSeenAt: now,
        lastSeenAt: now,
        createdAt: now,
        appVersion: '',
        buildNumber: '',
        platform: 'cloud_functions',
        deviceType: 'server',
        userAgent: '',
        timezone: '',
        resolved: false,
        resolvedBy: '',
        resolvedByEmail: '',
        resolvedAt: null,
        ownerNotified: false,
        metadata: sanitizeLogMetadata({
          functionName,
          ...metadata,
        }),
      });
      return 1;
    });

    if (shouldNotifyOwnerForError({ severity, module: cleanModule, occurrenceCount })) {
      await createPlatformNotificationSafely('log_cloud_function_error', {
        id: `platform_error_${logRef.id}`,
        type: 'platformFunctionFailed',
        title: 'Cloud Function failed',
        message: `${cleanModule || functionName}: ${message}`,
        severity: 'warning',
        source: 'system',
        route: '/platform/monitoring',
        companyId: hasCompanyId ? cleanCompanyId : '',
        companyName,
        metadata: {
          logId: logRef.id,
          functionName,
          module: cleanModule,
          occurrenceCount,
          errorCode,
        },
      });
      await logRef.set({
        ownerNotified: true,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    return logRef.id;
  } catch (loggingError) {
    console.error('platform_error_log_failed', {
      functionName,
      code: loggingError && loggingError.code ? loggingError.code : '',
      message: loggingError && loggingError.message ? loggingError.message : '',
    });
    return '';
  }
}

async function createPlatformNotification(payload) {
  const sourcePayload = payload || {};
  const type = optionalString(sourcePayload.type);
  if (!PLATFORM_NOTIFICATION_TYPES.has(type)) {
    return '';
  }
  const requestedSeverity = optionalString(sourcePayload.severity);
  const severity = PLATFORM_NOTIFICATION_SEVERITIES.has(requestedSeverity)
    ? requestedSeverity
    : 'info';
  const requestedSource = optionalString(sourcePayload.source);
  const source = PLATFORM_NOTIFICATION_SOURCES.has(requestedSource)
    ? requestedSource
    : 'platform';
  const cleanDeliveryMode = platformNotificationDeliveryModeOrDefault({
    deliveryMode: sourcePayload.deliveryMode,
    type,
    severity,
  });
  const cleanRecipientScope = platformNotificationRecipientScopeOrDefault(sourcePayload.recipientScope);
  const requestedId = optionalString(sourcePayload.id);
  const notificationRef = requestedId
    ? db.collection('platform_notifications').doc(safeDocumentId(requestedId))
    : db.collection('platform_notifications').doc();
  const now = FieldValue.serverTimestamp();
  const actorId = optionalString(sourcePayload.actorId);
  const notification = {
    id: notificationRef.id,
    type,
    title: sanitizePlainString(optionalString(sourcePayload.title), 240),
    message: sanitizePlainString(optionalString(sourcePayload.message), 500),
    severity,
    deliveryMode: cleanDeliveryMode,
    recipientScope: cleanRecipientScope,
    dedupeKey: requestedId ? safeDocumentId(requestedId) : '',
    isRead: false,
    readAt: null,
    createdAt: now,
    updatedAt: now,
    actorId: sanitizePlainString(actorId, 160),
    actorName: sanitizePlainString(optionalString(sourcePayload.actorName), 160),
    actorEmail: sanitizePlainString(optionalString(sourcePayload.actorEmail), 180),
    companyId: sanitizePlainString(optionalString(sourcePayload.companyId), 160),
    companyName: sanitizePlainString(optionalString(sourcePayload.companyName), 240),
    route: sanitizePlainString(optionalString(sourcePayload.route), 240),
    metadata: safeNotificationMetadata(sourcePayload.metadata || {}),
    source,
  };

  if (requestedId) {
    const snapshot = await notificationRef.get();
    if (snapshot.exists) {
      await notificationRef.set({
        ...notification,
        createdAt: snapshot.get('createdAt') || now,
      }, { merge: true });
      return notificationRef.id;
    }
  }
  await notificationRef.set(notification);
  await sendPushForPlatformNotification({
    notificationId: notificationRef.id,
    notification,
    notificationRef,
  });
  return notificationRef.id;
}

function platformNotificationDeliveryModeOrDefault({ deliveryMode, type, severity }) {
  const cleanDeliveryMode = optionalString(deliveryMode);
  if (PLATFORM_NOTIFICATION_DELIVERY_MODES.has(cleanDeliveryMode)) {
    return cleanDeliveryMode;
  }
  const cleanType = optionalString(type);
  const cleanSeverity = optionalString(severity);
  if (cleanSeverity === 'urgent' || [
    'urgentSupportTicketCreated',
    'platformFunctionFailed',
    'trialExpired',
    'paymentOverdue',
    'paymentGraceEnding',
    'paymentSuspended',
    'storageNearLimit',
  ].includes(cleanType)) {
    return 'pushEligible';
  }
  return 'inAppOnly';
}

function platformNotificationRecipientScopeOrDefault(recipientScope) {
  const cleanRecipientScope = optionalString(recipientScope);
  return PLATFORM_NOTIFICATION_RECIPIENT_SCOPES.has(cleanRecipientScope)
    ? cleanRecipientScope
    : 'platformOwner';
}

async function createPlatformNotificationSafely(contextLabel, payload) {
  try {
    return await createPlatformNotification(payload);
  } catch (error) {
    console.error('platform_notification_create_failed', {
      context: contextLabel,
      type: payload && payload.type ? payload.type : '',
      companyId: payload && payload.companyId ? payload.companyId : '',
      code: error && error.code ? error.code : '',
      message: error && error.message ? error.message : '',
    });
    return '';
  }
}

async function platformActorSummary(uid) {
  const cleanUid = optionalString(uid);
  if (!cleanUid) {
    return { actorId: '', actorName: '', actorEmail: '' };
  }
  const [adminSnapshot, userRecord] = await Promise.all([
    db.doc(`platform_admins/${cleanUid}`).get(),
    auth.getUser(cleanUid).catch(() => null),
  ]);
  const adminData = adminSnapshot.exists ? adminSnapshot.data() || {} : {};
  return {
    actorId: cleanUid,
    actorName: sanitizePlainString(
      optionalString(adminData.fullName) ||
        optionalString(userRecord && userRecord.displayName),
      160,
    ),
    actorEmail: sanitizePlainString(
      optionalString(adminData.email) ||
        optionalString(userRecord && userRecord.email),
      180,
    ),
  };
}


async function notificationActorSummary(companyId, uid) {
  const cleanUid = optionalString(uid);
  if (!cleanUid) {
    return { actorId: '', actorName: '', actorEmail: '' };
  }
  const [platformSummary, companyUserSnapshot, userRecord] = await Promise.all([
    platformActorSummary(cleanUid),
    companyId ? db.doc(`companies/${companyId}/users/${cleanUid}`).get().catch(() => null) : null,
    auth.getUser(cleanUid).catch(() => null),
  ]);
  const companyUser = companyUserSnapshot && companyUserSnapshot.exists
    ? companyUserSnapshot.data() || {}
    : {};
  return {
    actorId: cleanUid,
    actorName: sanitizePlainString(
      optionalString(platformSummary.actorName) ||
        optionalString(companyUser.fullName) ||
        optionalString(userRecord && userRecord.displayName),
      160,
    ),
    actorEmail: sanitizePlainString(
      optionalString(platformSummary.actorEmail) ||
        optionalString(companyUser.email) ||
        optionalString(userRecord && userRecord.email),
      180,
    ),
  };
}

function companyNotificationName(companyId, company) {
  return sanitizePlainString(
    optionalString(company && company.displayName) ||
      optionalString(company && company.name) ||
      optionalString(companyId),
    240,
  );
}

function storageLimitBytes(company) {
  const limits = company && company.limits && typeof company.limits === 'object'
    ? company.limits
    : {};
  const storageMb = Number(limits.storageMb || 0);
  if (!Number.isFinite(storageMb) || storageMb <= 0) {
    return 0;
  }
  return storageMb * 1024 * 1024;
}

function generateInvitationCode() {
  const part = (length) => {
    const bytes = crypto.randomBytes(length);
    let value = '';
    for (let index = 0; index < length; index += 1) {
      value += INVITATION_CODE_CHARS[bytes[index] % INVITATION_CODE_CHARS.length];
    }
    return value;
  };
  return `MASAR-${part(4)}-${part(4)}`;
}

function normalizeInvitationCode(code) {
  const clean = requiredString(code, 'invitationCode').toUpperCase();
  if (!INVITATION_CODE_PATTERN.test(clean)) {
    throw new HttpsError('invalid-argument', 'Invitation code is invalid.');
  }
  return clean;
}

function hashInvitationCode(code) {
  return crypto
    .createHash('sha256')
    .update(normalizeInvitationCode(code), 'utf8')
    .digest('hex');
}

function previewInvitationCode(code) {
  const clean = normalizeInvitationCode(code);
  return `MASAR-****-${clean.split('-').pop()}`;
}

function invitationLink(code, origin) {
  const cleanCode = encodeURIComponent(normalizeInvitationCode(code));
  const cleanOrigin = optionalString(origin).replace(/\/+$/, '');
  const hashRoute = `/#/register-company?code=${cleanCode}`;
  if (!cleanOrigin || !/^https?:\/\/[^<>\s]+$/.test(cleanOrigin)) {
    return hashRoute;
  }
  return `${cleanOrigin}${hashRoute}`;
}

function registrationError(code, key) {
  return new HttpsError(code, key, { key });
}

function logAcceptInvitationStep(step, context, error) {
  const payload = { step };
  const companyId = optionalString(context && context.companyId);
  const adminEmail = normalizeEmail(optionalString(context && context.adminEmail));
  const invitationId = optionalString(context && context.invitationId);
  if (companyId) {
    payload.companyId = companyId;
  }
  if (adminEmail) {
    payload.adminEmail = adminEmail;
  }
  if (invitationId) {
    payload.invitationId = invitationId;
  }
  if (error) {
    payload.errorCode = safeLogErrorCode(error);
    payload.errorMessage = safeLogErrorMessage(error);
    console.error(payload);
    return;
  }
  console.info(payload);
}

async function cleanupInvitationAuthUser(userRecord, context) {
  try {
    await auth.deleteUser(userRecord.uid);
    logAcceptInvitationStep('cleanup_auth_user', context);
  } catch (error) {
    logAcceptInvitationStep('cleanup_auth_user', context, {
      code: safeLogErrorCode(error),
      message: safeLogErrorMessage(error),
    });
  }
}

function safeLogErrorCode(error) {
  return optionalString(error && error.code) || 'unknown';
}

function safeLogErrorMessage(error) {
  if (isRegistrationError(error)) {
    return optionalString(error.message);
  }
  const code = optionalString(error && error.code);
  if (code.startsWith('auth/')) {
    return code;
  }
  return 'unable-to-complete-registration';
}

function isRegistrationError(error) {
  return error instanceof HttpsError &&
    REGISTRATION_ERROR_KEYS.has(optionalString(error.message));
}

function registrationKeyForInvitationStatus(invitation, status) {
  if (status === 'expired') {
    return 'invitation-expired';
  }
  if (status === 'revoked') {
    return 'invitation-revoked';
  }
  if (status === 'used') {
    const storedStatus = optionalString(invitation.status);
    return storedStatus === 'used'
      ? 'invitation-used'
      : 'invitation-limit-reached';
  }
  return 'invitation-invalid';
}

function assertInvitationActiveForRegistration(invitation) {
  if (!invitation) {
    throw registrationError('invalid-argument', 'invitation-invalid');
  }
  const status = invitationPublicStatus(invitation.data);
  if (status !== 'active') {
    throw registrationError(
      'failed-precondition',
      registrationKeyForInvitationStatus(invitation.data, status),
    );
  }
}

function mapAuthUserCreationError(error) {
  const code = optionalString(error && error.code);
  if (code === 'auth/email-already-exists') {
    return registrationError('already-exists', 'admin-email-already-exists');
  }
  if (code === 'auth/invalid-email') {
    return registrationError('invalid-argument', 'invalid-admin-email');
  }
  if (code === 'auth/invalid-password' || code === 'auth/weak-password') {
    return registrationError('invalid-argument', 'weak-password');
  }
  if (code === 'auth/operation-not-allowed') {
    return registrationError('failed-precondition', 'email-password-auth-disabled');
  }
  if (code === 'auth/too-many-requests') {
    return registrationError('resource-exhausted', 'unable-to-create-admin');
  }
  return registrationError('internal', 'unable-to-create-admin');
}

function mapAcceptRegistrationError(error, step) {
  if (isRegistrationError(error)) {
    return error;
  }
  if (error instanceof HttpsError) {
    const message = optionalString(error.message).toLowerCase();
    if (message.includes('invitation')) {
      return registrationError('invalid-argument', 'invitation-invalid');
    }
    if (message.includes('email')) {
      return registrationError('invalid-argument', 'invalid-admin-email');
    }
    if (message.includes('password')) {
      return registrationError('invalid-argument', 'weak-password');
    }
    if (message.includes('company id') && error.code === 'already-exists') {
      return registrationError('already-exists', 'company-id-already-exists');
    }
    if (error.code === 'already-exists') {
      return registrationError('already-exists', 'registration-conflict');
    }
    if (error.code === 'aborted' || error.code === 'failed-precondition') {
      return registrationError('failed-precondition', 'registration-conflict');
    }
    return registrationError('invalid-argument', 'unable-to-complete-registration');
  }
  const code = optionalString(error && error.code);
  if (code.startsWith('auth/')) {
    return mapAuthUserCreationError(error);
  }
  if (isAcceptInvitationFirestoreStep(step)) {
    return registrationError('internal', 'unable-to-create-company');
  }
  return registrationError('internal', 'unable-to-complete-registration');
}

function isAcceptInvitationFirestoreStep(step) {
  return step === 'create_company_docs' ||
    step === 'create_global_user' ||
    step === 'create_company_admin_profile' ||
    step === 'create_membership' ||
    step === 'mark_invitation_used';
}

function invitationUsageRef(invitationId) {
  return db.doc(`platform_invitation_uses/${invitationId}`);
}

async function invitationUseMarkerExists(invitationId) {
  const cleanId = optionalString(invitationId);
  if (!cleanId) {
    return false;
  }
  const snapshot = await invitationUsageRef(cleanId).get();
  return snapshot.exists;
}

async function loadInvitationByCode(code) {
  const codeHash = hashInvitationCode(code);
  const snapshot = await db.collection('platform_invitations')
    .where('codeHash', '==', codeHash)
    .limit(1)
    .get();
  if (snapshot.empty) {
    return null;
  }
  const doc = snapshot.docs[0];
  return { ref: doc.ref, id: doc.id, data: doc.data() || {} };
}

function invitationPublicStatus(invitation) {
  const status = optionalString(invitation.status) || 'active';
  if (status === 'revoked' || status === 'used') {
    return status;
  }
  const expiresAt = dateFromCallableValue(invitation.expiresAt);
  if (expiresAt && expiresAt.getTime() <= Date.now()) {
    return 'expired';
  }
  const usedCount = Number.isInteger(invitation.usedCount) ? invitation.usedCount : 0;
  const maxUses = Number.isInteger(invitation.maxUses) ? invitation.maxUses : 1;
  if (usedCount >= maxUses) {
    return 'used';
  }
  return INVITATION_STATUSES.has(status) ? status : 'invalid';
}

function invitationStatusMessage(status) {
  switch (status) {
    case 'expired':
      return 'invitation-expired';
    case 'used':
      return 'invitation-used';
    case 'revoked':
      return 'invitation-revoked';
    default:
      return 'invitation-invalid';
  }
}

function publicFeatureSummary(features) {
  const source = features && typeof features === 'object' ? features : {};
  const summary = {};
  for (const key of FEATURE_KEYS) {
    summary[key] = source[key] !== false;
  }
  return summary;
}

function emailHint(email) {
  const clean = optionalString(email);
  if (!clean) {
    return '';
  }
  const [name, domain] = clean.split('@');
  if (!name || !domain) {
    return '';
  }
  return `${name.slice(0, 2)}***@${domain}`;
}

function publicInvitationListItem(id, invitation, company = null) {
  const visibleStatus = invitationPublicStatus(invitation);
  const companyData = company || {};
  return {
    id,
    invitationCode: invitation.invitationCode || invitation.codePreview || '',
    codePreview: invitation.invitationCode || invitation.codePreview || '',
    type: invitation.type || 'companyAdmin',
    status: visibleStatus,
    planId: invitation.planId || '',
    planName: invitation.planName || '',
    userLimit: invitation.userLimit || 0,
    storageLimitMb: invitation.storageLimitMb || 0,
    features: publicFeatureSummary(invitation.features || {}),
    locale: invitation.locale || 'en',
    timezone: invitation.timezone || 'Africa/Cairo',
    allowedAdminEmailHint: emailHint(invitation.allowedAdminEmail || ''),
    expiresAt: dateMillis(invitation.expiresAt),
    createdAt: dateMillis(invitation.createdAt),
    createdBy: invitation.createdBy || '',
    acceptedAt: dateMillis(invitation.acceptedAt),
    acceptedBy: invitation.acceptedBy || '',
    acceptedAdminEmail: invitation.acceptedAdminEmail || '',
    companyId: invitation.companyId || '',
    adminUid: invitation.adminUid || '',
    companyName: companyData.displayName || companyData.name || '',
    companyStatus: companyData.status || '',
    companyPlanName: companyData.planName || '',
    companyCreatedAt: dateMillis(companyData.createdAt),
  };
}

function parseFutureDate(value, field) {
  const date = dateFromCallableValue(value);
  if (!date || Number.isNaN(date.getTime())) {
    throw new HttpsError('invalid-argument', `${field} is invalid.`);
  }
  if (date.getTime() <= Date.now()) {
    throw new HttpsError('invalid-argument', `${field} must be in the future.`);
  }
  return date;
}

function parseOptionalDate(value) {
  if (value === null || typeof value === 'undefined' || value === '') {
    return null;
  }
  const date = dateFromCallableValue(value);
  if (!date || Number.isNaN(date.getTime())) {
    throw new HttpsError('invalid-argument', 'Date value is invalid.');
  }
  return date;
}

function dateFromCallableValue(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === 'function') {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (typeof value === 'object' && Number.isInteger(value.seconds)) {
    return new Date(value.seconds * 1000);
  }
  return null;
}

function dateMillis(value) {
  const date = dateFromCallableValue(value);
  return date ? date.getTime() : null;
}

function sanitizeCompanyText(value, field) {
  const clean = requiredString(value, field);
  if (clean.length < 2 || clean.length > 160 || /[<>]/.test(clean)) {
    throw new HttpsError('invalid-argument', `${field} is invalid.`);
  }
  return clean;
}

function sanitizeCompanyId(value) {
  const clean = requiredString(value, 'companyId').toLowerCase();
  validateCompanyId(clean);
  return clean;
}

function slugFromName(name) {
  return optionalString(name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48) || `company-${Date.now()}`;
}

function sanitizeOptionalUrl(value) {
  const clean = optionalString(value);
  if (!clean) {
    return '';
  }
  if (clean.length > 200 || /[<>\s]/.test(clean)) {
    throw new HttpsError('invalid-argument', 'Website is invalid.');
  }
  if (!/^https?:\/\//i.test(clean)) {
    return `https://${clean}`;
  }
  return clean;
}

function firestoreTimestampToIso(value) {
  if (!value || typeof value.toDate !== 'function') {
    return '';
  }
  return value.toDate().toISOString();
}

function safeDocumentId(value) {
  return optionalString(value).replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 180);
}

function enumValue(value, allowedValues, field) {
  const clean = requiredString(value, field);
  if (!allowedValues.has(clean)) {
    throw new HttpsError('invalid-argument', `${field} is invalid.`);
  }
  return clean;
}

function numberValue(value, field) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    throw new HttpsError('invalid-argument', `${field} must be a positive number.`);
  }
  return value;
}

function sanitizePlainString(value, maxLength) {
  const clean = optionalString(value);
  if (clean.length > maxLength || /[<>]/.test(clean)) {
    throw new HttpsError('invalid-argument', 'Text field is invalid.');
  }
  return clean;
}

function optionalCallableTimestamp(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  if (typeof value === 'string') {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new HttpsError('invalid-argument', 'Date field is invalid.');
    }
    return admin.firestore.Timestamp.fromDate(date);
  }
  if (typeof value === 'number') {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new HttpsError('invalid-argument', 'Date field is invalid.');
    }
    return admin.firestore.Timestamp.fromDate(date);
  }
  throw new HttpsError('invalid-argument', 'Date field is invalid.');
}

function requiredCallableTimestamp(value, field) {
  const timestamp = optionalCallableTimestamp(value);
  if (!timestamp) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return timestamp;
}

function validateRole(role) {
  if (!ROLES.has(role)) {
    throw new HttpsError('invalid-argument', 'Role is invalid.');
  }
}
