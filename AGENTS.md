# AGENTS.md — Masar CRM / مسار

## Project identity

Masar CRM / مسار is a production-grade real estate CRM SaaS built with Flutter Web/Mobile and Firebase.

Product identity:
- English name: `Masar CRM`
- Arabic name: `مسار`
- Meaning: path / journey / workflow.
- Business scope: real estate CRM for the full journey from lead → client → appointment → property → deal → task/follow-up → audit/export/notifications/release monitoring.
- Local project path: `C:\Users\islam\Desktop\real_estate_crm`
- Active branch: `dev`
- Firebase project: `real-escrm-ia`
- Live Hosting: `https://masarcrm.web.app`
- User-preferred workflow: strong mega prompts, scoped stabilization batches, exact reports, no hidden commands.

Core stack:
- Flutter Web/Mobile
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Hosting
- Firebase Cloud Messaging
- go_router
- BLoC/Cubit only
- Feature-first Clean Architecture
- Arabic/English localization with RTL/LTR

---

## Absolute rules for Codex / assistant work

These rules are mandatory.

- Follow this `AGENTS.md` first.
- Work on `dev` unless the user explicitly says otherwise.
- Do not run Flutter, Firebase, Git, npm, Dart, analyzer, build, deploy, commit, push, migrations, or package installation unless the user explicitly approves.
- Do not commit, push, deploy, or run migrations unless the user explicitly asks.
- Do not use `git add .` blindly.
- Do not stage temp files, ZIPs, local patches, screenshots, generated throwaway files, local editor folders, `build/`, `functions/node_modules/`, `.vscode/`, `android/.gradle/`, or `config/firebase.local.json`.
- Do not claim `flutter analyze`, build, deploy, rules deploy, Functions deploy, APK install, or manual QA passed unless it actually ran or the user confirmed it.
- Keep every change scoped to the user’s exact request.
- Do not touch unrelated files.
- Do not add new features during stabilization/release-lock/performance phases unless the user explicitly approves a new feature phase.
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
- Do not abbreviate or truncate important Arabic/English sentences with ellipsis unless the user explicitly asks. Use wrapping/responsive layout instead.
- Follow the existing Masar design system. Do not create generic admin-template UI.
- Use circular progress indicators for action/save/loading states where appropriate; prefer overlays when existing content can remain visible.
- Shimmer is for content loading only; action buttons should use circular spinners.
- Be direct, precise, and honest in reports.
- No emojis.

---

## Current status and release context

Latest active working context is around `v2.31.3+105`.

Important: treat `v2.31.3+105` as local/current working context unless the user explicitly confirms it was committed, pushed, built, or deployed.

Recent completed/local-good items:
- Release Intelligence and Device Lifecycle Monitoring was implemented around `v2.31.0+102`.
- Release Center UI/semantics polish moved the platform release area toward a professional Release Center around `v2.31.1+103`.
- Arabic localization corruption was repaired after mojibake appeared in the Arabic login/UI. Future l10n work must not use unsafe PowerShell/terminal rewriting for Arabic and should not manually edit generated localization Dart files except as a controlled recovery step.
- Dashboard trend work was applied after the user requested the performance trend to look like a straight horizontal trend chart, not a curved daily-activity-only line.
- Dashboard performance trend now uses a Total/Daily mode:
  - Default: Total, so quiet days do not drop the line to zero.
  - Daily mode remains available and can show zero on days with no daily activity.
  - Trend line uses straight segments, not curves.
  - Filter supports All and individual series.
  - Legend/colors exist for visible series.
- Dashboard urgent actions/sidebar cards were improved to show clearer reason/type, record title, due time/age, assignee, and record type badge.
- A dashboard `_CardHeader` corruption/overflow issue was fixed by restoring `_CardHeader` as a normal reusable header. The broken version had unrelated chart-control code accidentally inserted into `_CardHeader`.

Do not assume the following are completed unless the user confirms:
- `flutter analyze`
- Web release build
- Hosting deploy
- Android APK build/install
- Git commit/push
- Firebase Functions/rules/index deploy

Immediate next planned major phase:
- Production Performance and Firestore Cost Optimization.
- This must be split into controlled phases to avoid breaking the app.

Recommended optimization phases:
1. Performance and Firestore Cost Audit — read-only inspection, no behavior changes.
2. Query Limits and Role-Scoped Read Optimization.
3. Stream Lifecycle and Hidden Listener Cleanup.
4. Flutter Rebuild and UI Rendering Optimization.
5. Slow Network Mutation Reliability.
6. Index, Aggregation, and Data Retention Cleanup.
7. Production Profiling and Release Lock.

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
- Arabic must be natural and product-quality, not literal machine translation.
- Add English and Arabic messages together when adding validation/errors.
- Use RTL-safe layout:
  - `EdgeInsetsDirectional`
  - `AlignmentDirectional`
  - `PositionedDirectional`
  - `BorderRadiusDirectional` where appropriate
- Test mixed Arabic/English/numbers in RTL.
- Do not use ellipsis for important explanatory/support/warning/guidance text.
- Compact layout must still show full Arabic/English copy through wrapping, responsive layout, or smaller spacing.
- Do not manually edit generated localization Dart files as a normal workflow:
  - `lib/l10n/app_localizations.dart`
  - `lib/l10n/app_localizations_ar.dart`
  - `lib/l10n/app_localizations_en.dart`
- Normal l10n workflow is:
  - edit `lib/l10n/app_en.arb`
  - edit `lib/l10n/app_ar.arb`
  - regenerate l10n only when the user permits Flutter commands.
- Do not use unsafe PowerShell/terminal JSON rewrites for Arabic strings. Preserve UTF-8.
- Search for mojibake after Arabic changes when relevant: `Ø`, `Ù`, `Â`, `�`, repeated broken sequences like `ط§` and `ظ„` inside UI strings.

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
- Add animation that hurts Web/Android performance.

Dashboard design reminders:
- Dashboard chart trend should use straight line segments when showing the short-term trend style requested by the user.
- Default trend mode should be Total, not Daily, so it does not visually drop to zero on quiet days.
- Daily mode may show zero and must be clearly labeled as daily activity.
- All filter should show all visible series with legend/colors, not silently choose one series.
- Sidebar urgent/action cards must explain why the item is urgent, not only show a name/time.

---

## Role and permission model

Roles:
- Platform Owner
- Admin
- Manager
- Sales Agent
- Marketing
- Viewer

Core role expectations:
- Platform Owner manages platform/company controls, release intelligence, platform notifications, invites, company settings, and global platform views.
- Platform Owner must not be treated as a normal company CRM user unless explicitly in preview/company context.
- Admin has full company CRM control within company boundaries.
- Manager sees/manages their team scope only unless a specific Admin-only feature is involved.
- Sales Agent/Marketing see assigned/self/team-allowed records only according to rules.
- Viewer is read-only/restricted.

Security rules:
- Never weaken Firestore rules to make UI pass.
- Company isolation is mandatory.
- Manager team isolation is mandatory.
- Do not allow Manager Team 2 to see/select Team 1 records.
- Do not query broad data for restricted roles and filter client-side.
- Firestore rules must be compatible with app queries; app queries must include required where/order/limit constraints.
- If a page is role-denied, do not start denied streams.
- Do not show restricted navigation entries for roles that cannot access the module.

---

## Firebase and backend rules

- Firebase calls stay in data sources or Cloud Functions.
- Cloud Functions/Admin SDK must be used for privileged operations.
- Do not store server credentials in Flutter.
- FCM push must be sent from Cloud Functions/Admin SDK only.
- Every push notification must have an in-app notification first.
- Not every in-app notification should push.
- Push only for important/urgent/critical `pushEligible` events.
- Do not push normal CRUD/audit noise.
- Do not expose full FCM tokens in UI.
- Token/device status UI may show short token hash prefix only when needed.
- Notification token lifecycle, device lifecycle, and release intelligence are separate concerns:
  - notification token = push delivery
  - device install = adoption/lifecycle
  - release registry = published versions/policies
  - version history = previous builds/devices moved between builds

---

## Release Intelligence / Device Lifecycle status

Release Intelligence and Device Lifecycle Monitoring exists and should continue to be treated as a platform-owner-only capability.

Expected concepts:
- Release Registry (`platform_releases`) tracks what was published/prepared.
- Device install registry tracks active Web/Android devices even if notification permission fails.
- Version history/events track build/version changes over time.
- Session heartbeat updates last seen without excessive writes.
- Push health is separate from adoption.
- Android forced-update policy remains separate from release history.

Professional distinctions that must remain true:
- Release policy is not release history.
- Notification token is not device install.
- Current adoption is not historical usage.
- Android adoption is not Web adoption.
- Push permission health is not app adoption.
- A user can have multiple devices.
- A device can exist even if notifications are blocked.

Release Center should be platform-owner only and should not expose company data to company roles.

---

## Performance and Firestore cost optimization rules

The next major phase is optimization. Do it in small safe phases.

Phase 1 must be audit-only:
- No behavior changes.
- No refactors.
- No query changes.
- Produce a table/report of risky queries, streams, hidden listeners, duplicate listeners, client-side filters, missing limits, and rebuild hotspots.

Optimization goals:
- Reduce Firestore reads.
- Avoid broad streams.
- Stop hidden tab/page streams.
- Avoid duplicate shell/page listeners.
- Add limits/date windows/pagination where safe.
- Keep role scoping server-side.
- Move heavy non-critical startup services after critical UI is usable.
- Avoid expensive calculations inside `build()`.
- Use `BlocSelector`/narrow builders where useful.
- Use `ListView.builder`/pagination for long lists.
- Debounce search/filter changes.
- Keep dashboard and release center performant.
- Keep mutation/save flows reliable under slow networks.

Do not optimize blindly. Every query change must preserve role permissions, results correctness, indexes, and UI expectations.

---

## Slow network and mutation reliability rules

Write actions must be reliable under slow network:
- No success snackbar before confirmed write.
- No infinite spinner.
- No duplicate submit.
- Save buttons disabled while saving.
- If stream update is delayed, UI must still reconcile safely after confirmed write.
- Do not report false “no internet” for permission/scope/index errors.
- Error messages must be accurate and localized.

Audit all major write flows before claiming reliability:
- Create/edit/assign leads.
- Create/edit/assign clients.
- Create/edit properties/images.
- Create/edit/complete/cancel tasks.
- Create/edit/reschedule/complete/cancel appointments.
- Create/edit/stage-change/archive deals.
- Team assignment/removal.
- User activation/deactivation/password/reset flows.
- Report/export generation.
- Notification enable/retry.
- Android release policy updates.

---

## Dashboard current expectations

The dashboard currently contains:
- KPI strip/cards.
- Sales Command Center / Smart Suggestions.
- Today rail / urgent actions / recent activity.
- Deals stage chart.
- Lead source chart.
- Performance trend chart.
- Team/agent activity results.
- Opportunity cards.

Current dashboard performance trend requirements:
- Use `fl_chart`; no new chart package unless absolutely necessary and approved.
- Default trend mode: Total.
- Optional mode: Daily.
- Total mode should show running totals and not drop to zero just because a day has no new records.
- Daily mode may show zero and must be clearly labeled.
- Line must use straight segments (`isCurved: false`) for the trend style requested by the user.
- All filter should show multiple series together.
- Individual filters should show only the selected series.
- Legend must be visible and localized.
- Chart controls must wrap/responsively fit in Arabic and English.
- `_CardHeader` must remain a generic reusable header and must not contain trend-specific controls or undefined variables.

---

## Current important completed modules/phases

Treat these as implemented unless later evidence says otherwise:
- Auth/company session/platform owner foundation.
- Company-scoped CRM modules: Leads, Clients, Properties, Tasks, Deals, Appointments.
- Team hierarchy / manager teams.
- Manager visibility and assignment policy work.
- Platform Owner dashboard and company controls.
- Platform settings/features/limits.
- Password management and login activity.
- Dashboard Recent Activity from real audit logs.
- Audit log write foundation.
- Audit Log Viewer basics.
- Reports/export foundation, Excel-only export cleanup.
- Notifications Phase 1 in-app notification system.
- FCM Phase 1 classification.
- FCM token setup and Web/Android push sender work.
- Web FCM foreground/release fixes and token invalidation recovery.
- Android forced-update/release management flow.
- Release Intelligence and Device Lifecycle Monitoring.
- Support Center basics.
- Appointments calendar upgrade.
- Production hardening batches around stale sessions, role-gated streams, and export cleanup.

Treat deploy/build/test status as unknown unless user confirms for the exact current version.

---

## Known sensitive areas / do not break

High-risk areas:
- Firestore rules and role-scoped queries.
- Manager/team visibility.
- Sales/Marketing restricted reads.
- Platform Owner vs company user shell/session.
- FCM Web foreground/background behavior.
- Notification token/device lifecycle.
- Release Center/release policy.
- Arabic localization encoding.
- Dashboard chart/header layout in RTL.
- Property image upload and Storage rules.
- Slow-network mutation consistency.
- Export/audit visibility rules.

Before touching any of these, inspect current code and give a scoped plan.

---

## Reporting format required

At the end of every Codex/assistant task, report:

```text
Summary:
- What changed.

Files changed:
- exact file paths.

Validation:
- What was actually run.
- What passed.
- What was not run.

Deploy requirements:
- Functions deploy needed: yes/no.
- Firestore rules deploy needed: yes/no.
- Firestore indexes deploy needed: yes/no.
- Hosting build/deploy needed: yes/no.
- Android APK rebuild needed: yes/no.

Manual QA:
- Exact steps the user should test.

Risks:
- Remaining risks or assumptions.
```

Never claim commands ran unless they ran.
Never hide uncertainty.
