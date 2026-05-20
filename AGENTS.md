# AGENTS.md — Masar CRM

## Project identity

Masar CRM is a production-grade real estate CRM built with Flutter Web/Mobile and Firebase.

Primary goals:
- Company-scoped CRM for real estate sales operations.
- Arabic and English support.
- RTL/LTR support.
- Role-based access for platform owner, admin, manager, salesAgent, marketing, and viewer.
- Clean, professional Masar CRM design system with warm premium styling.
- Secure Firebase rules and server-side privileged operations through Cloud Functions where needed.
- SaaS-ready onboarding where the platform owner controls invitations/subscription access and each company admin owns company setup and staff management.

Brand identity:
- Product name: Masar CRM.
- Arabic name: مسار.
- Meaning: path / journey / workflow, from real estate lead to client, appointment, property, deal, and follow-up.
- New SVG logo/mark should be used consistently across splash, onboarding, app shell/sidebar, favicon, web icons, and mobile launcher icons where supported.
- Avoid old/generic apartment icons after the logo migration.

## Current branch rule

Work on `dev` unless the user explicitly says otherwise.

Do not run Flutter, Firebase, Git, npm, dart, or other CLI commands unless the user explicitly asks.

Do not commit, push, deploy, or run migrations unless the user explicitly asks.

## User preferences

- The user prefers strong mega prompts for Codex instead of many small prompts.
- Keep guidance direct and specific.
- Do not use emojis.
- Be honest about uncertainty and risks.
- Do not claim that analyze/build/deploy passed unless actually run or confirmed by the user.
- Mention exact deploy requirements based on touched files.
- The user often wants full updated context before moving chats.
- The user prefers practical real-market CRM behavior over decorative-only features.

## Architecture rules

Use feature-first Clean Architecture:

lib/features/<feature>/
- data/
- domain/
- presentation/

Layer direction:
UI → Cubit/BLoC → Use Case → Repository → Data Source → Firebase/API

Rules:
- Use BLoC/Cubit only.
- Do not use Riverpod, Provider, GetX, MobX, or other state-management patterns.
- Keep Firebase calls inside data sources only.
- Do not call Firestore/Storage/Auth/Functions directly from widgets or Cubits except through existing repository/data source boundaries.
- Keep business logic out of widgets when possible.
- Keep changes scoped to the requested task.
- Do not touch unrelated files.
- Reuse existing widgets/styles/patterns where possible.

## Localization and directionality

Supported languages:
- English
- Arabic

Rules:
- All visible UI text must be localized through ARB/l10n.
- Do not hardcode visible strings in widgets.
- Keep Arabic RTL and English LTR correct.
- Use Directional widgets when layout depends on language:
  - EdgeInsetsDirectional
  - AlignmentDirectional
  - BorderRadiusDirectional where appropriate
- Test mixed Arabic/English/numbers in RTL screens.
- For old/new value display in Arabic, do not rely on a raw arrow if it reverses visually. Prefer: `من old إلى new` with directional isolation where needed.

## Design system rules

The app uses the Masar CRM warm premium design system.

All modules should visually match:
- same app shell/header style
- same sidebar behavior and spacing
- same card style
- same page title/header pattern
- same search/filter bar style
- same primary/secondary/destructive action button styles
- same action button positions
- same compact density
- same empty/loading/error states
- same snackbar/feedback style
- same dark mode behavior
- same Arabic RTL and English LTR behavior

Do not create generic admin-template screens.
Do not create separate-looking Platform UI.
Do not place action buttons randomly.
Do not create huge blank cards or wide repeated action buttons.

Loading pattern:
- Use circular progress indicators.
- Prefer overlay loading when existing content can remain visible.
- Keep networked buttons disabled while saving and show progress feedback.
- Branded loading/splash can use the Masar mark and premium visual language, but button/network action loading should remain clear and compact.

## Branding, splash, onboarding, and public entry rules

Masar must feel premium at first launch.

Splash:
- Use the new Masar logo/mark from `assets/branding/`.
- Full-screen splash with premium warm background.
- No long text or paragraphs on splash.
- Logo/mark should be large and professional, not tiny.
- Use modern loading dots/progress and optional floating CRM/property mockups.
- Splash should last roughly 3–5 seconds when configured that way.
- If using `MasarSplashGate` in `app.dart`, make sure `lib/core/widgets/masar_splash_gate.dart` actually defines `class MasarSplashGate`.
- If `MasarBrandMark` is inside `_LogoHalo`, pass an explicit size; do not rely on the default 48px size.
- If the logo still appears small, inspect/crop `assets/branding/masar_mark.svg` because the SVG viewBox may contain too much empty space.

Onboarding:
- Onboarding should be shown once, then remembered as seen/skipped.
- Mobile onboarding should support horizontal PageView, Next, Back, Skip, page dots, and smooth animation.
- Onboarding must not start protected Firestore/company/platform streams while logged out.
- Login/register/onboarding must support language switch and dark/light mode before authentication.

Public routes:
- `/onboarding`
- `/login`
- `/register-company`
- `/register-company?code=...`
- `/force-change-password`

Public route rules:
- Unauthenticated users must be able to access `/login`, `/onboarding`, and `/register-company`.
- Public pages must not read protected company/platform data.
- No permission-denied snackbar should appear after logout on public pages.

Fonts:
- Do not set `GoogleFonts.config.allowRuntimeFetching = false` unless the required fonts are bundled locally.
- The app previously used Google Fonts (`PlusJakartaSans`, `IBMPlexSansArabic`). On emulator/offline, runtime Google Fonts may fail.
- Immediate safe fallback is to remove direct GoogleFonts theme calls and use system font fallback (`Roboto`, `Tahoma`, `Noto Sans Arabic`, `Segoe UI`, etc.).
- Long-term better fix is to bundle fonts locally under `assets/fonts/`, register them in `pubspec.yaml`, and then disable runtime fetching safely.
- Never share font files with the user.

## Versioning rule

For every major user-facing, security, data, or platform phase:
- Update `pubspec.yaml` version.
- Update `AppConstants.appVersion`.
- Update `AppConstants.appBuildNumber`.
- Settings must show the current app version/build.
- Mention the version update in the final report.

Do not bump version for tiny compile-only fixes unless the user asks.

Current known version after Phase B invitation onboarding:
- Around `1.6.0+15`.

If only doing branding/splash compile fixes, do not bump again unless the user explicitly asks.

## Firebase structure

Company-scoped data lives under:

companies/{companyId}/...

Important collections include:
- users
- leads
- clients
- properties
- tasks
- deals
- appointments
- notifications
- audit_logs
- teams

Platform/global collections include:
- platform_admins/{uid}
- users/{uid}
- users/{uid}/memberships/{companyId}
- companies/{companyId}
- platform_invitations/{invitationId}
- platform_invitation_uses/{invitationId}

## Security rules principles

Firestore rules are not filters.

Never query broad company data for restricted roles and then filter client-side.
Queries must match security rules.

Do not weaken rules to make UI pass.
Do not use broad `allow read, write: if true`.
Do not allow client-side writes to privilege fields.
Do not expose cross-company data.
Do not expose platform data to normal company users.

Sensitive fields must be protected:
- role
- isActive
- companyId
- teamId/teamName/managerId/managerName when not being changed by safe flow
- email when controlled by platform owner/admin function
- login activity/IP fields
- password/reset-link fields
- mustChangePassword/passwordSetupMethod fields
- platform admin fields
- invitation hashes / secret invitation codes

Privileged platform operations should go through Cloud Functions/Admin SDK.

## Role visibility policy

Platform owner/admin:
- Can access `/platform` without company membership.
- Can manage companies and company users through safe functions.
- Can preview company dashboards read-only.
- Must not be forced into a company dashboard if no company membership exists.

Admin:
- Sees all company CRM records.
- Sees unassigned leads.
- Sees all company teams and users.
- Can assign/reassign records to eligible users across the company.
- Sees company-wide dashboard, reports, and recent activity.
- Can access Company User Management (`/users`).
- Can create company users for manager, salesAgent, marketing, and viewer roles.

Manager:
- Sees own team records only.
- Can assign/reassign only to eligible users in own team.
- Dashboard and reports must be team-only.
- Recent Activity must be team-only.
- Must not see other managers’ teams/records/activity.
- Must not access `/users` or Data Health.

Sales Agent:
- Sees only own assigned records.
- Must not see all company leads/clients/tasks/deals.
- Must not see unassigned leads.
- Must not see other users’ records.
- Can update own assigned records only where current policy allows.
- Must not access `/users`.

Marketing:
- Sees only own assigned records unless an explicit policy changes this.
- Must not see unassigned leads by default.
- Must not access other users’ records through search, filters, reports, or direct routes.
- Must not access `/users`.

Viewer:
- Restricted/read-only according to policy.
- Must not appear as assignable.
- Must not access team/platform/user-management data unless explicitly allowed.

## Assignment policy

Final assignable-role policy:

Leads:
- salesAgent
- marketing

Tasks:
- salesAgent
- marketing

Clients:
- salesAgent

Deals:
- salesAgent

Properties:
- salesAgent only if property assignment exists in the current business flow.
- Do not over-restrict property viewing if properties are intended as inventory.

Admin and Manager can manage assignment but should not appear as normal operational assignee options.
Viewer must never appear as assignable.

## Assignment snapshot requirements

Assigned records should store snapshots where module supports assignment:
- assignedTo
- assignedToName
- assignedToEmail where supported
- teamId
- teamName
- managerId
- managerName

When creating/reassigning:
- Copy snapshots from `companies/{companyId}/users/{uid}`.
- Do not trust manually typed team/manager values from UI.
- If assignedTo is empty, team/manager snapshot fields should be empty.
- If assignedTo is not empty, snapshots should match the selected assignee profile.

Old records:
- Must still load safely.
- Do not run destructive migration automatically.
- When edited/reassigned, refresh snapshots safely from assignee profile.

## Invitation onboarding rules

Invitation-code onboarding is the preferred SaaS company onboarding flow.

Platform owner creates invitation:
- Owner creates only invitation package/settings.
- Owner does not enter company name.
- Owner does not enter company email.
- Owner does not enter admin email.
- Invitation settings include plan/package, user limit, storage limit, enabled features, locale, timezone, expiry, and optional notes.
- Create Invitation should be shown as a polished modal bottom sheet, especially on mobile.
- Generated links must use the public web URL and hash route:
  `https://masarcrm.web.app/#/register-company?code=MASAR-XXXX-XXXX`
- Never use `Uri.base.origin` blindly on mobile because mobile may use `file://` and crash.

Company admin registration:
- Public route: `/register-company`.
- Link route: `/register-company?code=MASAR-XXXX-XXXX`.
- Invitation code can be auto-filled from the link.
- No company email field.
- No editable company ID field.
- Company ID/slug is generated automatically from company name and must be revalidated server-side.
- Admin email is enough as initial contact email.
- Admin enters his own password during company registration.
- Backend creates Firebase Auth user, company doc, company admin profile, global user doc, and membership doc.
- Registered admin must have full company admin powers.

Invitation reuse protection:
- A successfully accepted invitation must never be reusable.
- Deleting the created company must not make the same invitation code valid again.
- Use a permanent server-side usage marker outside the company doc, such as:
  `platform_invitation_uses/{invitationId}`.
- `validateCompanyInvitation` and `acceptCompanyInvitation` must check both invitation status and usage marker.

Duplicate checks:
- Use Firebase Auth `getUserByEmail` and global `users` email checks.
- Avoid broad `collectionGroup('users')` duplicate scans during registration unless a proper index/registry strategy is in place.
- Previous failure happened at `check_admin_email_company_users` due to a fragile collection-group query / `FAILED_PRECONDITION` style problem.

## Password and user-creation rules

First company admin:
- The first company admin chooses his own password in the Register Company form.
- Do not generate a setup link for the first admin.
- Do not store the password in Firestore.
- Do not log the password.
- Password is sent once to Firebase Auth createUser.

Normal company users created by company Admin:
- Default flow: create user and return setup/reset link.
- Admin sends setup/reset link to the user.
- User sets his own password.
- Admin should not know user passwords in the default flow.

Optional temporary password flow:
- Admin may optionally set a temporary password for a new user.
- Do not store the temporary password in Firestore.
- Backend creates Firebase Auth user with that temporary password.
- Company user profile must get:
  - `mustChangePassword: true`
  - `passwordSetupMethod: temporaryPassword`
- On login, the app must force `/force-change-password` before dashboard/CRM access.
- The user enters current temporary password + new password + confirm.
- `completeRequiredPasswordChange` clears `mustChangePassword` and updates safe password metadata.
- Normal Settings password change must remain working.

User management:
- Company Admin User Management route is `/users`.
- Sidebar item must appear only for Admin, above Team Management.
- Manager/Sales/Marketing/Viewer must be blocked from `/users` even by direct route.
- Create user dialog must access `CompanyUsersCubit` correctly, including when opened via `showDialog`/bottom sheet. Use `BlocProvider.value` when passing the existing Cubit into dialogs.

## Notifications and feature flags

Notifications + reminders are stable and must remain role/team scoped.

When company feature `notifications` is disabled:
- notification bell should hide or show disabled state according to design.
- notification streams must not start.
- `/notifications` must be blocked.
- notification center/menu entries must be hidden/disabled.
- no permission/error spam should appear.
- existing notification docs must not be deleted just because the feature is disabled.

## Audit logs and recent activity

Real audit logs are used for dashboard recent activity.

Audit logs should include:
- actor id/name/email/role
- module
- action
- record id/title/subtitle
- createdAt
- metadata/details where useful
- assignedTo when relevant
- teamId/teamName when relevant
- managerId/managerName when relevant

Admin Recent Activity:
- Company-wide.

Manager Recent Activity:
- Own team only.
- Must be scoped by managerId/teamId/actor fallback safely.
- Must not query all logs then filter client-side.
- Must not show other team activity.

Sales/Marketing/Viewer:
- No team/company activity unless an explicit future policy says otherwise.

Timeline and audit detail requirements:
- Normal record edits should create visible timeline/audit details where supported.
- Lead timeline must include normal `updated` events.
- Lead timeline should show changes for status, assignment, contact/follow-up, source/source details, budget, notes, preferred details, phone/email/name, etc.
- Admin/Manager recent activity should show useful changed-field details, not only generic text.
- Arabic old/new values should use `من old إلى new` with directional isolation where needed.

## Profile image rules

Profile images should be consistent across:
- app shell avatar
- mobile header avatar
- account menu avatar
- profile page
- settings account area if applicable
- platform user rows/cards
- team/member rows/cards
- assignee dropdowns where supported

Source priority:
1. company/platform user profile `photoUrl`
2. Firebase Auth `photoURL`
3. initials fallback

Rules:
- Do not store image bytes in Firestore.
- Do not clear `photoUrl` automatically just because an image load fails.
- Only clear profile image when user explicitly removes it.
- Use safe image loading and fallback initials.
- Do not log full profile image URLs/tokens in production or normal debug output.
- Remove noisy diagnostic prints before final handoff.

Storage rules:
- Users can upload/remove only their own profile image unless a safe server-side owner flow exists.
- Same company active users may need read access for avatars/user lists.
- Platform owner may need read access for platform user lists.
- Do not make all profile images globally public.

## Platform rules

Platform Dashboard must follow the same Masar CRM design system.

Platform owner/admin:
- Accesses `/platform` without company membership.
- Can manage companies and users through safe functions.
- Can preview selected company read-only.
- Can create invitation codes/links.
- Still keeps manual company/admin/user creation powers as a support/manual fallback.

Platform UI requirements:
- Must not feel like a separate app.
- Must reuse/match normal CRM shell/header/sidebar/cards/buttons/spacing.
- Company users should not be duplicated in multiple sections.
- User row actions should be compact action menus, not many wide buttons.
- Platform avatar menu must match normal role menu.
- Platform dashboard should stay organized like a SaaS control center: owner chip, company selector, KPI row, selected company operations, companies list, activity/login records, workspace summary.
- Security tab should not come back as a redundant tab; useful security/login info belongs in Overview/Workspace/Activity.

Platform account menu:
- Profile
- Settings
- Logout

Data Health:
- Platform Data Health is SaaS monitoring mode plus safe snapshot backfill only.
- Company Admin Data Health is operational action mode.
- Company Admin can run health checks, backfill safe assignment snapshots, reassign invalid/missing/inactive/ineligible assignee records, and notify the responsible manager through saved notifications.
- Data Health is Admin-only inside normal CRM. Managers must not see Data Health navigation or access `/data-health`.
- Platform owner must not manually reassign tenant business records.
- Backfill/reassign actions must use Cloud Functions/Admin SDK, not direct client-side mass writes.
- Data Health reports should remain visible after one run, including last run date/time, until the user runs the check again.
- After a successful repair/reassign action, remove the affected issue from the visible report without clearing the whole report.
- Do not perform destructive backfills automatically.

## Mobile behavior rules

Mobile avatar:
- Opens account menu with Profile, Settings, Logout.

Mobile More sheet:
- Module navigation only.
- No Profile/Settings/Logout.
- Dismiss by tapping outside.
- Dismiss by dragging down.
- Dismiss after selecting a module.

Mobile bottom nav:
- Hide on downward scroll.
- Show on upward scroll/top.
- Do not flicker.
- Do not hide while text input/keyboard interaction would hurt usability.
- Desktop/tablet navigation unaffected.

Tabs policy:
Use tabs only for section-heavy pages.

Tabs should exist or be considered for:
- Dashboard
- Lead Details
- Reports
- Team Management on mobile/narrow only
- Platform workspace if useful

Do not force tabs into normal list pages:
- Leads list
- Clients list
- Properties list
- Tasks list
- Deals list

Team Management specific:
- Mobile/narrow width: tabs are allowed.
- Web/desktop: no tabs; use professional dashboard-style sections.

## Global Search rules

Global Search is Firebase-only for now.

Rules:
- Debounce search around 300 ms.
- Minimum query length around 2 characters.
- Use limited one-shot queries where possible.
- No permanent global search streams.
- Group results by module.
- Tapping result opens correct details page if allowed.
- Do not show forbidden results.

Scope:
- Admin: company-wide allowed results.
- Manager: own team only.
- Sales/Marketing: own assigned only.
- Viewer: restricted.
- Platform owner: platform-safe search in platform context.

Do not introduce external search engines unless explicitly requested.

## Performance and lifecycle rules

Optimize for mobile scrolling and large app shell stability.

Avoid:
- unnecessary app shell rebuilds
- broad streams for restricted roles
- starting streams for hidden/forbidden tabs
- expensive sorting/filtering in build()
- huge nested scrolls that cause jank
- `shrinkWrap` on long lists unless justified
- leaking controllers/listeners/focus nodes
- noisy debug prints
- async work launched repeatedly from `build()`

Use:
- ListView.builder/GridView.builder for long lists
- debounced search
- stable keys where needed
- const widgets where safe
- local sorting only on small already-scoped result sets
- circular progress indicators for loading states
- mounted guards after async callbacks
- dispose timers/controllers/subscriptions/focus nodes
- unfocus before dialog/form submit on web/mobile when needed

Flutter Web hot restart / AppInspector / EngineFlutterView logs can be tooling noise, but app-owned timers/controllers must still be cleaned up.

## Current Cloud Functions and privileged flows

Important callable functions include:
- `saveLeadRecord` for lead create/update/reassign with server-side role/team/assignee validation.
- `getCompanyDataHealthReport` for platform SaaS monitoring.
- `getOperationalDataHealthReport` for company Admin Data Health.
- `backfillAssignedRecordSnapshots` for safe assignment/team snapshot backfill.
- `reassignDataHealthRecord` for company Admin operational reassignment repair.
- `createCompanyInvitation` for platform invitation creation.
- `validateCompanyInvitation` for public invite validation.
- `acceptCompanyInvitation` for company/admin registration through invite.
- `revokeCompanyInvitation` for platform invite revoke.
- `listCompanyInvitations` for platform invite management.
- `addUserToCompany` for platform owner/manual setup and company Admin user creation.
- `completeRequiredPasswordChange` for clearing temporary-password enforcement after user changes password.
- Platform user/company tools such as `createCompanyWithAdmin`, `setCompanyUserEmail`, `setCompanyUserPassword`, `generateCompanyUserPasswordResetLink`, `updateCompanyPlatformSettings`, `assignUserToTeam`, and `removeUserFromTeam`.

Rules:
- Keep privileged business-data repair/reassignment server-side.
- Do not move these flows into direct Flutter Firestore writes.
- When changing function names or adding new callables, report exact deploy commands.
- Do not log passwords, full invite codes, reset links, tokens, or secrets.

## Deployment reporting rules

In every final report, mention exact deployment needs:

If Firestore rules changed:
- `firebase deploy --only firestore:rules`

If Storage rules changed:
- `firebase deploy --only storage`
  or combined with Firestore if both changed.

If Functions changed:
- `firebase deploy --only functions:<functionName>`
  or `firebase deploy --only functions` if individual deploy fails.

If Flutter UI changed:
- `flutter build web --release --dart-define-from-file=config/firebase.local.json`
- `firebase deploy --only hosting`

If mobile assets/icons/native configuration changed:
- rebuild/reinstall the mobile app.

Do not claim deployment happened unless the user confirms it.

## Current latest known stable/in-progress fixes

The latest confirmed good state includes:
- Notifications + Reminders Foundation is stable.
- Saved notifications persist after refresh and read/unread behavior is stable.
- Manager/team notification routing works and notifications connect assigned users and managers.
- Appointments + Calendar Foundation added a company-scoped appointments workspace.
- Appointments support role-scoped schedules, related record snapshots, assignment/team snapshots, status actions, and appointment notifications.
- Lead create/update/reassign is stabilized through the `saveLeadRecord` Cloud Function.
- Admin can create/assign/reassign leads company-wide.
- Manager can assign/reassign only inside own team.
- Sales/Marketing can update own assigned leads where policy allows.
- Manager Recent Activity works and is scoped to team.
- Sales can edit own assigned lead after rules/snapshot fixes.
- Profile image debug console spam removed.
- Normal lead edits appear in lead timeline.
- Admin/Manager Recent Activity shows edit details.
- Arabic old/new value direction fixed using `من old إلى new`.
- Platform Data Health remains SaaS monitoring mode.
- Company Admin Data Health is implemented as Admin-only operational repair mode.
- Data Health reports persist after running until a new check is triggered.
- Data Health hides raw missing-assignee UIDs and shows clean issue labels.
- Data Health reassign/backfill repairs update the visible report without clearing it.
- Data Health Notify Manager is implemented for Admin through saved notifications.
- Phase A Admin/Owner Operations UI Cleanup is implemented: Admin Team Management is compact, Platform Security is merged into overview/workspace/activity, Platform login records are readable.
- Platform Owner dashboard reference polish is implemented: premium SaaS control-center layout with owner chip, company selector, KPI row, selected company operations, companies list, activity/login records, and workspace summary.
- Phase B invitation onboarding works after removing the fragile `check_admin_email_company_users` collectionGroup scan.
- Invitation reuse after company deletion is fixed using `platform_invitation_uses/{invitationId}`.
- Company Admin User Management exists and Admin can create company users.
- Optional temporary password flow exists and must force `/force-change-password`.
- Mobile onboarding/login/register/public route polish is mostly implemented.
- Splash/branding/logo work is in progress and needs final compile/runtime stabilization.
- Mobile More remains module navigation only; Profile/Settings/Logout belong to avatar menu.

Known current issue to resolve first:
- `MasarSplashGate` compile issue in `app.dart` even though `app.dart` imports `core/widgets/masar_splash_gate.dart`. Inspect actual `lib/core/widgets/masar_splash_gate.dart` and ensure the class is defined and file is saved correctly.
- GoogleFonts runtime/offline issue should be resolved either by system fallback or local bundled fonts.
- Splash logo still needs to be made larger and more premium.

## Recommended next phases

Immediate next phase:
- Phase B compile/runtime stabilization and release lock.
- Fix splash/branding compile issue, GoogleFonts runtime issue, logo size, public onboarding final polish.
- Run `flutter analyze` and `node --check functions/src/index.js` only if explicitly allowed.
- Deploy required functions/rules/hosting only after validation.
- Commit/push only after final confirmation.

After Phase B is locked:
1. Production Release QA + Deployment Stabilization.
2. Reports + Export / Business Intelligence phase.
3. Scheduled reminders engine Phase 2.
4. Global Search upgrade.
5. Final mobile/browser polish.
6. Public launch preparation.
