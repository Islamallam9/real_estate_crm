# AGENTS.md — Masar CRM

## Project identity

Masar CRM is a production-grade real estate CRM SaaS built with Flutter Web/Mobile and Firebase.

Product identity:
- English name: `Masar CRM`
- Arabic name: `مسار`
- Meaning: path / journey / workflow.
- Business scope: real estate CRM for the full journey from lead → client → appointment → property → deal → task/follow-up.
- Live Hosting: `https://masarcrm.web.app`
- Current active branch: `dev`
- Working path: `C:\Users\islam\Desktop\real_estate_crm`

Current release context:
- Latest known deployed/stable release: around `2.8.0+38`.
- Always verify `pubspec.yaml`, `AppConstants.appVersion`, and `AppConstants.appBuildNumber` before bumping.
- Latest huge release included production hardening, protected sessions, trial server-time security, manual payment follow-up, platform owner controls, Excel export, observability, notification improvements, profile image fixes, Reports/Support tab fixes, and performance/query-limit cleanup.
- The current active phase is **Release Lock QA**. Do not start new features until release-lock QA passes.

Important Hosting/cache note:
- If the live web app still shows an older version after deploy, test with a cache-busting query param:
  - `https://masarcrm.web.app/?v=<build-number>`
- Use hard refresh `Ctrl + Shift + R` or Incognito after each Flutter Web deploy.

---

## Absolute rules for Codex / assistant work

These rules are mandatory.

- Follow this `AGENTS.md` first.
- Work on `dev` unless the user explicitly says otherwise.
- Do not run Flutter, Firebase, Git, npm, Dart, analyzer, build, deploy, commit, push, or migrations unless the user explicitly allows.
- Do not commit, push, deploy, or run migrations unless the user explicitly asks.
- Do not use `git add .` blindly.
- Do not stage temp files, zip files, local patches, screenshots, generated throwaway files, or local editor folders.
- Do not claim `flutter analyze`, build, deploy, rules deploy, or Functions deploy passed unless it was actually run or the user confirmed it.
- Keep every change scoped to the user’s exact request.
- Do not touch unrelated files.
- Do not add new features during stabilization/release-lock phases.
- Do not rewrite large parts of the app unless the user explicitly asks.
- Do not weaken Firestore rules to make UI pass.
- Firestore rules are not filters.
- Do not query broad company data for restricted roles and then filter client-side.
- Do not broaden role permissions silently.
- Do not hide security problems behind UI checks.
- Use BLoC/Cubit only.
- Keep Firebase access inside data sources or Cloud Functions, not widgets.
- All visible UI text must be localized through ARB/l10n.
- Support Arabic RTL and English LTR in every UI change.
- Follow the existing Masar design system. Do not create generic admin-template UI.
- Be direct, precise, and honest in reports.
- No emojis.

---

## User preferences

- The user prefers strong mega prompts for Codex over many small prompts.
- The user often asks for required files only, not a full ZIP.
- The user wants practical real-market CRM behavior, not decorative-only features.
- The user dislikes generic/AI-looking designs.
- The user wants direct reports with exact files changed, exact risks, and exact deploy requirements.
- The user is strict about role security and permissions.
- The user expects app design consistency across all modules.
- The user expects Arabic wording to be natural, not machine-translated.
- The user expects all new phases to be treated seriously when they affect money, security, access, roles, exports, or customer data.

---

## Architecture rules

Use feature-first Clean Architecture:

```text
lib/features/<feature>/
  data/
  domain/
  presentation/
```

Layer direction:

```text
UI → Cubit/BLoC → Use Case → Repository → Data Source → Firebase/API
```

Rules:
- Use `flutter_bloc`, `bloc`, `equatable` patterns already in the repo.
- Do not introduce Riverpod, Provider, GetX, MobX, or other state-management patterns.
- Keep Firebase calls inside data sources or Cloud Functions.
- Cubits should call use cases/repositories, not Firestore directly.
- Widgets should not call Firestore/Storage/Auth/Functions directly.
- Keep business logic out of widgets when practical.
- Prefer existing reusable widgets and app patterns.
- Use safe `mounted` checks after async UI callbacks.
- Dispose controllers, timers, focus nodes, and subscriptions.
- Avoid launching async work repeatedly from `build()`.

---

## Localization and directionality

Supported languages:
- English
- Arabic

Rules:
- All visible UI text must be localized through `app_en.arb`, `app_ar.arb`, and generated l10n files.
- Do not hardcode visible UI strings in widgets.
- Do not mix Arabic UI with English notifications/messages.
- Arabic must be natural and business-friendly.
- Use RTL-safe layout:
  - `EdgeInsetsDirectional`
  - `AlignmentDirectional`
  - `PositionedDirectional`
  - `BorderRadiusDirectional` where appropriate
- Test mixed Arabic/English/numbers in RTL.
- For old/new values in Arabic, prefer:
  - `من old إلى new`
  with directional isolation where needed.
- User-facing server-side notifications from Cloud Functions must also respect target language where possible.

---

## Masar design system rules

The whole app, including Platform Owner, must follow one Masar CRM design language.

Use:
- warm premium surfaces
- professional CRM card layout
- compact density
- consistent section headers
- consistent search/filter/action bars
- consistent action button positions
- consistent segmented tabs
- consistent status badges
- consistent empty/loading/error states
- consistent snackbar/feedback style
- consistent dark/light behavior
- RTL/LTR-safe spacing and alignment

Do not:
- create generic admin-template screens
- create a separate-looking Platform UI
- use random gradients/glassmorphism/AI-looking effects
- place action buttons randomly
- create huge blank cards
- create huge repeated bordered boxes
- make mobile screens scroll too much when compact layout is possible
- use old/GNav-style tabs that hide labels or show weird ellipsis

Tabs:
- Use the shared Masar segmented tab style.
- Reports, Support, Appointments, Dashboard, and Platform workspace tabs must look consistent.
- On mobile, avoid squeezing many tabs into one unreadable full-width row; use scroll/segmented behavior that keeps names readable.

Loading:
- Page/panel-level loading should use the Masar logo loader where applicable.
- Button/action-level loading can stay compact circular progress.
- Existing content should remain visible with overlay loading when possible.

Brand/logo:
- Use Masar logo/mark consistently.
- In dark mode, keep a light backing where needed so black logo strokes remain visible.
- Do not let logo invert into invisible black-on-black.
- Do not use generic apartment icons where the Masar logo should appear.

---

## Versioning rule

For every major user-facing, security, data, platform, trial, payment, export, Functions, or rules phase:
- Update `pubspec.yaml` version.
- Update `AppConstants.appVersion`.
- Update `AppConstants.appBuildNumber`.
- Mention the version update in the final report.

Do not bump version for tiny compile-only fixes unless the user asks.

Latest known deployed/stable release:
- Around `2.8.0+38`.
- Verify in files before bumping again.

---

## Firebase structure

Company-scoped data lives under:

```text
companies/{companyId}/...
```

Important company collections:
- `users`
- `leads`
- `clients`
- `properties`
- `tasks`
- `deals`
- `appointments`
- `notifications`
- `audit_logs`
- `teams`
- `payment_history`

Platform/global collections include:
- `platform_admins/{uid}`
- `users/{uid}`
- `users/{uid}/memberships/{companyId}`
- `companies/{companyId}`
- `platform_invitations/{invitationId}`
- `platform_invitation_uses/{invitationId}`
- `platform_notifications/{notificationId}`
- `platform_error_logs/{logId}` or current observability collection structure

---

## Security rules principles

Firestore rules are not filters.

Never:
- use broad reads and filter client-side for restricted roles
- use `allow read, write: if true`
- weaken rules to make UI pass
- expose cross-company data
- expose platform data to normal company users
- let normal company users write platform/payment/privilege fields
- let client-side UI be the source of truth for money/access decisions

Protect sensitive fields:
- `role`
- `isActive`
- `companyId`
- `teamId`
- `teamName`
- `managerId`
- `managerName`
- `email` when controlled by privileged flow
- login activity/IP/device fields
- password/reset-link fields
- `mustChangePassword`
- `passwordSetupMethod`
- platform admin fields
- invitation hashes/secret invitation codes
- trial/payment access fields
- payment history records
- payment reminder state

Privileged platform operations must go through Cloud Functions/Admin SDK.

If rules change:
- report exact reason
- keep them strict
- mention deploy requirement:
  - `firebase deploy --only firestore:rules`

---

## Role visibility and permission policy

### Platform owner/admin

- Can access `/platform` without company membership.
- Can manage companies through safe platform flows.
- Can manage company users through safe functions.
- Can preview company dashboards read-only.
- Can access platform monitoring, platform notifications, platform support inbox, company export, and payment follow-up.
- Must not be forced into normal company dashboard if no company membership exists.
- Platform export and payment management must remain platform-owner only.

### Company Admin

- Sees all company CRM records.
- Sees unassigned leads.
- Sees all company teams and users.
- Can assign/reassign records to eligible users across the company.
- Sees company-wide dashboard, reports, and recent activity.
- Can access Company User Management `/users`.
- Can create company users according to current policy.
- Cannot access `/platform`.
- Cannot write payment fields directly.
- Cannot bypass trial/payment block.

### Manager

- Sees own team records only.
- Can assign/reassign only to eligible users in own team.
- Dashboard and reports must be team-only.
- Recent Activity must be team-only.
- Must not see other managers’ teams, records, or activity.
- Must not access `/users` or Platform.
- Must not query all company data and filter client-side.

### Sales Agent

- Sees only own assigned records.
- Must not see all company leads/clients/tasks/deals.
- Must not see unassigned leads.
- Must not see other users’ records.
- Can update own assigned records only where current policy allows.
- Must not access `/users` or Platform.

### Marketing

- Sees only own assigned records unless an explicit policy changes this.
- Must not see unassigned leads by default.
- Must not access other users’ records through search, filters, reports, exports, or direct routes.
- Must not access `/users` or Platform.

### Viewer

- Restricted/read-only according to current policy.
- Must not appear as assignable.
- Must not access team/platform/user-management/payment data unless explicitly allowed.

---

## Assignment policy

Final assignable-role policy:

Leads:
- `salesAgent`
- `marketing`

Tasks:
- `salesAgent`
- `marketing`

Clients:
- `salesAgent`

Deals:
- `salesAgent`

Properties:
- `salesAgent` only if property assignment exists in current business flow.
- Do not over-restrict property viewing if properties are intended as shared inventory.

Admin and Manager can manage assignment but should not appear as normal operational assignee options.
Viewer must never appear as assignable.

Assigned records should store snapshots where module supports assignment:
- `assignedTo`
- `assignedToName`
- `assignedToEmail` where supported
- `teamId`
- `teamName`
- `managerId`
- `managerName`

When creating/reassigning:
- Copy snapshots from `companies/{companyId}/users/{uid}`.
- Do not trust manually typed team/manager values from UI.
- If `assignedTo` is empty, team/manager snapshot fields should be empty.
- If `assignedTo` is not empty, snapshots should match the selected assignee profile.

Old records:
- Must still load safely.
- Do not run destructive migration automatically.
- When edited/reassigned, refresh snapshots safely from assignee profile.

---

## Account switching and protected sessions

This has been a major production hardening area.

Rules:
- Protected module streams must wait for a fresh loaded `UserProfile`.
- `profile.uid` must match current Firebase Auth user uid.
- Company metadata must be active/usable for access.
- Protected scopes/Cubits should be keyed by `companyId + uid + role + teamId + managerId` where relevant.
- On logout/account switch, stale profile/company/session state must be cleared.
- Old Cubits/streams must be disposed and rebuilt.
- Public routes after logout must not start protected company/platform streams.
- Do not show old Admin data after logging in as Sales/Manager.
- Hot restart must not be required to clear state.

Protected routes/pages to watch:
- Dashboard
- Leads
- Clients
- Properties
- Tasks
- Deals
- Appointments
- Reports
- Export
- Notifications
- Support
- Team Management
- Company Users
- Platform pages

---

## Trial system rules

Trial system is money-sensitive. Treat it as critical.

Current behavior:
- Trial can be set from:
  - platform invitation creation
  - manual company creation
  - editing company status/settings
- Trial duration supports:
  - minutes
  - hours
  - days
- Trial duration is customizable.
- Trial end time must be calculated on the server, not browser/client time.
- Dashboard remaining time must use server-time logic, not `DateTime.now()` from laptop.
- Changing laptop/device time must not fake remaining trial time.
- Expired trial access must be blocked by Firestore rules using `request.time`.
- Scheduler is cleanup/notification only, not the only enforcement layer.
- Trial company can be converted to active/paid without deleting data.
- Trial badge must appear immediately in company dashboard after company becomes trial.
- Trial expired company must show clean localized block message.

Trial notifications/warnings:
- Company admin gets warnings around:
  - 1/3 of trial period
  - 2/3 of trial period
  - final warning before expiry
- Warning dialogs must not dismiss by tapping outside; user must acknowledge.
- Saved company notifications should be localized Arabic/English.
- Platform owner gets near-ending and expired trial alerts.
- No duplicate notification spam every minute.
- Use reminder/checkpoint markers.

Arabic wording examples:
- `تنبيه فترة التجربة`
- `فترة التجربة أوشكت على الانتهاء`
- `انتهت فترة التجربة`
- `تبقى تقريبًا {remaining} على انتهاء فترة التجربة. يرجى التواصل مع الدعم أو الاشتراك للاستمرار في استخدام مسار.`
- `انتهت فترة التجربة. يرجى التواصل مع الدعم أو الاشتراك لإعادة تفعيل الشركة.`

---

## Payment follow-up rules

Payment follow-up is implemented for direct client payments.

This is not:
- Stripe
- online billing
- payment gateway
- online invoice payment

It is:
- platform-owner-controlled manual payment tracking and company access control.

Current payment metadata on `companies/{companyId}`:
- `paymentStatus`
- `nextPaymentDueAt`
- `lastPaymentAt`
- `paymentAmount`
- `paymentCurrency`
- `paymentCycle`
- `paymentNotes`
- `gracePeriodEndsAt`
- `suspendedAt`
- `suspendedReason`
- `paymentUpdatedAt`
- `paymentUpdatedBy`
- `paymentReminderState`

Payment statuses:
- `paid`
- `dueSoon`
- `overdue`
- `gracePeriod`
- `suspended`
- `trial`
- `trialExpired`
- `inactive`

Payment history:
- stored under `companies/{companyId}/payment_history`
- platform-owner readable only
- normal company users must not write it

Cloud Functions:
- `markCompanyPaymentPaid`
- `extendCompanyPaymentDueDate`
- `updateCompanyPaymentStatus`
- `runPaymentReminderSweep`

Access behavior:
- Paid/active company works normally.
- Due soon works normally while owner sees reminders.
- Overdue does not automatically delete data.
- Grace-period company works until `gracePeriodEndsAt` using server/rules time.
- Suspended company is blocked from CRM access.
- Trial/trialExpired behavior remains separate.
- Reactivating/switching to paid keeps all company data.

Rules:
- Payment writes must go through Cloud Functions/Admin SDK.
- Company Admin/Manager/Sales/Marketing/Viewer must not write payment fields.
- Money/access decisions must not depend on client/laptop time.
- Existing active legacy companies with missing payment fields must remain usable if `isActive == true`.
- Missing payment metadata must not crash Platform UI.
- Missing payment metadata must not accidentally block old clients.

Reminder logic:
- Owner reminders for:
  - due in 7 days
  - due tomorrow
  - overdue
  - grace ending soon
  - suspended/reactivated/marked paid
- Store reminder markers to avoid repeated spam.
- Company admin payment notices must be localized and clean, with no raw technical status.

---

## Platform owner rules

Platform Dashboard must follow the normal Masar design system.

Platform owner can:
- access `/platform` without company membership
- manage companies
- manage company users through safe functions
- create/revoke invitations
- preview company dashboard read-only
- view platform notifications
- view platform support inbox
- view platform monitoring/error logs
- export selected company data to Excel
- manage trial/payment status
- suspend/reactivate companies

Platform owner cannot:
- weaken tenant role rules
- bypass tenant data isolation from normal user UI
- expose platform controls to company roles

Platform UI requirements:
- Must look like Masar CRM, not generic admin UI.
- Company data chips/cards must be aligned and compact.
- Payment section must remain compact.
- Top bar and company selector must match the app design.
- Error monitoring must include copy buttons and avoid exposing secrets/tokens.
- Platform export should use professional Excel, not JSON.

---

## Platform owner Excel export rules

Platform owner export is Excel-only, not JSON.

Owner can choose sections:
- users
- leads
- clients
- properties
- tasks
- deals
- appointments
- notifications
- audit logs
- teams

Rules:
- Export remains platform-owner only through Cloud Function/Admin SDK.
- Normal company roles do not get platform export access.
- Output must be professional:
  - Summary sheet
  - section/data sheets
  - clean headers
  - filters
  - readable widths
  - frozen headers where supported
  - Arabic RTL where supported
  - no black/garbage cells
  - no raw UID/Firestore-looking visible main columns
  - no image URLs
  - no storage paths
  - no token URLs
  - no `createdBy`/`updatedBy` as primary visible columns unless intentionally hidden/excluded
- Use localized readable status/role/module/action labels when practical.

---

## Reports export rules

Normal Reports Export is Excel-only.

No PDF.
No preview.

Workflow:
1. Choose report type.
2. Choose filters.
3. Choose columns.
4. Generate Excel.

Design:
- Export is a real Reports tab.
- Export tab should be compact on mobile.
- Report types should be a grid, not long vertical cards.
- Export tab should be last on mobile if that is the current design.
- Use existing Masar filters/action button style.

Role scope:
- Admin company-wide.
- Manager own team only.
- Sales/Marketing assigned-only where allowed.
- Viewer blocked/restricted.
- No broad restricted-role fetch then client filtering.

Excel quality:
- Summary/Data sheets
- frozen/styled headers
- filters
- readable widths
- phone as text
- date/currency formatting
- Arabic RTL
- no raw enum names
- no raw Firestore-looking IDs unless intentionally required

---

## Notifications rules

Current notification system includes:
- notification bell
- dropdown panel
- notification center
- attention-needed section
- platform notifications
- trial/payment/support/error notifications

Rules:
- Attention needed in dropdown must be collapsible.
- Each attention item can be cleared from current session.
- Each normal notification can be cleared/marked read.
- Mark all read must remain working.
- Notification streams must not start when feature is disabled or profile/session is invalid.
- Notification text must match Arabic/English target user/company/platform locale.
- No duplicate spam for trial/payment reminders.
- Do not use notification UI as a replacement for rules/access control.

---

## Support rules

Support Center exists:
- Support
- Feedback
- My Requests
- Contact

Platform support inbox exists.

Rules:
- Contact actions use WhatsApp/email icons according to design.
- Do not show raw phone/email if design says icons only.
- Web external link opener must work.
- Support/feedback status updates should notify ticket owner through company notifications.
- Platform support should be limited/paginated where practical.

---

## Observability / error monitoring rules

Platform Observability exists:
- `platform_error_logs`
- owner-only Monitoring UI
- KPI cards, filters, detail sheet, mark-resolved flow
- sanitized metadata
- global Flutter/Bloc error reporting
- selected Cloud Function error logging helper

Cloud Functions include:
- `reportClientError`
- `markPlatformErrorResolved`
- platform-safe error list/watch path, depending on current implementation

Rules:
- Normal company users must not access monitoring data.
- Platform monitoring must not throw permission snackbars.
- Copy error action must avoid secrets/tokens.
- Flutter Web hot restart metadata errors should not crash app.
- Do not spam platform owner with noisy non-serious errors.

---

## Profile image rules

Profile images should display consistently across:
- app shell/avatar menu
- profile page
- settings account area
- company user rows/cards
- platform user rows/cards
- team/member rows/cards
- assignee dropdowns where supported

Source priority:
1. company/platform user profile `photoUrl`
2. Firebase Auth `photoURL`
3. initials fallback

Rules:
- Do not store image bytes in Firestore.
- Do not clear `photoUrl` because image load fails.
- Only clear profile image when user explicitly removes it.
- Use safe image loading and initials fallback.
- Do not log full image URLs/tokens.
- Cache-bust only when image changes, not constantly.
- Storage rules must not make all profile images globally public.

---

## Invitation onboarding rules

Invitation-code onboarding remains preferred SaaS company onboarding.

Platform owner creates invitation:
- Owner creates package/settings only.
- Owner does not enter company name/email/admin email.
- Invitation settings include plan/package, user limit, storage limit, enabled features, locale, timezone, expiry, trial option, trial duration unit/value, and optional notes.
- Generated links must use public web URL and hash route:
  - `https://masarcrm.web.app/#/register-company?code=MASAR-XXXX-XXXX`
- Do not use `Uri.base.origin` blindly on mobile because mobile may use `file://`.

Company admin registration:
- Public route: `/register-company`.
- Link route: `/register-company?code=...`.
- Code can auto-fill from link.
- Company ID/slug generated from company name and revalidated server-side.
- Admin enters own password.
- Backend creates Firebase Auth user, company doc, company admin profile, global user doc, and membership doc.
- Registered admin has full company admin powers.

Invitation reuse protection:
- Accepted invitation must never be reusable.
- Deleting company must not make same invitation code valid again.
- Use permanent usage marker:
  - `platform_invitation_uses/{invitationId}`

Duplicate checks:
- Use Firebase Auth `getUserByEmail` and global users email checks.
- User-facing duplicate message should be safe/generic:
  - “Please try another admin email.”
  - “جرّب بريدًا آخر للمسؤول.”
- Do not expose detailed duplicate internals to end user.

---

## Password and user creation rules

First company admin:
- Chooses own password in Register Company form.
- Do not generate setup link for first admin.
- Do not store or log password.
- Password sent once to Firebase Auth createUser.

Normal company users:
- Default flow: create user and return setup/reset link.
- Admin/platform owner sends setup/reset link.
- User sets own password.
- Admin should not know user passwords in default flow.

Temporary password flow:
- Optional.
- Do not store password in Firestore.
- Backend creates Firebase Auth user with temporary password.
- User profile gets:
  - `mustChangePassword: true`
  - `passwordSetupMethod: temporaryPassword`
- On login, force `/force-change-password`.
- User changes password, then `mustChangePassword` clears.

Company Admin User Management:
- Route: `/users`.
- Admin only.
- Manager/Sales/Marketing/Viewer blocked even by direct route.
- Dialogs must receive Cubit correctly with `BlocProvider.value` when opened via dialog/sheet.

---

## Audit logs and recent activity

Real audit logs feed dashboard recent activity.

Audit logs should include:
- actor id/name/email/role
- module
- action
- record id/title/subtitle
- createdAt
- useful metadata/details
- assignedTo where relevant
- teamId/teamName where relevant
- managerId/managerName where relevant

Admin Recent Activity:
- company-wide

Manager Recent Activity:
- own team only
- must not query all logs then filter client-side

Sales/Marketing/Viewer:
- no broad team/company activity unless future policy explicitly allows.

Future phase:
- Full Audit Log Viewer after release-lock QA.

---

## Team Management rules

Admin:
- sees all teams and members
- can create/edit teams
- can assign/remove/move Sales/Marketing members
- can manage team managers

Manager:
- sees only own team
- sees all active members of own team
- read-only My Team view
- no create/edit/manage/remove/backfill actions
- must not see other managers’ teams/members

Sales/Marketing/Viewer:
- no Team Management nav unless explicitly allowed

Team snapshots:
- Moving user teams should update assigned record snapshots through safe flow/Cloud Functions where needed.
- Manual backfill is a repair tool, not normal workflow.
- Do not broaden manager visibility to fix missing snapshots.

---

## Mobile behavior rules

Mobile avatar:
- Opens account menu with Profile, Settings, Logout.

Mobile More sheet:
- Module navigation only.
- No Profile/Settings/Logout.
- Dismiss by tapping outside.
- Dismiss by dragging down.
- Dismiss after selecting module.

Mobile bottom nav:
- Hide on downward scroll.
- Show on upward scroll/top.
- Do not flicker.
- Do not hide while keyboard/text input interaction would hurt usability.
- Must not cover important action buttons.

Mobile layout:
- Make module cards tappable where that is the current pattern.
- Avoid separate “details eye” buttons on mobile if cards are tappable.
- Avoid long messy vertical sections where compact grid/wrap works.
- Ensure Reports/Export/Support/Team/User Management are compact and aligned.

---

## Global Search rules

Global Search is Firebase-only for now.

Rules:
- Debounce around 300 ms.
- Minimum query length around 2 characters.
- Use limited one-shot queries where possible.
- No permanent global search streams.
- Group results by module.
- Tapping result opens detail page if allowed.
- Do not show forbidden results.

Scope:
- Admin company-wide allowed results.
- Manager own team only.
- Sales/Marketing own assigned only.
- Viewer restricted.
- Platform owner platform-safe search in platform context.

Do not introduce external search engines unless explicitly requested.

---

## Performance and lifecycle rules

Avoid:
- unnecessary app shell rebuilds
- broad streams for restricted roles
- streams for hidden/forbidden tabs
- expensive sorting/filtering in `build()`
- huge nested scrolls
- `shrinkWrap` on long lists unless justified
- leaking controllers/listeners/focus nodes
- noisy debug prints
- repeated async work from `build()`
- loading all company data for dashboard/reports when only small recent lists/counts are needed

Use:
- `ListView.builder` / `GridView.builder` for long lists
- query limits
- date windows
- debounced search
- stable keys
- const widgets where safe
- mounted guards after async callbacks
- proper dispose
- small role-scoped streams

---

## Cloud Functions and privileged flows

Important existing/new callable or scheduled functions include:
- `saveLeadRecord`
- `getServerTime`
- `expireTrialCompanies`
- `createCompanyInvitation`
- `validateCompanyInvitation`
- `acceptCompanyInvitation`
- `revokeCompanyInvitation`
- `listCompanyInvitations`
- `createCompanyWithAdmin`
- `addUserToCompany`
- `setCompanyActiveStatus`
- `setCompanyUserActiveStatus`
- `setCompanyUserEmail`
- `setCompanyUserPassword`
- `generateCompanyUserPasswordResetLink`
- `updateCompanyPlatformSettings`
- `assignUserToTeam`
- `removeUserFromTeam`
- `reportClientError`
- `markPlatformErrorResolved`
- `exportCompanyDataForPlatform`
- `markCompanyPaymentPaid`
- `extendCompanyPaymentDueDate`
- `updateCompanyPaymentStatus`
- `runPaymentReminderSweep`
- Data Health functions:
  - `getCompanyDataHealthReport`
  - `getOperationalDataHealthReport`
  - `backfillAssignedRecordSnapshots`
  - `reassignDataHealthRecord`

Rules:
- Keep privileged repair/reassignment/platform/payment/trial/export operations server-side.
- Do not move them into direct Flutter Firestore writes.
- When changing Functions, report exact deploy commands.
- Do not log passwords, invite secrets, reset links, tokens, or sensitive URLs.

---

## Deployment reporting rules

Every final report must state exact deployment needs.

If Functions changed:
```powershell
firebase deploy --only functions:<functionName>
```
or:
```powershell
firebase deploy --only functions
```

If Firestore rules changed:
```powershell
firebase deploy --only firestore:rules
```

If Storage rules changed:
```powershell
firebase deploy --only storage
```

If Flutter UI changed:
```powershell
flutter build web --release --dart-define-from-file=config/firebase.local.json
firebase deploy --only hosting
```

If mobile assets/native config changed:
- rebuild/reinstall mobile app.

Do not claim deployment happened unless user confirms.

Recommended full deployment order when Functions + rules + UI changed:
```powershell
firebase deploy --only functions
firebase deploy --only firestore:rules
flutter build web --release --dart-define-from-file=config/firebase.local.json
firebase deploy --only hosting
```

---

## Git hygiene rules

Never stage blindly.

Do not commit:
- `.vscode/`
- `*.zip`
- `*.patch`
- screenshots
- pasted text files
- temporary scripts
- `apply_masar_branding_assets.py`
- font zip files
- local secrets/config unless intentionally tracked
- `assets/IBM_Plex_Sans_Arabic.zip`
- `assets/Plus_Jakarta_Sans.zip`
- `whatsapp_icon_support_page.patch`

Be careful with:
- `.metadata`
- `windows/`
- `test/`
- local config files

Safe staging for this project is usually:
```powershell
git add lib
git add functions/src/index.js
git add firestore.rules
git add pubspec.yaml
git add pubspec.lock
```

Then inspect:
```powershell
git status --short
git diff --cached --stat
```

Do not commit unless staged files match intended scope.

---

## Current latest completed phases

The latest confirmed good/deployed state includes:

1. Protected session and role-scoped account switching hardening.
2. Firebase token/session invalidation for disabled user/company behavior.
3. Export cleanup:
   - Excel-only
   - no PDF
   - no preview
   - compact Reports Export UI
   - role-scoped export
4. Shared Masar segmented tab system replacing `google_nav_bar/GNav`.
5. Global dark-mode logo visibility fix.
6. Masar logo page-level loader where applicable.
7. Company Users layout crash fix.
8. Profile image refresh/caching fix.
9. Reports/Support/Appointments tab consistency.
10. Mobile Reports Export compact grid.
11. Performance/query-limit cleanup.
12. App Check skipped and removed.
13. Platform observability/error monitoring.
14. Platform owner trial system:
   - minutes/hours/days
   - server-time calculation
   - dashboard badge
   - localized milestone notifications
   - Firestore request-time expiry enforcement
15. Platform owner Excel export for selected company sections.
16. Notification dropdown collapsible attention-needed and clear actions.
17. Manual Payment Follow-up:
   - payment statuses
   - payment history
   - mark paid / extend / grace / suspend / reactivate
   - reminder sweep
   - strict platform-owner control
18. Latest Hosting deploy succeeded; browser cache required hard refresh/query-param to show new version.

---

## Current active phase

**Release Lock QA ONLY**

Do not start another feature until release-lock QA passes.

Release Lock QA must verify:
- Platform owner dashboard
- Trial lifecycle
- Payment follow-up
- Suspended/grace company access
- Existing active legacy companies without payment fields
- Company export Excel
- Monitoring/errors
- Notifications
- Admin/Manager/Sales/Marketing/Viewer scopes
- Arabic/English
- Mobile web
- Dark/light mode
- Logout/login account switching
- Build/deploy cache behavior

Required checks if user approves:
```powershell
flutter analyze
node --check functions/src/index.js
flutter build web --release --dart-define-from-file=config/firebase.local.json
```

Do not deploy again unless needed.

---

## Next phases after Release Lock QA passes

1. Final Production Release Lock / Tag / Backup
   - verify commit/tag
   - verify Firebase deploy state
   - verify rules/functions/hosting all live
   - final smoke test
   - document rollback point

2. UI/UX Professional Polish
   - platform top bar polish
   - payment section density
   - mobile/narrow cleanup
   - dashboard responsive details
   - no business logic changes

3. Full Audit Log Viewer
   - filter by module/user/action/date
   - manager team-scoped view
   - readable before/after changes
   - export audit logs
   - open related record

4. Global Search
   - role-scoped only
   - grouped result UI
   - open details
   - no forbidden data
   - no broad client-side filtering

5. Appointments Calendar Upgrade
   - month/week/day views
   - today schedule
   - missed appointments dashboard
   - reschedule flow
   - appointment outcome
   - link related records

6. FCM / Push Notifications
   - only after in-app notifications are stable
   - web push
   - mobile push
   - token registration/cleanup
   - foreground/background handling
   - appointment/payment/trial/support/error alerts

7. Public Website / Domain Setup
   - domain
   - landing page
   - login route
   - invite registration route
   - privacy policy
   - terms
   - support/contact page
   - screenshots
   - SEO
   - favicon/app icons

8. Data Health/Admin Tools Upgrade
   - missing team snapshots
   - invalid/inactive assignees
   - companies with no admin
   - duplicated leads/clients
   - safe one-click repairs

9. Windows/Desktop Packaging
   - optional later
   - Windows build
   - app icon
   - installer
   - update strategy

Skipped/removed:
- Full Stripe/billing gateway.
- App Check.
- Online payment gateway.
