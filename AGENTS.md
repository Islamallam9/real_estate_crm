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
- Do not call Firestore/Storage/Auth directly from widgets or Cubits except through existing repository/data source boundaries.
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

## Versioning rule

For every major user-facing, security, data, or platform phase:
- Update `pubspec.yaml` version.
- Update `AppConstants.appVersion`.
- Update `AppConstants.appBuildNumber`.
- Settings must show the current app version/build.
- Mention the version update in the final report.

Do not bump version for tiny compile-only fixes unless the user asks.

Current known version after Appointments + Calendar Foundation Phase 1:
- Around `1.4.0+13`.

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
- platform admin fields

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

Manager:
- Sees own team records only.
- Can assign/reassign only to eligible users in own team.
- Dashboard and reports must be team-only.
- Recent Activity must be team-only.
- Must not see other managers’ teams/records/activity.

Sales Agent:
- Sees only own assigned records.
- Must not see all company leads/clients/tasks/deals.
- Must not see unassigned leads.
- Must not see other users’ records.
- Can update own assigned records only where current policy allows.

Marketing:
- Sees only own assigned records unless an explicit policy changes this.
- Must not see unassigned leads by default.
- Must not access other users’ records through search, filters, reports, or direct routes.

Viewer:
- Restricted/read-only according to policy.
- Must not appear as assignable.
- Must not access team/platform management data unless explicitly allowed.

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

Platform UI requirements:
- Must not feel like a separate app.
- Must reuse/match normal CRM shell/header/sidebar/cards/buttons/spacing.
- Company users should not be duplicated in multiple sections.
- User row actions should be compact action menus, not many wide buttons.
- Platform avatar menu must match normal role menu.

Platform account menu:
- Profile
- Settings
- Logout

Data Health:
- Platform Data Health is SaaS monitoring mode plus safe snapshot backfill only.
- Company Admin Data Health is operational action mode.
- Company Admin can run health checks, backfill safe assignment snapshots, and reassign invalid/missing/inactive/ineligible assignee records.
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

## Performance rules

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

Use:
- ListView.builder/GridView.builder for long lists
- debounced search
- stable keys where needed
- const widgets where safe
- local sorting only on small already-scoped result sets
- circular progress indicators for loading states

## Current Cloud Functions and privileged flows

Important callable functions include:
- `saveLeadRecord` for lead create/update/reassign with server-side role/team/assignee validation.
- `getCompanyDataHealthReport` for platform SaaS monitoring.
- `getOperationalDataHealthReport` for company Admin Data Health.
- `backfillAssignedRecordSnapshots` for safe assignment/team snapshot backfill.
- `reassignDataHealthRecord` for company Admin operational reassignment repair.
- Platform user/company tools such as `createCompanyWithAdmin`, `addUserToCompany`, `setCompanyUserEmail`, `setCompanyUserPassword`, `generateCompanyUserPasswordResetLink`, `updateCompanyPlatformSettings`, `assignUserToTeam`, and `removeUserFromTeam`.

Rules:
- Keep privileged business-data repair/reassignment server-side.
- Do not move these flows into direct Flutter Firestore writes.
- When changing function names or adding new callables, report exact deploy commands.

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

Do not claim deployment happened unless the user confirms it.

## Current latest known stable fixes

The latest confirmed good state includes:
- Notifications + Reminders Foundation Phase 1.2 is stable.
- Saved notifications persist after refresh and read/unread behavior is stable.
- Manager/team notification routing works and notifications connect assigned users and managers.
- Appointments + Calendar Foundation Phase 1 added a company-scoped appointments workspace.
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
- Mobile More remains module navigation only; Profile/Settings/Logout belong to avatar menu.

## Recommended next phases

Option A — Appointments Phase 1.1 polish:
- Dashboard appointment cards.
- Notification-center appointment attention reminders.
- Global Search appointment results.
- Appointment detail timeline/audit polish.

Option B — Calendar depth:
- Calendar-style appointments/follow-ups.
- More advanced appointment grouping.
- Optional recurring appointments.
- Later Google/Outlook sync.

Option C — Data Health polish if needed:
- Repair history.
- Export health report.
- Bulk safe snapshot backfill after manual confirmation.
- Notify company admin/manager after Notifications foundation exists.

Recommendation:
Move to Appointments Phase 1.1 polish next unless Appointments Phase 1 testing reveals blocking issues.


## Latest Data Health ownership rule

Platform owner Data Health is SaaS monitoring plus safe snapshot backfill only. Company Admin Data Health is operational action mode and can reassign invalid records. Manager Data Health is currently removed/disabled; Managers should not see Data Health navigation or access `/data-health`. Notification buttons may remain disabled placeholders until the Notifications foundation is implemented.
