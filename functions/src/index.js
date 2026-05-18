const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const FieldValue = admin.firestore.FieldValue;

const ROLES = new Set(['admin', 'manager', 'salesAgent', 'marketing', 'viewer']);
const COMPANY_ID_PATTERN = /^[a-z0-9][a-z0-9_-]{2,48}[a-z0-9]$/;
const LOCALES = new Set(['en', 'ar']);
const COMPANY_STATUSES = new Set(['active', 'inactive', 'trial']);
const FEATURE_KEYS = new Set([
  'leads',
  'clients',
  'properties',
  'tasks',
  'deals',
  'reports',
  'auditLogs',
  'notifications',
]);
const OPERATIONAL_TEAM_ROLES = new Set(['salesAgent', 'marketing']);
const LEAD_ASSIGNABLE_ROLES = new Set(['salesAgent', 'marketing']);
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

exports.createCompanyWithAdmin = onCall(async (request) => {
  const callerUid = requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const companyName = requiredString(data.companyName, 'companyName');
  const adminFullName = requiredString(data.adminFullName, 'adminFullName');
  const adminEmail = normalizeEmail(requiredString(data.adminEmail, 'adminEmail'));
  const adminPhone = optionalString(data.adminPhone);
  const locale = optionalString(data.locale) || 'en';
  const timezone = optionalString(data.timezone) || 'Africa/Cairo';

  validateCompanyId(companyId);
  validateLocale(locale);
  validateTimezone(timezone);
  await callerUid;

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
    status: 'active',
    isActive: true,
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
      deals: true,
      reports: true,
      auditLogs: true,
      notifications: false,
    },
  });
  writeCompanyUser(batch, companyId, userRecord.uid, {
    fullName: adminFullName,
    email: adminEmail,
    phone: adminPhone,
    role: 'admin',
    isActive: true,
    actorUid: request.auth.uid,
    now,
  });
  writeMembership(batch, userRecord.uid, companyId, {
    companyName,
    role: 'admin',
    isActive: true,
    now,
  });
  await batch.commit();

  return { uid: userRecord.uid, companyId, passwordResetLink };
});

exports.addUserToCompany = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const fullName = requiredString(data.fullName, 'fullName');
  const email = normalizeEmail(requiredString(data.email, 'email'));
  const phone = optionalString(data.phone);
  const role = requiredString(data.role, 'role');

  validateCompanyId(companyId);
  validateRole(role);

  const companyRef = db.doc(`companies/${companyId}`);
  const companySnapshot = await companyRef.get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Company was not found.');
  }
  const company = companySnapshot.data();
  if (company.isActive !== true || company.status === 'inactive') {
    throw new HttpsError('failed-precondition', 'Company is inactive.');
  }

  await enforceUserLimit(companyId, company);

  const { userRecord, passwordResetLink } = await getOrCreateUserForInvitation({
    email,
    displayName: fullName,
  });

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
    now,
  });
  writeCompanyUser(batch, companyId, userRecord.uid, {
    fullName,
    email,
    phone,
    role,
    isActive: true,
    actorUid: request.auth.uid,
    now,
  });
  writeMembership(batch, userRecord.uid, companyId, {
    companyName: company.displayName || company.name || companyId,
    role,
    isActive: true,
    now,
  });
  await batch.commit();

  return { uid: userRecord.uid, companyId, passwordResetLink };
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
  await targetUserRef.update({
    teamId,
    teamName: optionalString(team.name),
    managerId: optionalString(team.managerId),
    managerName: optionalString(team.managerName),
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  });

  await Promise.all([
    refreshTeamMemberCount({ companyId, teamId, actorUid }),
    previousTeamId && previousTeamId !== teamId
      ? refreshTeamMemberCount({ companyId, teamId: previousTeamId, actorUid })
      : Promise.resolve(),
  ]);

  return { companyId, teamId, uid };
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
  await targetUserRef.update({
    teamId: '',
    teamName: '',
    managerId: '',
    managerName: '',
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: actorUid,
  });

  if (previousTeamId) {
    await refreshTeamMemberCount({ companyId, teamId: previousTeamId, actorUid });
  }

  return { companyId, uid };
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

  const modulePolicies = [
    { module: 'leads', titleField: 'fullName', allowedRoles: new Set(['salesAgent', 'marketing']) },
    { module: 'clients', titleField: 'fullName', allowedRoles: new Set(['salesAgent']) },
    { module: 'tasks', titleField: 'title', allowedRoles: new Set(['salesAgent', 'marketing']) },
    { module: 'deals', titleField: 'clientName', fallbackTitleField: 'propertyTitle', allowedRoles: new Set(['salesAgent']) },
    { module: 'properties', titleField: 'title', allowedRoles: new Set(['salesAgent']), onlyWhenAssigned: true },
  ];

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

exports.setCompanyActiveStatus = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const isActive = requiredBoolean(data.isActive, 'isActive');
  validateCompanyId(companyId);

  await db.doc(`companies/${companyId}`).update({
    isActive,
    status: isActive ? 'active' : 'inactive',
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: request.auth.uid,
  });

  return { companyId, isActive };
});

exports.updateCompanyPlatformSettings = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
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
  }
  if (Object.prototype.hasOwnProperty.call(data, 'isActive')) {
    update.isActive = requiredBoolean(data.isActive, 'isActive');
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

  await companyRef.update(update);

  const nextCompanyName = update.displayName || update.name;
  if (nextCompanyName) {
    await updateMembershipCompanyNames(companyId, nextCompanyName);
  }

  return { companyId };
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
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  const isActive = requiredBoolean(data.isActive, 'isActive');
  validateCompanyId(companyId);

  const now = FieldValue.serverTimestamp();
  const status = isActive ? 'active' : 'inactive';
  const batch = db.batch();
  batch.update(db.doc(`companies/${companyId}/users/${uid}`), {
    isActive,
    updatedAt: now,
    updatedBy: request.auth.uid,
  });
  batch.update(db.doc(`users/${uid}/memberships/${companyId}`), {
    isActive,
    status,
    updatedAt: now,
  });
  await batch.commit();

  return { uid, companyId, isActive };
});

exports.setCompanyUserPassword = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  const newPassword = requiredString(data.newPassword, 'newPassword');
  validateCompanyId(companyId);
  validatePassword(newPassword);

  const { companyUserSnapshot, userRecord } = await loadCompanyUserAndAuthUser({
    companyId,
    uid,
  });
  const companyUser = companyUserSnapshot.data() || {};

  await auth.updateUser(uid, { password: newPassword });
  await db.collection('platform_security_alerts').add({
    type: 'platformPasswordChanged',
    companyId,
    targetUid: uid,
    targetEmail: userRecord.email || companyUser.email || '',
    actorUid: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
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
    validateCompanyId(companyId);
    await requireActiveCompanyUser(request, companyId);
    batch.set(db.doc(`companies/${companyId}/users/${uid}`), profileUpdate, { merge: true });
  } else {
    await requireActivePlatformAdmin(request);
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

  if (operation === 'create') {
    await leadRef.set(payload);
  } else {
    await leadRef.set(payload, { merge: true });
  }

  return { companyId, leadId };
});


exports.generateCompanyUserPasswordResetLink = onCall(async (request) => {
  await requireActivePlatformAdmin(request);
  const data = request.data || {};
  const companyId = requiredString(data.companyId, 'companyId');
  const uid = requiredString(data.uid, 'uid');
  validateCompanyId(companyId);

  const { companyUserSnapshot, userRecord } = await loadCompanyUserAndAuthUser({
    companyId,
    uid,
  });
  const companyUser = companyUserSnapshot.data() || {};
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
    actorUid: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { uid, companyId, email, passwordResetLink };
});

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

  const snapshot = await db.doc(`platform_admins/${request.auth.uid}`).get();
  if (!snapshot.exists || snapshot.get('isActive') !== true) {
    throw new HttpsError('permission-denied', 'Platform admin access required.');
  }

  return request.auth.uid;
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

async function getOrCreateUserForInvitation({ email, displayName }) {
  let userRecord;
  let created = false;

  try {
    userRecord = await auth.getUserByEmail(email);
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
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }

    userRecord = await auth.createUser({
      email,
      displayName,
      emailVerified: false,
      disabled: false,
    });
    created = true;
  }

  const passwordResetLink = await auth.generatePasswordResetLink(email);
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
      status: data.isActive ? 'active' : 'inactive',
      createdAt: data.now,
      updatedAt: data.now,
    },
    { merge: true },
  );
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
  if (password.length < 8) {
    throw new HttpsError(
      'invalid-argument',
      'Password must be at least 8 characters.',
    );
  }
}

function normalizeEmail(email) {
  return email.trim().toLowerCase();
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

function positiveInteger(value, field) {
  if (!Number.isInteger(value) || value <= 0 || value > 1000000) {
    throw new HttpsError(
      'invalid-argument',
      `${field} must be a positive whole number.`,
    );
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

  const payload = {
    id: leadId,
    companyId,
    fullName: sanitizePlainString(requiredString(leadInput.fullName, 'fullName'), 160),
    phone: sanitizePlainString(requiredString(leadInput.phone, 'phone'), 80),
    email: sanitizePlainString(optionalString(leadInput.email), 160),
    source,
    sourceDetails: sanitizePlainString(optionalString(leadInput.sourceDetails), 200),
    status,
    priority,
    budgetMin: numberValue(leadInput.budgetMin, 'budgetMin'),
    budgetMax: numberValue(leadInput.budgetMax, 'budgetMax'),
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
    nextFollowUpAt: optionalCallableTimestamp(leadInput.nextFollowUpAt),
    isArchived: existingLead && existingLead.isArchived === true ? true : false,
    archivedAt: existingLead && existingLead.archivedAt ? existingLead.archivedAt : null,
    archivedBy: existingLead ? optionalString(existingLead.archivedBy) : '',
  };

  if (isCreate) {
    payload.createdAt = now;
    payload.createdBy = actorUid;
    payload.isArchived = false;
    payload.archivedAt = null;
    payload.archivedBy = '';
  }

  return payload;
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

function validateRole(role) {
  if (!ROLES.has(role)) {
    throw new HttpsError('invalid-argument', 'Role is invalid.');
  }
}
