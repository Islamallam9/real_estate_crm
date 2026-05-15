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

# Current Phase

## Platform Foundation Finishing Pass

The current active work is **Platform Foundation / Multi-company Structure / Simple Super Admin**.

The goal is to make Masar CRM scalable for trial companies without adding subscriptions, billing, AI, public signup, appointments, notifications, or manager/team hierarchy yet.

This phase is about:

- platform admin independent from company membership
- professional `/platform` dashboard
- safe company/user creation through Cloud Functions
- scalable company/user/membership structure
- read-only company dashboard preview for the platform owner
- layout overflow fixes in platform pages
- keeping demo company and trial companies isolated and working

Do not mix this phase with unrelated modules.

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

---

# Current Platform Foundation Status

## New Database Structure

The platform foundation introduces:

```text
platform_admins/{uid}
users/{uid}
users/{uid}/memberships/{companyId}
companies/{companyId}
companies/{companyId}/users/{uid}
```

Existing CRM data remains under:

```text
companies/{companyId}/leads/{leadId}
companies/{companyId}/clients/{clientId}
companies/{companyId}/properties/{propertyId}
companies/{companyId}/tasks/{taskId}
companies/{companyId}/deals/{dealId}
companies/{companyId}/audit_logs/{auditLogId}
```

Do not move existing CRM module collections in this phase.

## Global Users

`users/{uid}` is the global identity document.

It answers:

```text
Who is this Firebase Auth user?
```

It does not mean the user belongs to every company.

Expected fields:

```text
uid
email
fullName
phone
isActive
createdAt
updatedAt
```

## Memberships

`users/{uid}/memberships/{companyId}` links a user to a company.

It answers:

```text
Which company does this user belong to?
What role does this user have in that company?
Is this membership active?
```

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

It answers:

```text
Can this user access this company CRM?
What role does this user have inside this company?
```

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
```

## Correct Relationship

```text
Firebase Auth user
  -> users/{uid}
  -> users/{uid}/memberships/{companyId}
  -> companies/{companyId}/users/{uid}
  -> companies/{companyId}/CRM data
```

## Cloud Functions Added

Callable functions were added in `functions/src/index.js`:

```text
createCompanyWithAdmin
addUserToCompany
setCompanyActiveStatus
setCompanyUserActiveStatus
```

These functions must use Admin SDK server-side logic. Do not recreate these privileged operations as direct client Firestore/Auth writes.

Cloud Run invoker permission was manually granted for these callable functions because Firebase Functions Gen 2 callable services were rejecting requests before function code ran.

Keep function-level auth checks strict:

```text
request.auth required
caller must be active platform admin
```

Public Cloud Run invocation is acceptable only because the callable function code validates Firebase Auth and platform admin status.

## Current Verified Platform State

- `/platform` opens for platform admin.
- Create Company button exists.
- Create Company form opens.
- Company creation works after Cloud Run invoker permission fix.
- Global users appear under `users/{uid}`.
- Each company must still have its own users under `companies/{companyId}/users/{uid}`.
- `users/{uid}/memberships/{companyId}` connects a global user to a company.

## Firestore Backup

A Firestore backup was created before starting platform foundation.

Backup location:

```text
gs://real-escrm-ia-firestore-backups-202605142227/backups/backup-before-platform-foundation
```

The backup operation was successful and exported about 257 Firestore documents.

This backup does not include Firebase Auth users/passwords.

Do not commit `auth-users.json` because it contains password hashes/salts.

---

# Current Known Platform Issues To Fix

## 1. Platform Admin Login Without Company Membership

Current bug:

- Platform owner exists in `platform_admins/{uid}`.
- Platform owner exists in `users/{uid}`.
- If platform owner is removed from `companies/demo_company/users/{uid}`, login fails with “unable to load profile”.

Correct behavior:

```text
Platform admin only:
  login -> /platform
  no company membership required
  no companies/{companyId}/users/{uid} required

Company user only:
  login -> CRM dashboard
  requires users/{uid}/memberships/{companyId}
  requires companies/{companyId}/users/{uid}

Both:
  can access platform and CRM if both conditions exist

Neither:
  blocked with clean localized account-not-linked message
```

Do not fake a companyId for platform-only users. Do not hardcode `demo_company`.

## 2. Platform Dashboard Layout Overflow

Observed issue:

```text
RenderFlex overflowed by 64 pixels on the bottom
```

Known area:

```text
lib/features/platform/presentation/pages/platform_page.dart
```

The platform page/company users list must scroll safely and work on desktop, smaller desktop, tablet-like width, and mobile browser width.

## 3. Professional Platform Dashboard Needed

The `/platform` dashboard should be upgraded to a professional platform management dashboard with real platform data, not fake metrics.

It must follow the Masar CRM visual identity and normal Dashboard quality level.

## 4. Company Dashboard Preview Mode Needed

The platform owner should be able to preview any company’s normal CRM Dashboard in read-only mode.

Do not create a new dashboard design for this preview. Reuse the existing company Dashboard style/layout/widgets as much as safely possible.

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

## Platform Dashboard Scope

The platform dashboard may include:

- platform header
- platform admin name/email if available
- companies list
- selected company details
- company settings display
- company limits display
- company features display
- company users list
- create company action
- add company user action
- company/user activate-deactivate actions
- read-only dashboard preview action

Do not add in this phase:

- subscriptions
- billing
- payments
- public signup
- usage analytics charts
- platform audit logs
- AI
- notifications
- appointments
- manager/team hierarchy

## Platform Dashboard KPIs

Use real data only.

Allowed if data is available cheaply:

- total companies
- active companies
- inactive companies
- trial companies if status exists
- recently created companies
- loaded selected company user count

Do not add fake metrics. Avoid expensive collectionGroup reads unless clearly justified.

## Create Company Form

Required fields:

```text
company name
company ID / slug
first admin full name
first admin email
first admin phone optional
temporary password
locale: en or ar only
timezone: Africa/Cairo default
```

Rules:

- Use `createCompanyWithAdmin` callable function.
- Do not write company/Auth/user/membership docs directly from Flutter.
- Do not store plaintext password in Firestore.
- Show loading state.
- Disable form while submitting.
- Show localized success/error feedback.
- Refresh companies list after success.

## Add User Form

Required fields:

```text
full name
email
phone optional
role: admin, manager, salesAgent, marketing, viewer
temporary password
```

Rules:

- Use `addUserToCompany` callable function.
- Show loading state.
- Disable form while submitting.
- Show localized success/error feedback.
- Refresh company users after success.

## Activate / Deactivate

- Company activate/deactivate must call `setCompanyActiveStatus`.
- Company user activate/deactivate must call `setCompanyUserActiveStatus`.
- Do not hard delete companies or users.
- Use clear loading state for the specific row/action.

---

# Platform Company Dashboard Preview

## Goal

From `/platform`, the platform owner can open any company’s CRM Dashboard in the same style/design as the normal company Dashboard, but in read-only preview mode.

Suggested route:

```text
/platform/companies/{companyId}/dashboard
```

Visible action:

```text
English: Preview dashboard
Arabic: معاينة لوحة الشركة
```

Visible badge:

```text
English: Read-only preview
Arabic: معاينة فقط
```

## Rules

- Do not create a separate fake platform analytics dashboard.
- Reuse the existing CRM Dashboard style/layout/widgets as much as safely possible.
- Use real selected-company data only.
- Platform owner must not be able to create/edit/delete/archive/assign/upload/complete/cancel/change stage/change status from preview mode.
- Hide or disable all normal CRM action buttons in preview mode.
- Do not add the platform owner to `companies/{companyId}/users` just to preview.
- Do not fake a company user profile.
- Do not change normal CRM company session.
- Company users must not access preview routes.
- If rules change, add platform-admin read-only access only where necessary.
- Never add platform-admin write access to CRM records unless they are also a real company user with proper company permissions.

Architecture guidance:

- Prefer reusing existing Dashboard widgets with an explicit mode:

```text
normal company mode
platform read-only preview mode
```

- If direct reuse is risky, create a thin platform wrapper that passes:

```text
companyId
readOnly: true
platformPreview: true
```

- Do not duplicate the whole Dashboard UI if avoidable.
- Firebase reads must remain inside data sources.
- Keep BLoC/Cubit.

---

# Assignee Policy

Admin and Manager should manage and assign, but should not appear as normal assignee options in everyday sales work.

Recommended assignable roles:

```text
Leads: salesAgent + marketing
Clients: salesAgent only
Properties: salesAgent only
Tasks: salesAgent + marketing
Deals: salesAgent only
Reports agent filters: salesAgent-focused
```

Rules:

- Viewer must never appear as assignable.
- Admin/Manager should not appear as normal assignee choices.
- Existing records already assigned to Admin/Manager must still display safely and not break.
- Do not automatically migrate/rewrite existing assignedTo data unless explicitly asked.
- Audit logs must still show Admin/Manager as actors because audit logs track who performed actions.

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

# Firebase Structure

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
companies/{companyId}/leads/{leadId}
companies/{companyId}/clients/{clientId}
companies/{companyId}/properties/{propertyId}
companies/{companyId}/deals/{dealId}
companies/{companyId}/tasks/{taskId}
companies/{companyId}/appointments/{appointmentId}
companies/{companyId}/notifications/{notificationId}
companies/{companyId}/audit_logs/{auditLogId}
```

Rules:

- Never create global CRM collections such as `/leads`, `/clients`, `/properties`, `/tasks`, `/deals`.
- All CRM operations must require company context.
- Never allow cross-company access for normal users.
- Never hard delete CRM business records unless explicitly requested.
- Prefer archive/soft delete.

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

## Multiple Memberships

The structure supports multiple memberships later.

For now:

- if one active membership exists, enter directly
- if multiple active memberships exist, do not build full company switching unless explicitly requested
- do not redesign the database when company switching is added later

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

Never allow in production:

```text
allow read, write: if true;
```

Route guards are UX protection only. Firestore/Storage rules are the real security boundary.

## Platform Security

- Normal users cannot create/update/delete `platform_admins`.
- Normal users cannot create companies directly.
- Normal users cannot create memberships directly.
- Platform actions must use Cloud Functions/Admin SDK.
- Platform admin read-only preview must not imply platform write access to CRM records.

## API Key / Project Security

Firebase client API keys are not passwords, but before real production:

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

# Cloud Functions Rules

Use Cloud Functions only when logic must be trusted server-side.

Current platform functions:

```text
createCompanyWithAdmin
addUserToCompany
setCompanyActiveStatus
setCompanyUserActiveStatus
```

Rules:

- Admin SDK code must stay inside Functions.
- Do not expose Admin SDK keys to Flutter.
- Do not store plaintext passwords in Firestore.
- Do not add service account JSON files to the repo.
- Callable functions must check `request.auth`.
- Callable platform functions must verify active `platform_admins/{uid}`.
- Do not rely only on UI hiding for platform actions.

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
- Failures must keep user on the same page and show clean feedback.
- Audit log writes must not block main actions.
- Platform function calls must show loading and clean errors.

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

---

# Module Status

## Auth

Implemented, but currently being updated for platform admin/company membership session behavior.

## Dashboard

Implemented with real data and real audit log activity.

Must support future read-only platform preview mode without enabling actions.

## Leads

Implemented.

## Clients

Implemented.

## Properties

Implemented with image upload.

## Tasks / Follow-ups

Implemented.

Saved backlog:

- verify related Deal support in task forms/lists
- improve complete/cancel row-level loading if practical
- avoid fragile success handling after await if practical
- do not add manager/team logic yet

## Deals

Implemented.

## Reports

Implemented.

Agent/assignee filters should focus on salesAgent users where the meaning is sales ownership.

## Audit Logs

Implemented and connected to Dashboard Recent Activity.

## Appointments

Not built. Skip for now unless explicitly requested.

## Notifications

Not built. Future phase after platform foundation and stabilization.

## Manager/Team Hierarchy

Not built. Future phase.

## Platform Admin

Current active phase. Needs finishing pass described above.

---

# Future Phase Order

Recommended order from current state:

```text
1. Finish Platform Foundation / Professional Platform Dashboard / Platform Auth Fix
2. Final platform + CRM regression testing
3. Finish assignee policy cleanup if not fully tested/committed
4. Version/app info polish
5. Notifications/reminders foundation
6. Manager/team hierarchy
7. Final security QA: rules tests, API key restrictions, App Check, IAM review
8. Import/export if needed
9. Mobile app packaging if needed
10. Platform subscriptions/billing much later
11. Appointments only if real scheduling becomes necessary
```

Do not add more business modules before the platform foundation is stable.

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

# Manual Test Checklist For Current Platform Phase

1. Platform-only owner:
   - exists in `platform_admins/{uid}`
   - exists in `users/{uid}`
   - does not exist in `companies/demo_company/users/{uid}`
   - login succeeds
   - opens `/platform`
   - companies load

2. Company manager:
   - has membership and company user profile
   - login opens CRM dashboard
   - `/platform` is blocked

3. Sales agent:
   - has membership and company user profile
   - login opens CRM dashboard
   - `/platform` is blocked

4. Create company:
   - platform admin creates a trial company
   - company appears in list
   - Firebase Auth user for first admin is created
   - `companies/{newCompanyId}` exists
   - `companies/{newCompanyId}/users/{adminUid}` exists
   - `users/{adminUid}` exists
   - `users/{adminUid}/memberships/{newCompanyId}` exists

5. New company admin:
   - login succeeds
   - sees empty CRM data
   - cannot see `demo_company` records
   - `/platform` blocked unless explicitly platform admin

6. Add user:
   - platform admin adds user to company
   - user can login
   - user sees only their company

7. Toggle active:
   - deactivating user blocks user cleanly
   - reactivating user restores login
   - deactivating company blocks company login cleanly

8. Platform company dashboard preview:
   - platform owner previews `demo_company` dashboard
   - same CRM Dashboard style is shown
   - read-only badge visible
   - no create/edit/archive/action buttons usable
   - platform owner previews trial company dashboard
   - only selected company data appears
   - company users cannot access preview route

9. Layout:
   - no RenderFlex overflow on `/platform`
   - company users list scrolls safely
   - mobile width usable
   - Arabic RTL layout good

10. CRM regression:
   - demo company Admin/Manager/Sales still open Dashboard, Leads, Clients, Properties, Tasks, Deals, Reports
   - audit logs still work
   - property images still upload for allowed roles

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
