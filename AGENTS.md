# AGENTS.md — Masar CRM

## Project identity

Masar CRM is a production-grade real estate CRM SaaS built with Flutter Web/Mobile and Firebase.

Product identity:
- English name: `Masar CRM`
- Arabic name: `مسار`
- Meaning: path / journey / workflow.
- Business scope: real estate CRM for the full journey from lead → client → appointment → property → deal → task/follow-up → audit/export/notifications.
- Working path: `C:\Users\islam\Desktop\real_estate_crm`
- Current active branch: `dev`
- Firebase project: `real-escrm-ia`
- Live Hosting: `https://masarcrm.web.app`
- Current user-preferred development style: strong mega prompts, scoped stabilization batches, strict reports.

Core stack:
- Flutter Web/Mobile
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Hosting
- go_router
- BLoC/Cubit only
- Feature-first Clean Architecture
- Arabic/English localization with RTL/LTR

---

## Current release context

Latest confirmed stable batch:
- `v2.28.9+91`
- User confirmed it was all good and tested.

`v2.28.9+91` included:
- Duplicate appointment deny-block cleanup.
- Lead duplicate check optimization through targeted normalized phone/email Cloud Function path.
- Lead budget min/max validation.
- Notification stream Firestore-side limits where safe.
- Audit actor snapshot hardening.
- Unified new-password policy.
- Arabic/English localization updates.

Latest implemented but not yet confirmed stable:
- `v2.29.0+92`

Treat `v2.29.0+92` as implemented but **not stable** until analyze, rules deploy, local QA, web QA, and Android QA are confirmed.

Codex reported `v2.29.0+92` implemented:
- Sales appointment/task related-record loading uses scoped queries and no longer maps permission/scope failures to false “no internet.”
- Sales/Marketing can create self-assigned tasks under strict Firestore rules.
- Manager scope prioritizes `teamId` across leads, clients, tasks, deals, dashboard, reports, and related-record lookups.
- Manager Team 2 should not see/select Team 1 records.
- Shared active properties no longer use manager/assignee scope in appointment/task related lookups.
- Appointment/task related dropdowns no longer inject stale selected records not in eligible result set.
- Notification list and attention queries over-fetch before local dismissed/status filtering to avoid missing items caused by limit-before-filter behavior.
- Platform Owner Settings/Profile use platform owner account shell instead of company CRM shell.
- Platform Owner email change updates Firebase Auth first, then `platform_admins/{uid}` and global `users/{uid}`.
- Version bumped to `2.29.0+92`.

Immediate active phase:
- Validate `v2.29.0+92` before starting FCM Phase 2B.
- Do **not** start FCM server push work until `v2.29.0+92` is confirmed stable.

Required before treating `v2.29.0+92` as stable:
1. Run `flutter analyze` only after user approval.
2. Deploy Firestore rules because `firestore.rules` changed.
3. Test locally on Web.
4. Build/deploy Hosting only if local QA passes.
5. Build APK only after Web is clean.
6. Test Android release/update path if distributing APK 92.

Suggested commands only after user approval:

```powershell
cd C:\Users\islam\Desktop\real_estate_crm
flutter analyze
firebase deploy --only firestore:rules
flutter run -d edge --dart-define-from-file=config/firebase.local.json
```

If local Web QA passes:

```powershell
flutter build web --release --dart-define-from-file=config/firebase.local.json
firebase deploy --only hosting
```

If Android release is needed:

```powershell
flutter build apk --release --dart-define-from-file=config/firebase.local.json
```

Important Hosting/cache note:
- Firebase Hosting deploys from `build/web`, not directly from `web/`.
- If the live web app still shows an older version after deploy, test with a cache-busting query param:
  - `https://masarcrm.web.app/?v=<build-number>`
- Use hard refresh `Ctrl + Shift + R` or Incognito after each Flutter Web deploy.

---

## Absolute rules for Codex / assistant work

These rules are mandatory.

- Follow this `AGENTS.md` first.
- Work on `dev` unless the user explicitly says otherwise.
- Do not run Flutter, Firebase, Git, npm, Dart, analyzer, build, deploy, commit, push, or migrations unless the user explicitly approves.
- Do not commit, push, deploy, or run migrations unless the user explicitly asks.
- Do not use `git add .` blindly.
- Do not stage temp files, zip files, local patches, screenshots, generated throwaway files, local editor folders, `build/`, `functions/node_modules/`, `.vscode/`, `android/.gradle/`, or `config/firebase.local.json`.
- Do not claim `flutter analyze`, build, deploy, rules deploy, Functions deploy, APK install, or manual QA passed unless it was actually run or the user confirmed it.
- Keep every change scoped to the user’s exact request.
- Do not touch unrelated files.
- Do not add new features during stabilization/release-lock phases unless the user explicitly approves the new phase.
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
- Do not abbreviate or truncate visible Arabic/English sentences with ellipsis unless the user explicitly asks. Use wrapping/responsive layout instead.
- Follow the existing Masar design system. Do not create generic admin-template UI.
- Use circular progress indicators for action/save/loading states where appropriate; prefer overlays when existing content can remain visible.
- Shimmer is for content loading only; action buttons should use circular spinners.
- Be direct, precise, and honest in reports.
- No emojis.

---

## User preferences

- The user prefers strong mega prompts for Codex over many small prompts.
- The user often asks for required files only, not a full ZIP.
- The user wants practical real-market CRM behavior, not decorative-only features.
- The user dislikes generic/AI-looking designs.
- The user wants direct reports with exact files changed, exact risks, exact deploy requirements, and exact manual QA steps.
- The user is strict about role security and permissions.
- The user expects app design consistency across all modules.
- The user expects Arabic wording to be natural, not machine-translated.
- The user expects compact UI to still show full important text.
- The user expects all new phases to be treated seriously when they affect money, security, access, roles, exports, notifications, update flow, or customer data.

---

## Architecture rules

Use feature-first Clean Architecture:

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
    cubit/ or bloc/
    pages/
    widgets/
```

Layer direction:

```text
UI → Cubit/BLoC → Use Case → Repository → Data Source → Firebase/API
```

Core rules:
- Use BLoC/Cubit for state management.
- Do not introduce Riverpod, Provider, GetX, MobX, or another state-management pattern.
- Keep Firebase calls inside data sources or Cloud Functions.
- Widgets must not call Firestore/Storage/Auth/Functions directly.
- Cubits should call use cases/repositories, not Firestore directly.
- Keep role/company scoping in repositories/data sources/functions, not only widgets.
- Prefer shared reusable widgets/components that already exist in the app.
- Keep model/entity mapping explicit and safe.
- Use safe `mounted` checks after async UI callbacks.
- Dispose controllers, timers, focus nodes, and subscriptions.
- Avoid launching async work repeatedly from `build()`.

---

## Localization / RTL / LTR rules

Supported languages:
- English
- Arabic

Rules:
- Every visible string must use ARB/l10n.
- Do not hardcode visible user-facing strings in widgets, function responses, validators, snackbars, dialogs, cards, empty states, or errors.
- Arabic must be natural and product-quality.
- Add English and Arabic messages together when adding validation/errors.
- Use RTL-safe layout:
  - `EdgeInsetsDirectional`
  - `AlignmentDirectional`
  - `PositionedDirectional`
  - `BorderRadiusDirectional` where appropriate
- Test mixed Arabic/English/numbers in RTL.
- Do not use ellipsis for important explanatory/support/warning/guidance text.
- For old/new values in Arabic, prefer `من old إلى new` with directional isolation where needed.

---

## Masar design system rules

The whole app, including Platform Owner, must follow one Masar CRM design language.

Use:
- Warm premium surfaces.
- Professional CRM card layout.
- Compact density.
- Consistent section headers.
- Consistent search/filter/action bars.
- Consistent action button positions.
- Consistent segmented tabs.
- Consistent status badges.
- Consistent empty/loading/error states.
- Consistent snackbar/feedback style.
- Consistent dark/light behavior.
- RTL/LTR-safe spacing and alignment.

Do not:
- Create generic admin-template screens.
- Create a separate-looking Platform UI.
- Use random gradients/glassmorphism/AI-looking effects.
- Place action buttons randomly.
- Create huge blank cards.
- Create huge repeated bordered boxes.
- Make mobile screens scroll too much when compact layout is possible.
- Use old/GNav-style tabs that hide labels or show weird ellipsis.
- Truncate support/help/explanatory sentences with ellipsis; redesign the layout to wrap or reflow instead.

Tabs:
- Use the shared Masar segmented tab style.
- Reports, Support, Appointments, Dashboard, and Platform workspace tabs must look consistent.
- On mobile, avoid squeezing many tabs into one unreadable row. Use scroll/segmented behavior that keeps names readable.

Loading:
- Page/panel-level loading should use the Masar logo loader where applicable.
- Button/action-level loading can stay compact circular progress.
- Existing content should remain visible with overlay loading when possible.

Brand/logo:
- Use Masar logo/mark consistently.
- In dark mode, keep a light backing where needed so black logo strokes remain visible.
- Do not let logo invert into invisible black-on-black.
- Do not use generic apartment icons where the Masar logo should appear.

Mobile:
- Pull-to-refresh should exist across modules where content lists/workspaces refresh.
- Cards should be tappable where that is the current pattern.
- Avoid duplicate FABs on mobile.
- Mobile bottom nav must not cover important action buttons.
- Mobile More sheet is for module navigation only; Profile/Settings/Logout belong in avatar/account menu.

---

## Versioning rule

For every major user-facing, security, data, platform, trial, payment, export, Functions, or rules phase:
- Update `pubspec.yaml` version.
- Update `AppConstants.appVersion`.
- Update `AppConstants.appBuildNumber`.
- Mention the version update in the final report.

Do not bump version for tiny compile-only fixes unless the user asks.

Current context:
- `v2.28.9+91` is confirmed stable.
- `v2.29.0+92` is implemented but not yet confirmed stable.
- Always verify `pubspec.yaml`, `AppConstants.appVersion`, and `AppConstants.appBuildNumber` before saying a version is final.

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
- `companies/{companyId}` metadata
- `platform_invitations/{invitationId}`
- `platform_invitation_uses/{invitationId}`
- `platform_notifications/{notificationId}`
- `platform_error_logs/{logId}` or current observability collection structure
- `platform_config/android_release_policy`

---

## Firestore rules and query rules

- Firestore rules are not filters.
- A query must only ask for records the role is allowed to read.
- Do not query broad collections for restricted roles and then filter in Dart.
- If Firestore denies a query, fix the query shape/scope first.
- Do not loosen rules unless the product policy explicitly requires it and the user approves.
- Firestore multiple matching `allow` expressions are OR-based; a later deny-only duplicate block does not override an earlier allow like CSS. Still remove confusing duplicate deny blocks.
- Any rules change requires `firebase deploy --only firestore:rules` after user approval.
- Report any composite indexes Firestore asks for. Do not guess indexes if the error provides a link.
- Do not hide security issues behind UI-only checks.
- Do not make UI show records that rules would deny on direct route/query.

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
- Android release policy fields

Privileged platform/payment/trial/security operations must go through Cloud Functions/Admin SDK.

---

## Role and permission model

Primary roles:
- Platform Owner / owner: platform-level operations only.
- Company Admin / admin: company-wide control.
- Manager: own-team scope only unless an explicit existing product rule says otherwise.
- Sales Agent: assigned/owned records and allowed self-created records.
- Marketing: assigned/allowed campaign/lead/task-related records depending on existing rules.
- Viewer: read-only where allowed.

Company Admin:
- Sees all company records.
- Sees unassigned leads.
- Sees all company teams/users where the feature allows.
- Can assign/reassign to eligible users.
- Can access Company User Management `/users`.
- Can supervise normal company export activity where policy allows.
- Cannot access `/platform`.
- Cannot write payment/trial/platform fields directly.

Manager:
- Sees own team records only.
- Must not see/select/assign Team 1 records if Manager leads Team 2.
- Dashboard/reports/recent activity must be team-only.
- Can assign/reassign only to eligible users in own team.
- Must not access `/users` or Platform.
- Must not query all company data and filter client-side.
- Must not see export/report/audit-export activity if export policy says Admin-only.
- Must not receive export notifications if export policy says Admin-only.

Sales Agent:
- Sees only own assigned/allowed records.
- Must not see all company leads/clients/tasks/deals.
- Must not see unassigned leads.
- Must not see other users’ records.
- Can create appointments/tasks where current policy allows, including self-assigned tasks after `v2.29.0+92`.

Marketing:
- Sees only own assigned/allowed records unless explicit policy changes this.
- Must not see unassigned leads by default.
- Must not access other users’ records through search, filters, reports, exports, or direct routes.

Viewer:
- Restricted/read-only according to current policy.
- Must not appear as assignable.
- Must not access team/platform/user-management/payment data unless explicitly allowed.

Platform Owner:
- Can access `/platform` without company membership.
- Uses platform owner shell/sidebar, not company CRM shell.
- Settings/Profile must use platform shell on web and mobile.
- Can manage companies, company limits/features, trial/payment follow-up, support, platform notifications, monitoring, and release policy.
- Can change owner email from Settings safely: update Firebase Auth first, then `platform_admins/{uid}` and global `users/{uid}`.
- Must not accidentally act as a company Admin inside tenant CRM unless through a controlled support/preview tool.
- Platform Owner export is platform administrative and must not leak tenant-visible company Admin notifications/audits unless explicitly designed.

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
- Do not over-restrict property viewing if properties are intended as shared active inventory.

Admin and Manager can manage assignment but should not appear as normal operational assignee options.
Viewer must never appear as assignable.

Assigned records should store snapshots where the module supports assignment:
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

## Current `v2.29.0+92` validation checklist

Before any FCM work, validate this exact batch.

Admin:
- Leads/clients/tasks/deals visible.
- Create appointment related to lead/client/deal.
- Create task related to lead/client/deal.
- Notifications still appear.
- Assignment still works.

Sales:
- Create appointment.
- Create task.
- Related dropdown shows only allowed records.
- No false “internet connection” error.
- Denied records stay hidden.

Manager Team 2:
- Team 1 client is not visible.
- Team 1 client is not selectable in appointment/task/deal forms.
- Eligible Team 2 records are visible/selectable.
- Shared active properties are selectable if product policy allows.
- Manager sees only team-scoped leads/clients/tasks/deals/dashboard/reports.

Related-record dropdowns:
- Appointment related to Deal shows only actual eligible deals.
- Task related to Client shows only actual eligible clients.
- Changing related type clears stale selected record/list.
- Archived/inactive records do not appear unless intentionally allowed.

Notifications:
- Bell/list/unread/attention/module filters show valid items.
- Attention section does not miss due/missed items.
- Unknown notification types do not crash.
- Notification over-fetching is bounded and not a new broad-query/security issue.

Owner:
- Owner Settings/Profile keep platform owner shell/sidebar.
- Owner email change updates Firebase Auth and platform/global profile.
- Company CRM sidebar is not shown for owner Settings/Profile.

Indexes:
- If Firestore reports index errors, copy the generated index link/error and report it.
- Likely areas include:
  - `teamId + isArchived/isActive`
  - `recipientUid + createdAt desc`
  - `recipientUid + isRead`

---

## Notifications / FCM status

FCM status:
- FCM Phase 1 notification classification is complete.
- FCM Phase 2A Android/Web token registration/storage infrastructure was prepared.
- Web VAPID key was obtained and should be stored locally as `FIREBASE_WEB_VAPID_KEY` in `config/firebase.local.json`.
- iOS is skipped for now.
- FCM Phase 2B server push sender has not started yet.
- Do not start FCM Phase 2B until `v2.29.0+92` is analyzed, deployed, and manually confirmed.

Strict push policy for future FCM Phase 2B:
- Android push: yes.
- Web push: yes.
- iOS push: no for now.
- Every push must have an in-app notification first.
- Not every in-app notification should push.
- Push only when `deliveryMode == pushEligible` and priority is high/urgent/critical according to current enums.
- No push spam.
- No push for normal CRUD noise.
- No push for normal audit logs.
- No manager export push if export policy says Admin-only.
- No Platform Owner export push to tenant Admin.
- Use Firebase Admin SDK inside Cloud Functions.
- Do not use Firebase Console Compose Notification for production workflow.
- Do not use legacy server keys.
- Do not put server credentials in Flutter.
- Flutter should handle permission/token registration only.

Notification query caution:
- `v2.29.0+92` reportedly over-fetches before local dismissed/status filtering to avoid missing notifications.
- This is acceptable only if bounded and role-scoped.
- Later, move more filters to indexed Firestore queries where safe.
- Missing notifications after limit-before-filter changes are a known regression risk.
- Test unread badge, list, attention section, and module filters.
- Unknown notification types must not crash; always use safe fallback titles/bodies.

---

## Android forced update / release management

Android forced-update flow is confirmed working after fixing stale `updateUrl` and adding validation that rejects fake/tiny APK downloads.

Current rules:
- Android forced update must require all:
  - `enabled == true`
  - `releaseReady == true`
  - `updateUrl` not empty
  - installed build below `minimumSupportedBuildNumber`
- Keep build numbers as whole numbers, not decimals.
- Platform Owner must not be blocked by forced update. Owner needs access to fix broken release policy.
- Release policy is global, not per company:
  - `platform_config/android_release_policy`
- Prefer Platform Owner Release Management UI for future updates after the relevant build is deployed.

Safe release order:
1. Build APK.
2. Rename APK clearly, for example `masar-crm-2.29.0-92.apk`.
3. Put APK in Hosting downloads output.
4. Deploy Hosting.
5. Open APK URL manually and verify it downloads a real APK.
6. Set/update release policy.
7. Set `releaseReady: true` only after real-device install/update test.

Emergency switch:
- Set `releaseReady: false`.

Hosting deploy detail:
- Firebase Hosting deploys from `build/web`, not directly from `web/`.
- The APK must exist under `build/web/downloads/...` before `firebase deploy --only hosting`, or be placed in `web/downloads` before running `flutter build web`.

---

## Password policy

Unified new-password policy as of `v2.28.9+91`:
- Minimum 8 characters.
- Must contain at least one lowercase letter.
- Must contain at least one uppercase letter.
- Must contain at least one number.
- Reject blank/whitespace-only passwords.
- Confirm password must match where confirmation exists.
- Login password field should not enforce complexity; login only requires non-empty because existing Firebase users may have older valid passwords.
- Client and server-side validation must match when creating/changing/resetting passwords.
- Do not log passwords.
- Do not store passwords in Firestore.

---

## Export / Reports rules

Current export policy:
- Excel only.
- No PDF.
- No preview.
- Role scoped.
- Professional Excel with Summary/Data sheets, readable summaries, formatted dates/currency, phone as text, styled/frozen headers, filters, widths, and RTL sheets for Arabic where applicable.
- Exports must be audited.
- Admin must be able to see company export audit/notifications where policy allows.
- Manager should not receive prohibited export notifications if export policy is Admin-only.
- Platform Owner export is platform administrative and must not leak tenant-visible company Admin notifications/audits unless explicitly designed.
- Export audit/notification metadata should show what was exported exactly, such as Leads, Properties, Tasks, Deals.
- Android export must work on real devices, not only emulator/web.
- Preferred Android behavior: save clearly under phone Downloads/Masar CRM or show Android system save picker if direct saving is blocked.
- Open Downloads should open the folder/downloads area, not the file itself.

Normal Reports Export:
- Real Reports tab.
- Choose report type.
- Choose filters.
- Choose columns.
- Generate Excel.
- Export tab should be compact on mobile.
- Report types should be a grid, not long vertical cards.
- Export tab should be last on mobile if that is the current design.

---

## Audit logs and recent activity

Real audit logs feed dashboard recent activity and the Full Audit Log Viewer.

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

Current Audit Log Viewer behavior:
- Route: `/audit-logs`.
- Admin can view company-wide logs.
- Manager can view own-team logs only.
- Sales/Marketing/Viewer are hidden/blocked.
- Default visible date range is Last 7 days unless changed.
- Search is local over loaded/scoped logs only, not full Firestore history.
- Legacy audit logs missing `managerId`/`teamId` snapshots should remain hidden from Managers until a safe Data Health/backfill phase fixes them.

Export audit policy:
- Admin can see export audit activity.
- Manager must not see export/report/audit-export entries.
- Manager must not receive export notifications.
- Platform Owner export from `/platform` should not create tenant-visible company Admin notification/audit unless policy is explicitly changed.
- Do not reintroduce Admin-only technical metadata dumps in user-facing audit sheets.

---

## Team Management rules

Admin:
- Sees all teams and members.
- Can create/edit teams.
- Can assign/remove/move Sales/Marketing members.
- Can manage team managers.

Manager:
- Sees only own team.
- Sees all active members of own team.
- Read-only My Team view.
- No create/edit/manage/remove/backfill actions.
- Must not see other managers’ teams/members.

Sales/Marketing/Viewer:
- No Team Management nav unless explicitly allowed.

Team snapshots:
- Moving user teams should update assigned record snapshots through safe flow/Cloud Functions where needed.
- Manual backfill is a repair tool, not normal workflow.
- Do not broaden manager visibility to fix missing snapshots.

---

## Platform owner rules

Platform Dashboard must follow the normal Masar design system.

Platform owner can:
- Access `/platform` without company membership.
- Manage companies.
- Manage company users through safe functions.
- Create/revoke invitations.
- Preview company dashboard read-only.
- View platform notifications.
- View platform support inbox.
- View platform monitoring/error logs.
- Export selected company data to Excel.
- Manage trial/payment status.
- Suspend/reactivate companies.
- Manage Android release policy.
- Access platform owner Settings/Profile using platform shell.

Platform owner cannot:
- Weaken tenant role rules.
- Bypass tenant data isolation from normal user UI.
- Expose platform controls to company roles.
- Be forced into the company CRM shell for platform pages.

---

## Trial system rules

Trial system is money-sensitive. Treat it as critical.

Current behavior:
- Trial can be set from platform invitation creation, manual company creation, or editing company status/settings.
- Trial duration supports minutes, hours, and days.
- Trial duration is customizable.
- Trial end time must be calculated on the server, not browser/client time.
- Dashboard remaining time must use server-time logic, not laptop/browser `DateTime.now()`.
- Changing laptop/device time must not fake remaining trial time.
- Expired trial access must be blocked by Firestore rules using `request.time`.
- Scheduler is cleanup/notification only, not the only enforcement layer.
- Trial company can be converted to active/paid without deleting data.
- Trial badge must appear immediately in company dashboard after company becomes trial.
- Trial expired company must show clean localized block message.

Trial notifications/warnings:
- Company admin gets warnings around 1/3 of trial period, 2/3 of trial period, and final warning before expiry.
- Warning dialogs must not dismiss by tapping outside; user must acknowledge.
- Saved company notifications should be localized Arabic/English.
- Platform owner gets near-ending and expired trial alerts.
- No duplicate notification spam every minute.

---

## Payment follow-up rules

Payment follow-up is implemented for direct client payments.

This is not:
- Stripe
- online billing
- payment gateway
- online invoice payment

It is:
- Platform-owner-controlled manual payment tracking and company access control.

Payment statuses:
- `paid`
- `dueSoon`
- `overdue`
- `gracePeriod`
- `suspended`
- `trial`
- `trialExpired`
- `inactive`

Rules:
- Payment writes must go through Cloud Functions/Admin SDK.
- Company Admin/Manager/Sales/Marketing/Viewer must not write payment fields.
- Money/access decisions must not depend on client/laptop time.
- Existing active legacy companies with missing payment fields must remain usable if `isActive == true`.
- Missing payment metadata must not crash Platform UI.
- Missing payment metadata must not accidentally block old clients.

---

## Support rules

Support Center exists:
- Support
- Feedback
- My Requests
- Contact

Platform support inbox exists.

Public login support contact:
- Login page includes compact public support contact so unauthenticated users can contact Masar before registration/login.
- The login support section must not start protected Firestore/company/platform streams.
- Current support contacts used in the app: WhatsApp `201208090241`, email `islamallam9@outlook.com`. Verify before changing.
- Login support copy must be localized Arabic/English and must not be truncated with ellipsis.

---

## Observability / error monitoring rules

Platform Observability exists:
- `platform_error_logs`
- owner-only Monitoring UI
- KPI cards, filters, detail sheet, mark-resolved flow
- sanitized metadata
- global Flutter/Bloc error reporting
- selected Cloud Function error logging helper

Rules:
- Normal company users must not access monitoring data.
- Platform monitoring must not throw permission snackbars.
- Copy error action must avoid secrets/tokens.
- Flutter Web hot restart metadata errors should not crash app.
- Do not spam platform owner with noisy non-serious errors.

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
- Admin company-wide allowed results.
- Manager own team only.
- Sales/Marketing own assigned only.
- Viewer restricted.
- Platform owner platform-safe search in platform context.
- Do not introduce external search engines unless explicitly requested.

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

Important callable or scheduled functions include:
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
- `generateReportExportFile`
- `recordReportExportActivity`
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
- FCM server push must be implemented through Firebase Admin SDK in Cloud Functions, not Flutter.

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
- Rebuild/reinstall mobile app.

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
- `build/`
- `functions/node_modules/`
- `android/.gradle/`
- `config/firebase.local.json`

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
git add storage.rules
git add firebase.json
git add pubspec.yaml
git add pubspec.lock
git add functions/package.json
git add functions/package-lock.json
```

Then inspect:

```powershell
git status --short
git diff --cached --stat
```

Do not commit unless staged files match intended scope.

---

## Completed major phases summary

Completed or previously confirmed major work includes:
- Auth/profile foundation and role-aware routing.
- Dashboard foundation and later Dashboard/Sales Command Center revamps.
- Leads, Clients, Properties, Tasks, Deals modules with role-aware flows.
- Property image upload with Firebase Storage and responsive property cards/gallery.
- Security rules hardening and compatibility passes.
- Real audit logs foundation and Dashboard Recent Activity from audit logs.
- Production stabilization/mobile-web polish passes.
- Multi-company Platform Foundation and Platform Dashboard/Settings.
- Password management, login activity, dashboard visibility fixes.
- Team Hierarchy / Manager Teams and team assignment Cloud Functions.
- Export cleanup: Excel-only, no PDF, no preview.
- Server-generated reports export and Platform Owner export.
- Export feature control and export audit/notification policy cleanup.
- Android forced-update flow with releaseReady safety and real APK validation.
- Web Workspace/MasarTabBar crash fix.
- Appointments Calendar Upgrade `v2.24.0+72`.
- Full Audit Log Viewer + Export Tracker around `v2.25.x`.
- FCM Phase 1 classification and Phase 2A token setup.
- `v2.28.9+91` rules/query/validation/password stabilization confirmed good.
- `v2.29.0+92` implemented but not yet confirmed stable.

---

## Next phases after `v2.29.0+92` is stable

1. Commit/push the stable checkpoint.
2. FCM Phase 2B — server push sender.
   - Android + Web only.
   - iOS skipped.
   - Push only for existing in-app pushEligible high/urgent/critical notifications.
   - Clean invalid FCM tokens.
   - No push spam.
3. FCM QA and notification polish.
4. Global Search.
5. Payment follow-up polish only, not full Stripe/billing gateway.
6. Platform Owner control polish.
7. Data Health/Admin Tools upgrade.
8. Public Website / domain setup.
9. Optional Windows/Desktop packaging.

Skipped/removed from near-term roadmap:
- Full Stripe/billing gateway.
- Online payment gateway.
- iOS push in current FCM phase.
- App Check unless the user explicitly revives it later.
