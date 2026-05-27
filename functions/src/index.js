const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const FieldValue = admin.firestore.FieldValue;


exports.getServerTime = onCall(() => {
  const now = new Date();
  return {
    now: now.toISOString(),
    nowMillis: now.getTime(),
  };
});


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
const PLATFORM_NOTIFICATION_SOURCES = new Set([
  'platform',
  'support',
  'invitation',
  'company',
  'user',
  'storage',
  'system',
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
    const password = requiredString(data.password, 'password');
    const confirmPassword = optionalString(data.confirmPassword);
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
  const temporaryPassword = optionalString(data.temporaryPassword);
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

  return result;
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
      metadata: {
        status: 'trialExpired',
        trialEndsAt: trialEndsAt.toISOString(),
      },
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
        metadata: {
          status: 'trialExpired',
          trialEndsAt: trialEndsAt.toISOString(),
        },
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
  if (!isPlatformActor) {
    enforceUserManagementFeature(company, false);
    assertCompanyAdminCanManageTarget({
      actorUid,
      targetUid: uid,
      targetUser,
      nextActive: isActive,
    });
  }
  if (!isActive) {
    await revokeRefreshTokensForUid(uid);
  }

  const now = FieldValue.serverTimestamp();
  const status = isActive ? 'active' : 'inactive';
  const batch = db.batch();
  batch.update(db.doc(`companies/${companyId}/users/${uid}`), {
    isActive,
    updatedAt: now,
    updatedBy: actorUid,
  });
  batch.update(db.doc(`users/${uid}/memberships/${companyId}`), {
    isActive,
    status,
    updatedAt: now,
  });
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
  const newPassword = requiredString(data.newPassword, 'newPassword');
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

  if (operation === 'create') {
    await leadRef.set(payload);
  } else {
    await leadRef.set(payload, { merge: true });
  }

  await createLeadAssignmentNotifications({
    companyId,
    leadId,
    operation,
    actorUid,
    actor,
    existingLead,
    payload,
    assignee,
  }).catch(() => undefined);

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

  await createAppointmentTimingNotifications({
    companyId,
    appointmentId,
    appointment: payload,
    now: admin.firestore.Timestamp.now(),
  }).catch(() => undefined);

  return { companyId, appointmentId };
});


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
    if (optionalString(after.companyId) !== companyId || optionalString(after.id) !== taskId) {
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
    if (optionalString(after.companyId) !== companyId || optionalString(after.id) !== clientId) {
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
    if (optionalString(after.companyId) !== companyId || optionalString(after.id) !== dealId) {
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
  const cleanTemporaryPassword = optionalString(temporaryPassword);
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
    password.length < 8 ||
    !/[A-Za-z]/.test(password) ||
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
    metadata: {
      milestone,
      trialEndsAt: endIso,
      trialStartedAt: trialStartedAt ? trialStartedAt.toISOString() : '',
    },
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
      metadata: {
        milestone,
        trialEndsAt: endIso,
        trialStartedAt: trialStartedAt ? trialStartedAt.toISOString() : '',
      },
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
  if (scheduleChanged && status === 'scheduled') {
    status = 'rescheduled';
  }

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
    outcomeNotes: sanitizePlainString(optionalString(appointmentInput.outcomeNotes), 4000),
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
  if (!nextStatus || previousStatus === nextStatus) {
    return;
  }
  const userType = appointmentStatusNotificationType(nextStatus);
  const teamType = teamAppointmentStatusNotificationType(nextStatus);
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
    priority: nextStatus === 'cancelled' || nextStatus === 'missed' ? 'high' : 'normal',
    metadata: {
      previousStatus,
      newStatus: nextStatus,
      assignedToName: optionalString(after.assignedToName),
      scheduledAt: firestoreTimestampToIso(after.scheduledAt),
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
      newStatus: nextStatus,
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
      recipientRole: '',
      type: 'teamLeadStatusChanged',
      dedupeKey: `lead_status_${leadId}_${previousStatus}_${nextStatus}_manager_${managerId}`,
    });
  }
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
      priority,
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
      newStatus: nextStatus,
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
  metadata,
  fallbackTitle,
  fallbackBody,
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
    recipientRole: optionalString(recipientRole) || optionalString(recipient.role),
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
    isRead: false,
    readAt: null,
    createdAt: now,
    updatedAt: now,
    metadata: safeNotificationMetadata(metadata),
    fallbackTitle: sanitizePlainString(optionalString(fallbackTitle), 240),
    fallbackBody: sanitizePlainString(optionalString(fallbackBody), 360),
  };

  await notificationRef.set(payload, { merge: false });
  return notificationRef.id;
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
  return notificationRef.id;
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
    summary[key] = source[key] === true;
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
