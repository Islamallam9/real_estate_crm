# AGENTS.md

## Project Name

Masar CRM

## Project Description

Masar CRM is a production-oriented real estate CRM built with Flutter for web/mobile and Firebase as the backend.

The app is not a demo. Treat it as a real business product that must stay clean, secure, scalable, localized, and maintainable.

---

# Main Technology Stack

## Frontend

- Flutter
- Flutter Web
- Flutter Mobile
- BLoC / Cubit state management only
- go_router for navigation
- Firebase SDKs
- Responsive UI for desktop, tablet, mobile, and mobile browser
- Flutter localization for Arabic and English
- RTL support for Arabic
- LTR support for English

## Backend / Cloud

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions when trusted server-side logic is needed
- Firebase Hosting for Flutter Web
- Firebase Security Rules
- Firebase Cloud Messaging later when notifications are added

---

# Current Active Phase

## Team Assignment Server-side Fix + Manager Visibility Rules

The current active work is to stabilize the recently added Team Hierarchy / Manager Teams phase before starting Assignee Policy Cleanup.

The immediate bug:

- A user created by platform owner can fail to be added to a team until that user logs in once.
- After the new user logs in, adding that same user to a team succeeds.
- Debug proved the client fails at the direct Firestore update to:

```text
companies/{companyId}/users/{uid}
```

- The failing write updates only team assignment fields:

```text
teamId
teamName
managerId
managerName
updatedAt
updatedBy
```

Correct direction:

- Do not keep team member assignment/removal as direct Flutter Firestore writes.
- Move team member assignment/removal to Cloud Functions with Admin SDK.
- Keep Firestore rules strict.
- Do not weaken broad company user update rules just to make team assignment pass.

This phase also defines manager visibility before Assignee Policy Cleanup:

```text
Admin sees all company records.
Manager sees only their team and team-assigned records.
Sales Agent sees only their own assigned work.
Marketing sees only their own assigned work unless a later explicit policy changes it.
Viewer has no operational ownership and must not see management-only sections.
```

Do not start Assignee Policy Cleanup until this phase is validated.

---

# Current Completed Work

## Core CRM Modules

Implemented and tested enough to continue:

- Authentication
- Protected routing
- Dashboard with real data
- Leads
- Clients
- Properties
- Property image upload
- Tasks/follow-ups
- Deals
- Reports
- Real audit logs
- Dashboard Recent Activity from real audit logs

## Properties Phase

Completed:

- Property create/edit/details/list
- Responsive property card grid
- Property image upload using `file_picker`
- Firebase Storage integration
- Storage path:

```text
companies/{companyId}/properties/{propertyId}/images/{fileName}
```

- Property fields:

```text
imageUrls
coverImageUrl
imageStoragePaths
```

- 5 MB image validation aligned with Storage rules
- `image/*` only
- No client-side image compression on Flutter Web
- Longer upload-specific timeouts
- Card image carousel with arrows
- Details page image gallery
- Old properties without images remain backward-compatible

## Security Hardening Phase

Completed and deployed:

- Firestore rules added and deployed
- Storage rules added and deployed
- Company-scoped access
- Active-user checks
- Role checks
- Strict writes
- Blocked hard deletes for CRM business records
- Protected user privilege fields
- Storage image upload/delete restricted by role
- Storage accepts `image/*` only, max 5 MB

Important history:

- The first strict Firestore rules deployment broke Admin/Sales list pages.
- Emergency read/list rules fix was deployed.
- Read/list rules now rely on company-scoped paths, active-user checks, role checks, and assigned-only checks where required.
- Writes remain strict.
- Do not reintroduce strict read/list predicates that require document fields such as `resource.data.companyId == companyId` for company-scoped list queries unless the app queries are guaranteed to match.

## Audit Logs Phase

Completed:

- New feature under `lib/features/audit_logs`
- Domain entity/repository/use case
- Data model/remote data source/repository implementation
- Best-effort audit writes after main CRM action succeeds
- Audit failures must not block saves/loading/snackbars
- Actor snapshot fields are filled from company user profile
- Audit logs are written for:
  - Leads create/update/assign/statusChange/archive
  - Clients create/update/assign/archive
  - Properties create/update/deactivate/imageAdded/imageRemoved
  - Tasks create/update/complete/cancel
  - Deals create/update/stageChange/archive
- Firestore rules allow strict client-side audit log create, Admin/Manager read/list, deny update/delete
- Audit actor fields should cross-check against company user profile in rules where applicable.

## Dashboard Recent Activity

Completed:

- Dashboard Recent Activity now reads real `audit_logs`
- Admin/Manager only start audit log stream
- Sales Agent/Marketing/Viewer do not render/start audit log stream
- Activity items show localized module/action, record title/subtitle, actor name/email fallback, and relative time

## Production Polish Pass

Completed:

- Dashboard density improved
- Excess empty spaces reduced
- Main list pages tightened
- Properties grid gaps reduced
- Safe analyzer warnings cleaned
- Permission-denied stream errors improved in touched surfaces

## Platform Foundation / Multi-company / Super Admin

Completed and validated:

- Platform-only owner login works without company membership.
- `/platform` route works for active platform admins.
- Normal company users are blocked from `/platform`.
- Company creation works through Cloud Functions.
- Add user works through Cloud Functions.
- Activate/deactivate company and user works.
- Read-only company dashboard preview works.
- Platform preview reads work through Firestore rules.
- Arabic/English localization and RTL/LTR work.
- CRM regression passed after platform foundation validation.

## Platform Dashboard Polish + Platform Settings Management

Implemented and validated enough to continue:

- Professional `/platform` dashboard structure.
- Platform sidebar/mobile section navigation.
- Company details, users, settings, features, limits, and preview sections.
- Company settings update through Cloud Functions.
- Feature toggles and limits are stored in company metadata.
- User limit is enforced by platform add-user flow.
- Feature flags affect the CRM app behavior.
- Disabled features should appear disabled/locked in navigation, not silently hidden, except audit logs may be hidden.

## Password Management + Login Activity + Dashboard Visibility Fix

Implemented and needs normal validation/deployment hygiene:

- User self-service change password using current password, reauthentication, and `updatePassword`.
- Platform owner manual password change through Cloud Function.
- Platform owner reset-link generation through Cloud Function.
- Login activity recording through Cloud Function with server-side IP capture.
- Last-login summary fields on company/global/platform user docs.
- Profile/platform user list can show last-login summary.
- Sales/Marketing/Viewer should not see unassigned leads dashboard sections.
- Admin/Manager and platform preview keep management visibility where appropriate.
- Forgot Password remains hidden from login because many CRM emails are internal/fake.

## Team Hierarchy / Manager Teams

Implemented but still being stabilized:

- New `lib/features/teams` feature.
- New route:

```text
/teams
```

- Team Management navigation for Admin/Manager only.
- Company-scoped teams collection:

```text
companies/{companyId}/teams/{teamId}
```

- User profile team snapshot fields:

```text
teamId
teamName
managerId
managerName
```

- Admin can create/edit teams, assign active Manager users, add/move/remove Sales Agent and Marketing members, activate/deactivate teams, and view team KPIs.
- Manager has read-only My Team view.
- Manager should only see teams/users where `managerId` matches the manager UID.
- Sales/Marketing/Viewer have no Team Management navigation and direct `/teams` access is blocked.
- Firestore rules include teams read/write validation and tightened company user profile reads for manager team visibility.

Current known Team bug:

- New platform-created users may fail team assignment until first login.
- The fix is to move team assignment/removal to Cloud Functions using Admin SDK.

---

# Current Database Structure

## Platform / Global

```text
platform_admins/{uid}
users/{uid}
users/{uid}/memberships/{companyId}
companies/{companyId}
```

## Company CRM

```text
companies/{companyId}/users/{userId}
companies/{companyId}/teams/{teamId}
companies/{companyId}/leads/{leadId}
companies/{companyId}/clients/{clientId}
companies/{companyId}/properties/{propertyId}
companies/{companyId}/deals/{dealId}
companies/{companyId}/tasks/{taskId}
companies/{companyId}/appointments/{appointmentId}
companies/{companyId}/notifications/{notificationId}
companies/{companyId}/audit_logs/{auditLogId}
companies/{companyId}/login_activity/{eventId}
```

Rules:

- Never create global CRM collections such as `/leads`, `/clients`, `/properties`, `/tasks`, `/deals`.
- All CRM operations must require company context.
- Never allow cross-company access for normal users.
- Never hard delete CRM business records unless explicitly requested.
- Prefer archive/soft delete.

## Global Users

`users/{uid}` is the global identity document.

Expected fields include:

```text
uid
email
fullName
phone
isActive
createdAt
updatedAt
lastLoginAt optional
lastLoginIp optional
lastLoginUserAgent optional
lastLoginPlatform optional
lastLoginBrowser optional
lastLoginDeviceType optional
lastLoginLocale optional
lastLoginTimezone optional
```

## Memberships

`users/{uid}/memberships/{companyId}` links a user to a company.

Expected fields:

```text
companyId
companyName
role
isActive
status
createdAt
updatedAt
```

## Company Users

`companies/{companyId}/users/{uid}` is the actual CRM profile for that company.

Expected fields:

```text
uid
companyId
fullName
email
phone
role
isActive
createdAt
createdBy
updatedAt
updatedBy
teamId
teamName
managerId
managerName
lastLoginAt optional
lastLoginIp optional
lastLoginUserAgent optional
lastLoginPlatform optional
lastLoginBrowser optional
lastLoginDeviceType optional
lastLoginLocale optional
lastLoginTimezone optional
```

Newly created users should receive default team fields immediately:

```text
teamId: ''
teamName: ''
managerId: ''
managerName: ''
```

Do not rely on the user logging in once to normalize these fields.

## Correct Relationship

```text
Firebase Auth user
  -> users/{uid}
  -> users/{uid}/memberships/{companyId}
  -> companies/{companyId}/users/{uid}
  -> companies/{companyId}/CRM data
```

---

# Team Hierarchy Rules

## Team Collection

Use:

```text
companies/{companyId}/teams/{teamId}
```

Team document fields:

```text
id
companyId
name
description optional
managerId
managerName
managerEmail
isActive
memberCount
createdAt
createdBy
updatedAt
updatedBy
```

## Roles

Admin:

- sees all teams
- sees all company users
- can create/edit/deactivate teams
- can assign/change manager
- can add/move/remove Sales Agent and Marketing members
- can see users without teams

Manager:

- sees only their own team
- sees only users where `managerId == managerUid`
- read-only Team Management view unless explicitly expanded later
- cannot create/edit/deactivate teams
- cannot manage other managers' teams

Sales Agent / Marketing:

- cannot access Team Management
- may see their own team/manager label if useful
- sees only their own work unless future business policy changes this

Viewer:

- cannot access Team Management
- should not be assigned as operational team member
- should not see management-only sections

## Team Member Eligibility

Operational team members are:

```text
salesAgent
marketing
```

Not eligible as normal operational team members:

```text
admin
manager
viewer
```

Admin/Manager may still appear as actors in audit logs because audit logs track who performed an action, not who owns the record.

## Team Assignment Must Be Server-side

Team member assignment/removal must use Cloud Functions because it is trusted business logic.

Required callable functions:

```text
assignUserToTeam
removeUserFromTeam
```

Server validation for `assignUserToTeam`:

- `request.auth` required
- caller must be active company Admin in `companies/{companyId}/users/{request.auth.uid}`
- `companyId` valid
- team exists under `companies/{companyId}/teams/{teamId}`
- team is active
- target user exists under `companies/{companyId}/users/{uid}`
- target user is active
- target role is `salesAgent` or `marketing`
- team snapshots are taken from the team doc server-side, not trusted from Flutter
- previous team member count refreshed if moving between teams
- new team member count refreshed

Server validation for `removeUserFromTeam`:

- `request.auth` required
- caller must be active company Admin
- target user exists under the same company
- target user is an operational member
- previous team count refreshed

Firestore writes from these functions:

```text
teamId
teamName
managerId
managerName
updatedAt
updatedBy
```

Rules:

- Do not use direct Flutter Firestore writes for member assignment/removal.
- Do not broaden Firestore user update rules just to allow this action.
- Keep company user update rules strict.
- Functions use Admin SDK.

---

# Business Visibility Policy

## Main Rule

```text
Admin sees all.
Manager sees only their team.
Sales Agent sees only their own assigned work.
Marketing sees only their own assigned work unless explicitly changed later.
Viewer has restricted/read-only visibility and must not see management-only data.
```

## Leads Visibility

Admin:

- all company leads
- unassigned leads
- all teams' leads
- all managers' leads

Manager:

- leads assigned to the manager directly
- leads assigned to users in the manager's team
- leads with `managerId == managerUid`
- leads with `teamId` matching one of the manager's teams
- no other managers' leads
- no global company-wide leads
- no unassigned leads by default

Sales Agent:

- leads where `assignedTo == currentUserId`
- no unassigned leads
- no other sales agents' leads
- no other teams' leads

Marketing:

- leads assigned to the marketing user
- no company-wide unassigned leads unless a later explicit marketing intake policy is added

Viewer:

- no operational assignment ownership
- no unassigned leads management information

## Unassigned Leads

Unassigned leads are management-level data.

Default visibility:

```text
Admin only
```

Do not show unassigned lead count, section title, empty placeholder, stream/query, or quick action to Sales Agent, Marketing, or Viewer.

Manager should not see unassigned leads by default. Add a future explicit policy if Admin wants certain managers to handle unassigned queues.

## Clients / Properties / Tasks / Deals Visibility

Until a dedicated assignee policy pass finalizes everything, keep the same principle:

```text
Admin: all company records
Manager: records assigned to manager or manager's team
Sales Agent: own assigned records
Marketing: own assigned records where module allows marketing
Viewer: restricted/read-only according to current permission rules
```

## Record Snapshot Fields

When assigning records after Team Hierarchy exists, prefer storing snapshot fields:

```text
teamId
teamName
managerId
managerName
assignedTo
assignedToName
```

This avoids heavy joins and makes dashboard, filters, reports, and rules easier.

Old records without team fields must remain backward-compatible.

---

# Assignee Policy

Assignee Policy Cleanup is the next major feature phase after Team Assignment Server-side Fix + Manager Visibility Rules is validated.

Goal:

- Admin/Manager can manage and assign records.
- Admin/Manager should not appear as normal assignee options in everyday sales work.
- Viewer must never appear as assignable.
- Existing records already assigned to Admin/Manager must still display safely.
- Do not automatically migrate/rewrite existing `assignedTo` data unless explicitly requested.
- Audit logs must still show Admin/Manager as actors.

Recommended assignable roles:

```text
Leads: salesAgent + marketing
Clients: salesAgent only
Properties: salesAgent only
Tasks: salesAgent + marketing
Deals: salesAgent only
Reports agent filters: salesAgent-focused
```

After Team Hierarchy, assignee dropdowns should also consider team scope:

```text
Admin: can assign to any eligible user in company
Manager: can assign only to eligible users in their own team
Sales/Marketing/Viewer: no assignment management unless explicitly allowed
```

---

# Platform Admin Rules

## Platform Admin Identity

`platform_admins/{uid}` identifies users allowed to open `/platform`.

A platform admin is different from a company admin.

```text
Company admin role != platform admin
```

Normal company admins must not access `/platform` unless they also have an active `platform_admins/{uid}` doc.

## Platform Admin Must Not Need Company Membership

Platform admins must be able to access `/platform` without:

```text
users/{uid}/memberships/{companyId}
companies/{companyId}/users/{uid}
```

If a platform admin also has memberships, CRM access may work too, but platform access must not depend on company profile loading.

## Platform Actions

Platform privileged actions must use Cloud Functions/Admin SDK.

Current/expected platform functions include:

```text
createCompanyWithAdmin
addUserToCompany
setCompanyActiveStatus
setCompanyUserActiveStatus
updateCompanyPlatformSettings
setCompanyUserPassword
generateCompanyUserPasswordResetLink
recordLoginActivity
validateUploadedImageMagicBytes
```

Rules:

- Admin SDK code must stay inside Functions.
- Do not expose Admin SDK keys to Flutter.
- Do not store plaintext passwords in Firestore.
- Do not store reset links in Firestore.
- Do not log passwords, tokens, or reset links.
- Do not add service account JSON files to the repo.
- Callable functions must check `request.auth`.
- Callable platform functions must verify active `platform_admins/{uid}`.
- Do not rely only on UI hiding for platform actions.

---

# Auth and Session Rules

## Normal Company User Flow

```text
Firebase Auth sign-in
  -> read users/{uid}/memberships
  -> resolve active companyId
  -> read companies/{companyId}
  -> read companies/{companyId}/users/{uid}
  -> start CRM session
```

Company users must have:

- active global user if used by resolver
- active membership
- active company
- active company user profile

## Platform Admin Flow

```text
Firebase Auth sign-in
  -> read platform_admins/{uid}
  -> if active, allow /platform
```

Platform-only users do not need company membership.

Do not block `/platform` because company profile loading fails.

## Password Management

Login page Forgot Password should remain hidden while many CRM users use internal/fake emails.

Supported password tools:

- logged-in user changes their own password from Profile/Settings using current password and `updatePassword`
- platform owner manually sets company user password via Cloud Function
- platform owner generates password reset link via Cloud Function and copies/sends it manually

Rules:

- Do not store passwords in Firestore.
- Do not log passwords.
- Do not store or log reset links.
- Real password reset emails need real inboxes; generated reset links shown to platform owner can be sent manually.

## Login Activity

Login activity is security-sensitive.

Expected behavior:

- `recordLoginActivity` callable records successful login.
- IP address captured server-side from request metadata/headers.
- Flutter may send coarse client info such as user agent/platform/locale/timezone/app version.
- No passwords/tokens/reset links are stored.

Access:

- Platform admins can read platform/company login activity where rules allow.
- Company Admin/Manager may read company login activity only if allowed.
- Normal users can see only their own last-login summary.
- Sales/Marketing/Viewer must not read other users' login history.

---

# Security Rules

Security rules are part of the application logic.

Rules must protect:

- company isolation
- platform admin isolation
- user active status
- role permissions
- read permissions
- write permissions
- delete permissions
- privilege escalation
- manager/team visibility
- protected login activity and last-login fields

Never allow in production:

```text
allow read, write: if true;
```

Route guards are UX protection only. Firestore/Storage rules are the real security boundary.

## Rules Guidance

- Normal users cannot create/update/delete `platform_admins`.
- Normal users cannot create companies directly.
- Normal users cannot create memberships directly.
- Platform actions must use Cloud Functions/Admin SDK.
- Platform admin read-only preview must not imply platform write access to CRM records.
- Manager list queries must include filters matching rules, because Firestore rules are not filters.
- If Manager can read only team members, the query must filter by `managerId == request.auth.uid` or equivalent allowed scope.
- Do not reintroduce strict read/list predicates that break company-scoped collection queries.
- Do not weaken user update rules for team assignment; use Cloud Functions instead.

## API Key / Project Security

Firebase client API keys are not passwords, but before real production:

- use `String.fromEnvironment(...)` in `firebase_options.dart`
- use `--dart-define-from-file=config/firebase.local.json` locally
- do not commit `config/firebase.local.json` or production secrets
- restrict Web API key to Firebase Hosting/custom domains
- restrict Android key to package name and SHA certificates before mobile release
- restrict iOS key to final bundle ID before App Store release
- enable MFA on Google/Firebase/GitHub accounts
- remove unnecessary IAM owners
- never commit service account JSON/private keys/secrets

## App Check Later

Firebase App Check should be added later for stronger abuse protection.

App Check is not a replacement for Security Rules.

---

# Error Handling and User Feedback

Do not show only generic messages such as:

```text
Failed to update
Something went wrong
```

Generic errors are acceptable only as a final fallback when the app truly cannot classify the problem.

Expected behavior:

- Map Firebase/Functions errors to realistic, actionable, localized messages.
- Keep technical details out of normal user-facing messages.
- Do not expose security internals.
- Log useful debug details in development if needed, but do not log passwords, tokens, reset links, or private data.
- AppFeedback should receive specific messages whenever possible.

Examples of better messages:

```text
You do not have permission to add this user to a team.
This user is inactive. Activate the user before assigning them to a team.
This team is inactive. Activate the team first.
This manager already owns an active team.
This user is not eligible for team membership.
The selected company is inactive.
This feature is disabled for this company.
The record was changed or removed. Refresh and try again.
The connection was interrupted. Check your internet and try again.
The reset link could not be generated for this user.
The current password is incorrect.
Your session expired. Sign in again and retry.
```

Arabic messages must be natural and direct, not literal machine translations.

Recommended error mapping:

```text
permission-denied -> clear permission message
unauthenticated -> ask user to sign in again
failed-precondition -> explain the business condition that failed
invalid-argument -> explain the invalid field/input
not-found -> selected record/user/company no longer exists
already-exists -> duplicate entity message
unavailable/deadline-exceeded -> network/server temporary issue
aborted -> data changed, refresh and retry
unknown -> fallback with retry guidance
```

For Team Management specifically, avoid only saying:

```text
Team update failed
```

Prefer:

```text
User could not be added because they are inactive.
User could not be added because they are not eligible for team membership.
User could not be added because you do not have permission.
User could not be added because the team is inactive.
```

---

# Architecture Defaults

- Use feature-first Clean Architecture.
- Use BLoC/Cubit only.
- Do not use Riverpod, Provider directly, GetX, MobX, or other state management packages.
- UI must call BLoC/Cubit.
- BLoC/Cubit must call use cases.
- Use cases must call repositories.
- Repositories must call data sources.
- Firebase calls must stay inside data sources only.
- Domain entities must not depend on Firebase SDKs.
- Data models handle Firebase mapping.
- Presentation widgets remain UI-focused.
- Keep business rules out of widgets whenever practical.

Recommended feature structure:

```text
lib/features/<feature>/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    cubit/
    pages/
    widgets/
```

---

# Localization / Internationalization

Supported languages:

```text
Arabic: ar
English: en
```

Rules:

- All visible UI text must be localized.
- Do not hardcode visible strings.
- Add keys to `app_en.arb` and `app_ar.arb`.
- Update generated localization files if the repo stores them.
- Arabic must use RTL correctly.
- English must use LTR correctly.
- Use direction-aware widgets when needed:
  - `EdgeInsetsDirectional`
  - `AlignmentDirectional`
  - `PositionedDirectional`
- Do not leave English fallback text in Arabic mode.
- Keep Arabic professional and natural.
- Keep ARB commas valid.

---

# UI / Visual Identity

Masar CRM should feel like a warm premium real estate CRM.

Use:

- cream / warm off-white workspace
- premium amber primary action
- white/warm cards
- soft beige-gray borders
- charcoal/dark brown text
- calm semantic colors
- professional spacing
- practical business UI

Avoid:

- generic purple/blue AI dashboard style
- glassmorphism
- huge shadows
- glowing cards
- random gradients
- decorative AI-looking effects
- fake SaaS template look
- flashy animation
- bouncing animation
- infinite animation loops
- auto-scrolling activity feeds

All modules should feel like one product.

Future UI work must reuse the same:

- page header style
- search/filter pattern
- AppButton style
- AppDropdown style
- AppStatusBadge style
- feedback/snackbar style
- circular loading pattern
- mobile card behavior
- table/card density
- warm Masar palette

---

# Loading, Saving, and Feedback

- Network/database actions must show loading feedback.
- Use circular progress indicators for loading states.
- Prefer overlay loading where existing content can remain visible.
- Forms should disable fields while saving.
- Save/update buttons must show circular loading until backend request completes.
- Pages/dialogs/sheets must not close before success.
- Failures must keep user on the same page and show clean, specific feedback.
- Audit log writes must not block main actions.
- Platform function calls must show loading and clean errors.
- Use `context.mounted` before showing feedback after async work.
- Avoid using stale BuildContext from disposed widgets.

---

# Responsive Rules

Every important screen should be reviewed on:

- desktop browser
- smaller desktop width
- tablet-ish width
- mobile browser
- Arabic RTL
- English LTR

Rules:

- Avoid horizontal overflow.
- Avoid RenderFlex overflow.
- Use scrollable containers for long lists.
- Do not fix web by breaking mobile.
- Do not fix mobile by making desktop empty.
- Keep useful content visible quickly.
- Reusable buttons must handle Arabic RTL labels without text painter/render overflow.

---

# Module Status

## Auth

Implemented with platform/company resolution and password-management work.

## Dashboard

Implemented with real data and real audit log activity.

Must respect feature flags and visibility policy.

Unassigned leads must not be visible to Sales Agent, Marketing, or Viewer.

## Leads

Implemented.

Next visibility cleanup should align Manager access to team scope.

## Clients

Implemented.

Next visibility cleanup should align Manager access to team scope.

## Properties

Implemented with image upload.

## Tasks / Follow-ups

Implemented.

Saved backlog:

- verify related Deal support in task forms/lists
- improve complete/cancel row-level loading if practical
- avoid fragile success handling after await if practical
- later align task visibility/assignment to team hierarchy

## Deals

Implemented.

Next visibility cleanup should align Manager access to team scope.

## Reports

Implemented.

Reports agent filters should focus on salesAgent ownership and later manager/team scope.

## Audit Logs

Implemented and connected to Dashboard Recent Activity.

## Appointments

Not built. Skip for now unless explicitly requested.

## Notifications

Not built. Future phase after stabilization.

## Team Management

Implemented but current stabilization phase must move member assignment/removal to Cloud Functions.

## Platform Admin

Implemented and being polished/stabilized with platform security and feature management.

---

# Future Phase Order

Recommended order from current state:

```text
1. Team Assignment Server-side Fix + Manager Visibility Rules
2. Validate Team Hierarchy / Manager Teams
3. Assignee Policy Cleanup
4. Version/app info polish
5. Notifications/reminders foundation
6. Final security QA: rules tests, API key restrictions, App Check, IAM review
7. Import/export if needed
8. Mobile app packaging if needed
9. Platform subscriptions/billing much later
10. Appointments only if real scheduling becomes necessary
```

Do not add more business modules before team/security visibility is stable.

---

# Deployment Workflow

Follow this order for major changes:

```text
Develop
Analyze
Test locally
Deploy Firestore rules if changed
Deploy Functions if changed
Build web
Deploy Hosting
Verify production
Commit/push when stable, or commit before deploy only if explicitly preferred by user
```

Do not deploy Hosting before rules/functions required by the new UI are ready.

Mention clearly when a change needs:

- `flutter pub get`
- `npm install` inside `functions`
- `firebase deploy --only firestore:rules`
- `firebase deploy --only functions`
- `firebase deploy --only hosting`

---

# Repository Hygiene

Do not commit:

```text
.env
.env.local
config/firebase.local.json
config/firebase.prod.json
serviceAccountKey.json
firebase-adminsdk*.json
google credentials JSON files
private keys
auth-users.json
functions/node_modules
zip files
patch files
temporary seed files unless explicitly requested
```

It is okay to commit:

```text
firebase.json
firestore.rules
storage.rules
pubspec.yaml
pubspec.lock
lib/firebase_options.dart if it only uses String.fromEnvironment(...)
functions/package.json
functions/package-lock.json
functions/src/index.js
docs/platform_seed_example.json
```

Before committing, check:

```text
git status
git diff --cached --stat
```

LF/CRLF warnings on Windows are usually not the main issue.

---

# Codex Operational Defaults

## Working Branch

- Work on branch `dev`.
- Do not work directly on `main`.
- Do not assume changes are committed.
- Keep each task focused.

## Command Usage

Do not run CLI commands unless explicitly requested.

Do not run:

- `flutter analyze`
- `flutter pub get`
- `flutter gen-l10n`
- `dart format`
- `flutter run`
- `flutter build`
- Firebase deploy commands
- Git commands
- destructive commands
- production data modification commands

The user will run checks locally unless they explicitly allow commands.

Read-only inspection of directly relevant files is allowed.

## File Editing Rules

- Do not touch unrelated files.
- Do not format broad folders.
- Do not run broad formatting like `dart format lib`.
- If formatting is needed, format only changed files.
- If a reusable widget API is unknown, inspect the existing widget file before using it.
- Do not create duplicate UI components if an existing reusable component can be used.
- Do not leave temporary zip, patch, exported Auth JSON, generated seed files, or test files inside the repo unless explicitly requested.

## Reporting Format

After every task, report:

```text
Files changed:
- ...

What was broken / missing:
- ...

What was implemented:
- ...

How to test:
- ...

Assumptions:
- ...

Remaining issues:
- ...
```

If relevant, also include:

```text
Security/rules changes:
Cloud Functions changes:
Critical warnings:
```

If there are no remaining issues, write:

```text
Remaining issues:
- None known
```

---

# Manual Test Checklist For Current Team Stabilization Phase

1. Platform owner creates a new company user.
2. Do not login as the new user.
3. Login as company Admin.
4. Open Team Management.
5. Add the newly created Sales Agent/Marketing user to an active team.
6. It must succeed without requiring the target user to login first.
7. Remove the user from the team.
8. Move the user between teams.
9. Manager sees only their own team and team members.
10. Sales/Marketing/Viewer cannot access `/teams`.
11. Admin still sees all teams and all company users.
12. Admin sees unassigned leads if intended.
13. Manager does not see all company leads.
14. Sales/Marketing/Viewer do not see unassigned leads.
15. Arabic RTL works.
16. English LTR works.
17. Dark mode works.
18. Mobile width has no overflow.
19. Errors are specific and useful, not only “failed to update”.

---

# Final Product Standard

Masar CRM should feel like a serious internal business application used by real sales teams and platform operators.

It should not feel like:

- a tutorial app
- a generated template
- a fake SaaS dashboard
- a decorative AI-generated UI
- a prototype with no security
- a messy Flutter demo

Build carefully. Make the smallest clean change that supports the scalable product direction.

---

# Versioning / App Info Rule

For every major phase, stabilization package, security fix, or visible product update, update the app version shown in Settings before handing the build back.

Required files:

```text
pubspec.yaml
lib/core/constants/app_constants.dart
```

Rules:

- Keep `pubspec.yaml` `version:` aligned with `AppConstants.appVersion` and `AppConstants.appBuildNumber`.
- Use semantic versions for product phases, for example `1.2.0+2`.
- Show the version/build in Settings > About app.
- Mention the version bump clearly in the final report.
- Do not change versions for tiny text-only fixes unless explicitly requested.
