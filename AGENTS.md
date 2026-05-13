# AGENTS.md

## Project Name

Masar CRM

## Project Description

Masar CRM is a full functional CRM system for a real estate company.

It is built using Flutter for web/mobile with Firebase as the backend.

The project must be clean, scalable, professional, secure, and easy to maintain.

The app is not a simple demo.

It should be treated as a real production project.

---

# Main Technology Stack

## Frontend

- Flutter
- Flutter Web
- Flutter Mobile
- BLoC / Cubit state management
- go_router for navigation
- Firebase SDKs
- Responsive UI for desktop, tablet, and mobile
- Flutter localization for Arabic and English
- RTL support for Arabic
- LTR support for English

## Backend / Cloud

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions when needed
- Firebase Cloud Messaging when needed
- Firebase Hosting for Flutter Web
- Firebase Security Rules

---

# Main Goal

Build a real estate CRM that allows a real estate company to manage:

- Users
- Roles
- Leads
- Clients
- Properties
- Deals
- Tasks
- Follow-ups
- Appointments
- Notifications
- Reports
- Audit logs

The system should support both mobile and web.

---

# Very Important Rules

## General Rules

- Do not generate the full CRM at once.
- Work module by module.
- Keep the code clean and readable.
- Do not create unnecessary abstractions.
- Do not modify unrelated files.
- Do not rewrite the whole project unless explicitly requested.
- Do not add packages unless they are needed.
- Do not use random architecture decisions.
- Do not mix UI, business logic, and Firebase logic together.
- Do not put Firebase calls directly inside widgets.
- Do not put business logic inside UI widgets.
- Do not create huge files.
- Keep each file focused on one responsibility.
- Avoid changing Firestore structure unless explicitly requested.
- Avoid changing permission/security logic unless explicitly requested.
- Do not rename Firebase project IDs, package IDs, app IDs, bundle IDs, or Hosting targets unless explicitly requested.

---

# Codex Operational Defaults

These rules apply to every Codex task unless the user explicitly says otherwise.

## Working Branch

- Work on branch `dev`.
- Do not work directly on `main`.
- Do not assume changes are committed.
- Keep each task focused.

## Command Usage

- Do not run CLI commands unless explicitly requested.
- Do not run:
  - flutter analyze
  - flutter pub get
  - flutter gen-l10n
  - dart format
  - flutter run
  - flutter build
  - firebase commands
  - git commands
- The user will run checks locally.
- Only edit files and report changed files.

## File Editing Rules

- Do not touch unrelated files.
- Do not format broad folders.
- Do not run broad formatting like `dart format lib`.
- If formatting is needed, format only the files changed by the task.
- If a reusable widget API is unknown, inspect the existing widget file before using it.
- Do not assume constructor names for existing widgets.
- Do not create duplicate UI components if an existing reusable component can be used.
- Do not leave temporary zip, patch, or generated test files inside the repo.

## Reporting Format

After every task, report using this format:

```text
Files changed:
- file 1
- file 2

What was implemented:
- explanation

How to test:
- step 1
- step 2

Assumptions:
- assumption 1

Remaining issues:
- issue 1
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
- Domain entities should not depend on Firebase SDKs.
- Data models should handle Firebase mapping.
- Presentation widgets should remain UI-focused.
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
    errors/
  presentation/
    cubit/
    pages/
    widgets/
```

---

# Firebase and Company Isolation Defaults

Firestore data must remain company-scoped.

Main company-scoped structure:

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

- Do not expose one company’s data to another company.
- Do not rely only on UI hiding.
- Permission checks must exist in app logic and Firebase rules.
- Keep Firebase access inside data sources.
- Validate `companyId`.
- Validate active users where appropriate.
- Do not show raw Firestore document IDs in the UI unless explicitly needed.
- Do not store private credentials in the Flutter app.
- Never commit service account keys or private credentials.

---

# Roles and Permissions

The app supports role-based access.

Known roles:

```text
admin
manager
salesAgent
marketing
viewer
```

Rules:

- Do not invent new role behavior casually.
- Use existing permission helpers/services where available.
- Do not bypass permissions in UI.
- Do not rely only on UI hiding.
- Firestore/Storage rules must enforce critical permissions.
- Sales Agent can view only where existing permission logic says view-only.
- Manager/team hierarchy is planned later and must not be mixed into unrelated module work.
- Do not add team visibility logic until the manager/team hierarchy phase.

---

# Localization and RTL/LTR Rules

The app supports:

```text
English
Arabic
```

Rules:

- All visible UI text must be localized.
- Do not hardcode visible strings.
- Add keys to:
  - app_en.arb
  - app_ar.arb
- Update generated localization files if the repo stores them.
- Arabic must use RTL correctly.
- English must use LTR correctly.
- Use direction-aware widgets when needed:
  - EdgeInsetsDirectional
  - AlignmentDirectional
  - PositionedDirectional
- Do not leave English fallback text in Arabic mode.
- Check ARB commas carefully.
- Generated localization files must match ARB keys.
- Do not mix Arabic text into English mode unless it is actual user data.

---

# UI and Visual Identity

## Current Visual Direction

Masar CRM should feel like a warm premium real estate CRM.

Use:

- Cream / warm off-white workspace
- Premium amber primary action
- White/warm cards
- Soft beige-gray borders
- Charcoal/dark brown text
- Calm semantic colors
- Professional spacing
- Practical business UI

Avoid:

- Generic purple/blue AI dashboard style
- Glassmorphism
- Huge shadows
- Glowing cards
- Random gradients
- Decorative AI-looking effects
- Fake SaaS template look
- Flashy animation
- Bouncing animation
- Infinite animation loops
- Auto-scrolling activity feeds

The UI should feel like a real internal business application used by sales teams.

## Design Quality Checklist

Before finishing any screen, check:

- Does this look like a real CRM screen?
- Is the layout useful or only decorative?
- Is the spacing consistent?
- Are actions clear?
- Is the page easy to scan?
- Is the mobile version usable?
- Is the web version professional?
- Are colors consistent?
- Are loading, empty, and error states handled?
- Is there any generic AI-style decoration that should be removed?

---

# Loading, Saving, and Feedback Rules

- Network/database actions must show loading feedback.
- Use circular progress indicators for loading states.
- Prefer overlay loading where existing content can remain visible.
- Forms should disable fields while saving.
- Buttons that trigger Firebase/Auth/database/network work must show pending state.
- Async save buttons must stay disabled until the request completes.
- Show final success/error feedback through existing snackbar/feedback components.
- Avoid duplicated snackbars.
- Actions that only open menus, routes, sheets, or filters do not need database loading.
- Do not leave UI stuck in saving/loading state after failure.
- For long image uploads, use longer upload-specific timeout logic instead of forcing all Firebase actions to wait too long.

---

# Implemented Modules and Current Status

These notes are the current source of truth after the latest Properties image upload and responsive property cards phase.

- Authentication, login, logout, user profile loading, and protected routing are implemented.
- Leads are implemented and tested for the current phase.
- Properties are implemented and tested for the current phase.
- Clients are implemented and tested for the current phase.
- Tasks and follow-ups are implemented and tested enough to move forward.
- Deals are implemented and connected to Leads, Clients, Properties, Tasks where relevant, Dashboard, and Reports.
- Dashboard is implemented with real data, useful KPI cards, analytics charts, quick actions, recent activity, deals/tasks summaries, follow-up sections, responsive layout, and professional motion polish.
- Reports is implemented with period/search/filter controls, summary KPIs, lead/deal/task/property reports, agent activity/results, animated charts/bars, and responsive layout.
- Recent Activity on Dashboard is visible only to Admin and Manager for now.
- Sales Agent must not see Recent Activity.
- Recent Activity is currently based on latest accessible record updates, not a full audit-log event stream.
- Do not call Recent Activity “Audit Log” or “System History” yet.
- Profile and Settings exist/planned as basic user-facing screens; do not expand them unless explicitly requested.
- Manager/team hierarchy is planned later and must not be mixed into unrelated module work.
- Property image upload and Cloud Storage rules are implemented for the current phase, but still need final QA before production deployment.
- Advanced notifications, appointments, and real audit-log implementation are future phases.

---

# Current Dashboard and Reports UI/Motion Status

- Dashboard KPI cards use a balanced responsive grid instead of uneven wrapping.
- Dashboard and Reports use subtle but noticeable professional motion:
  - section reveal
  - scroll reveal where added
  - card hover/tap lift
  - count-up numbers
  - animated donut sweeps
  - animated legends
  - animated progress bars
- `visibility_detector` is currently approved and used for Dashboard/Reports scroll reveal behavior.
- `VisibilityDetectorController.instance.updateInterval` is configured in `main.dart` to reduce scroll jank.
- Animations must remain professional:
  - no bouncing
  - no glowing
  - no infinite movement
  - no auto-scrolling activity feed
  - no distracting decorative animation
- If scrolling becomes janky, prefer tuning reveal thresholds, durations, updateInterval, and reducing heavy shadows before adding more animation packages.
- Do not remove `visibility_detector` unless replacing the scroll reveal approach intentionally.

---

# Current Mobile Dashboard Rule

- Mobile Dashboard uses a floating quick-add FAB for allowed quick actions according to permissions.
- The old mobile quick-action panel/cards should stay hidden/removed on mobile.
- Desktop/tablet quick actions may remain.
- Add Client quick action is admin/manager only.
- Add Lead follows the existing create-lead permission logic.
- Recent Activity remains hidden for Sales Agent on all screen sizes.

---

# Properties Module Current Status

The Properties module currently includes:

- Property list
- Property create
- Property edit
- Property details
- Search/filter
- Deactivate/soft archive flow
- Role-aware behavior
- Property image upload
- Firebase Storage integration
- Responsive property card grid
- Image carousel in property cards
- Image gallery on property details
- Mobile/web picker fixes

## Property Image Data Fields

Property supports these image fields:

```text
imageUrls
coverImageUrl
imageStoragePaths
```

Rules:

- Existing old properties without images must keep working.
- Mapping must be backward-compatible.
- Do not show raw Storage paths or Firestore IDs in UI.
- `coverImageUrl` should resolve safely from existing images.
- Removed images should delete Storage objects where practical.

## Property Storage Path

Use this Storage path:

```text
companies/{companyId}/properties/{propertyId}/images/{fileName}
```

Rules:

- Keep path company-scoped.
- Validate active authenticated company user.
- Validate role permissions.
- Validate image content type.
- Validate image size.
- Do not weaken Storage rules to make upload work.
- Deploy Storage rules separately when needed.

## Property Image Picker

Current decision:

- Use `file_picker` for production web/mobile browser.
- Do not use `image_picker` for property images on production web.
- `file_picker` must use:
  - `FilePicker.pickFiles`
  - `type: FileType.image`
  - `allowMultiple: false`
  - `withData: true`
- Single image selection is used per picker action.
- Users can add multiple images by pressing Add Image more than once.
- This is more stable on mobile web/Safari.

## Property Image Compression Decision

Current decision:

- Do not use client-side compression on Flutter Web for now.
- Dart image compression/resizing caused UI stalling/freezing.
- Even `compute()` did not solve the web UX well enough.
- Current production behavior:
  - pick image
  - preview quickly
  - upload original bytes
- Long-term better solution:
  - server-side image resize/compression through Cloud Functions or Firebase image resizing extension/flow.

## Property Upload Timeout Rule

There was a previous 10-second Cubit timeout that killed image uploads.

Current rule:

- Simple Firebase actions may keep a short timeout.
- Property create/update with images must use a longer upload-specific timeout.
- Remote data source may use longer Storage upload timeout and Firestore write timeout.
- Do not apply a very long timeout to every Firebase action globally.
- Use longer timeout only where upload work needs it.

## Property Card Grid

Current behavior:

- Property table view was replaced by responsive card grid.
- Desktop should show up to 4 cards per row when content width allows.
- Medium/tablet should show around 3 cards.
- Mobile/small width should show 2 cards if layout remains usable.
- Avoid yellow overflow.
- Card height must account for wrapped chips/text.
- The card itself opens property details.
- Avoid cluttered bottom action rows.
- Use compact card captions.

## Property Card Images

Current behavior:

- Property cards use hotel-style image carousel.
- Use arrow buttons for image navigation.
- Disable PageView swipe physics to avoid browser trackpad back/forward gesture problems.
- Limit grid carousel images to avoid excessive loading.
- Details page can show more images than the card.

Important web image rule:

- `cached_network_image` may fail or not display Firebase Storage URLs correctly on Flutter Web.
- For Flutter Web, prefer:

```dart
Image.network(
  url,
  fit: BoxFit.cover,
  alignment: Alignment.center,
  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
  errorBuilder: ...
)
```

- `CachedNetworkImage` may be kept for non-web/native later if useful.
- If images disappear on web, check `property_card.dart` first.

---

# Saved Tasks Backlog

- Verify Tasks support related Deal records now that Deals exists; improve if any flow still lacks Deal linking/display.
- Check/fix duplicated `initialDate` in the task form if present.
- Improve complete/cancel row action state if practical.
- Avoid relying only on global `TasksStatus.saving` for row-level actions if practical.
- Make complete/cancel success handling less fragile than checking Cubit state immediately after await if practical.
- Verify create/edit Task form fields are disabled while saving.
- Verify save button shows spinner until the async request fully completes.
- Verify task create/edit/complete/cancel/filter/search behavior at runtime.
- Do not add manager-team logic to Tasks yet.

---

# Future Phases

Recommended order:

```text
1. Finish Properties QA and deployment checks
2. Real audit_logs system
3. Security rules hardening
4. Appointments module
5. Notifications
6. Manager/team hierarchy
7. Final mobile/browser polish
8. Deployment QA
```

## Real Audit Logs

Current Dashboard Recent Activity is not a true audit log.

Future audit logs should use:

```text
companies/{companyId}/audit_logs/{auditLogId}
```

Track important actions:

- create
- update
- archive/deactivate
- delete if allowed
- assign
- status change
- deal stage change
- task completion/cancel
- login/activity events only if needed later

Rules:

- Do not call current Recent Activity an Audit Log.
- Audit logs should be company-scoped.
- Audit log writes should be reliable.
- Sensitive values should not be logged unnecessarily.
- Show clear activity history for Admin/Manager.
- Manager/team filtering should wait until team hierarchy exists.

## Security Rules Hardening

Future review should cover:

- Firestore company isolation
- Storage company isolation
- user active status
- role permissions
- create/update/delete separation
- no public access
- no client-side-only permission enforcement
- no test rules left in production

## Appointments

Future Appointments module may include:

- linked lead/client/property/deal
- date/time
- assigned user
- status
- notes
- calendar/list views
- reminder-ready structure

## Notifications

Future notifications may include:

- follow-up reminders
- task due/overdue alerts
- assignment notifications
- appointment reminders
- later FCM integration

## Manager/Team Hierarchy

Future manager/team hierarchy should define:

- teams
- manager visibility
- sales agent assigned-only visibility
- team dashboards
- team reports
- rules-level enforcement

Do not mix this into unrelated module work.

---

# Environment Management

The project should use two main environments:

```text
development
production
```

## Branch Rules

Use this branch strategy:

```text
dev  -> development
main -> production
```

## Development Environment

The `dev` branch is used for active development.

Rules:

- All normal development work should happen on the `dev` branch.
- Experimental changes should not be made directly on `main`.
- Development Firebase configuration should be used while working on `dev`.
- Development data can be used for testing, but it should still follow the real data structure.
- Do not use production Firebase data for risky experiments.

## Production Environment

The `main` branch is used for production releases.

Rules:

- Only stable, reviewed, and tested code should be merged into `main`.
- Production Firebase configuration should only be used for production.
- Do not deploy untested changes to production.
- Do not connect local experiments to production Firebase unless explicitly requested.
- Do not make destructive production data changes without a clear migration and rollback plan.

## Firebase Environment Rules

- Use separate Firebase projects or clearly separated Firebase configuration for development and production.
- Never commit private keys, service account files, secrets, or local environment files.
- Firebase config files should be handled carefully.
- Do not expose admin credentials in the Flutter app.
- Any Firebase configuration change must be explained clearly before implementation.

---

# Release and Deployment Workflow

All deployments should follow a safe release workflow.

## Deployment Flow

Use this workflow:

```text
Develop
Analyze
Test
Build
Verify
Deploy
Monitor
```

## Deployment Rules

Before deployment:

- Run `flutter analyze`
- Run tests when available
- Run `flutter build web --release`
- Verify responsive layouts
- Verify RTL and LTR layouts
- Verify authentication and permissions
- Verify Firebase rules impact
- Verify Storage rules impact if Storage was changed
- Verify production after deployment

Deployment rules:

- Do not deploy directly from unfinished code.
- Deploy only stable changes.
- Keep deployments focused when possible.
- Monitor Firebase usage after deployment.
- Check browser reload behavior after deployment.
- Check mobile browser behavior after deployment.

## Firebase Hosting Rules

- Use Firebase Hosting for Flutter Web deployment.
- Do not run `firebase init` repeatedly unless explicitly required.
- Use deployment automation when practical.
- Production deployment should come from stable code only.
- Firebase Hosting config may live in `firebase.json`.
- It is normal to commit `firebase.json`.
- Do not commit secrets.

---

# Security Rules Testing

Security rules must be treated as part of the application logic.

Rules:

- Firestore rules must be tested with allowed and denied scenarios.
- Storage rules must be tested with allowed and denied scenarios.
- Never weaken rules just to make UI features work.
- Fix architecture or queries instead of opening public access.
- Company isolation is mandatory.
- User role checks must exist in Firestore/Storage rules where needed.
- User active status must be validated when appropriate.
- Rules should protect reads, writes, updates, and deletes separately.
- Temporary testing permissions must not remain in production.

Never allow this in production:

```text
allow read, write: if true;
```

---

# Data Migration Rules

Firestore structure changes must be handled carefully.

Rules:

- Do not rename important fields casually.
- Do not delete production fields without understanding impact.
- Any breaking schema change should include a migration plan.
- Avoid destructive data operations.
- Explain migration impact before implementation.
- Prefer backward-compatible changes when possible.
- Large data changes should support rollback when practical.
- Existing documents may not have newly added fields; code must use safe defaults.

---

# Monitoring and Logging

Production monitoring is required.

Rules:

- Important failures should be logged.
- Sensitive CRM actions should create audit logs in the future.
- Do not log passwords or private credentials.
- Monitor Firebase usage and billing risk.
- Watch Firestore read/write usage.
- Watch Storage usage and bandwidth.
- Log important backend failures when practical.
- Track authentication failures when useful.

---

# Performance Rules

Performance matters for both web and mobile.

Rules:

- Avoid unnecessary rebuilds.
- Avoid loading entire collections.
- Use pagination or lazy loading for large lists.
- Split large widgets into smaller reusable widgets.
- Prefer const widgets when practical.
- Avoid deeply nested widget trees when unnecessary.
- Optimize Firestore queries carefully.
- Avoid expensive rebuilds inside lists.
- Keep web performance in mind when adding animations or heavy layouts.
- Avoid CPU-heavy synchronous image processing on Flutter Web.
- Do not add client-side image compression unless it is proven smooth on production web/mobile.
- Limit image loading in grids.
- Avoid loading too many large images at once.
- Prefer server-side image optimization in the future.

---

# Accessibility Rules

The CRM should remain usable and readable.

Rules:

- Buttons should have clear labels.
- Forms should remain readable on all screen sizes.
- Avoid relying only on color for status communication.
- Use readable contrast.
- Error messages should be understandable.
- Touch targets should remain usable on mobile.
- Arabic and English layouts should both remain readable.
- Avoid tiny action icons when text labels are clearer.
- Avoid cramped controls on mobile.

---

# Mobile and Web Quality Rules

Every important screen should be reviewed on:

- Mobile
- Tablet
- Desktop
- Mobile browser
- Desktop browser

Rules:

- Do not fix web issues by breaking mobile layouts.
- Do not fix mobile issues by stretching the same layout on desktop.
- Verify responsive layouts before completing tasks.
- Web screens should use proper desktop layouts.
- Mobile screens should remain simple and easy to use.
- Avoid horizontal overflow.
- Avoid browser trackpad gestures causing accidental browser back/forward.
- Keep app shell/header behavior consistent.
- Search/filter/content can scroll where necessary, but shell/header should remain usable.

---

# Firestore Query Rules

Firestore queries must be designed carefully.

Rules:

- Use pagination for large lists.
- Use indexes where needed.
- Avoid reading entire collections.
- Avoid loading unnecessary documents.
- Avoid deeply nested collections unless needed.
- Store duplicated summary fields when it improves performance.
- Keep search and filtering practical for Firestore limitations.
- Mention required Firestore indexes when adding new filters or sorting combinations.
- Avoid queries that will fail in production because of missing indexes.

---

# Package Defaults

- Do not add packages unless required by the task.
- If a package is needed, explain why in the report.
- Packages must improve production quality, visual consistency, accessibility, maintainability, or developer efficiency.
- Do not add decorative packages randomly.
- `visibility_detector` is approved and currently used for Dashboard/Reports reveal behavior.
- `file_picker` is used for property image picking on production web/mobile browser.
- `firebase_storage` is used for property image upload.
- `cached_network_image` may exist, but do not rely on it for Firebase Storage URLs on Flutter Web unless tested.
- If the `image` package is no longer used after removing client-side compression, it can be removed after `flutter analyze` confirms no imports remain.

---

# Git and Repository Hygiene

Rules:

- Do not commit zip files.
- Do not commit patch files.
- Do not commit temporary generated files.
- Do not commit local secrets.
- It is okay to commit:
  - firebase.json
  - firestore.rules
  - storage.rules
  - pubspec.yaml
  - pubspec.lock
- Do not commit:
  - .env
  - .env.local
  - serviceAccountKey.json
  - firebase-adminsdk*.json
  - google credentials JSON files
  - private keys
  - local-only debug files

Before commit, check:

```text
git status
git diff --cached --stat
```

The LF/CRLF warning on Windows is usually not the main issue.

The main issue is avoiding accidental zip/patch/secret commits.

---

# Codex Architecture Safety Rules

Before making major changes, Codex should explain the plan first.

Approval is required before:

- Architecture changes
- Security model changes
- Firestore structure changes
- Deployment workflow changes
- Firebase project changes
- New package additions that strongly affect architecture
- Authentication structure changes
- Role/permission model changes
- Manager/team hierarchy implementation
- Real audit log data model implementation
- Cloud Functions implementation

For normal UI fixes, small refactors, or focused feature work:

- Make the smallest safe implementation.
- Follow the existing architecture.
- Avoid unnecessary rewrites.

---

# Future Platform Admin / SaaS Owner Module

This module is not part of normal company CRM user screens.

Do not build this in version 1 unless explicitly requested.

The platform admin module may later allow the SaaS owner to monitor subscribed companies, usage, login activity, subscription status, and platform-level audit logs.

## Platform Admin Rules

- Platform admin features must be separate from normal CRM company features.
- Normal company users must never access platform admin screens or platform collections.
- Do not rely only on UI hiding.
- Firestore Security Rules must enforce platform access.
- Do not expose one company’s private CRM data to another company.
- Do not add payment or subscription billing unless explicitly requested.
- Do not delete existing Firestore data for platform admin features.
- Add fields and collections gradually and safely.

## Possible Future Platform Collections

```text
platform_admins/{adminId}
platform_companies/{companyId}
platform_usage/{companyId}
platform_audit_logs/{logId}
```

## Possible Company Metadata

Company documents may later include:

```text
companyName
status
plan
subscriptionStatus
createdAt
trialEndsAt
subscriptionEndsAt
lastActivityAt
userLimit
storageLimit
```

Existing company documents may not have these fields, so code must remain backward-compatible and use safe defaults.

Recommended safe defaults:

```text
status: active
plan: trial
subscriptionStatus: active
lastActivityAt: null
```

## Platform Admin Build Order

If requested later, build in small phases:

```text
1. Company metadata foundation
2. Platform admin route guard
3. Companies monitoring table
4. Login activity tracking
5. Usage counters
6. Subscription status management
7. Platform audit logs
```

Keep each phase small and focused.

Do not mix platform admin work with normal CRM module work unless explicitly requested.

---

# Final Product Standard

The final CRM should feel like a serious internal business application used by real sales teams.

It should not feel like:

- A tutorial app
- A generated template
- A fake SaaS dashboard
- A decorative AI-generated UI
- A prototype with no security
- A messy Flutter demo

The goal is a practical, maintainable, and scalable CRM that can grow safely.

---

# Important Final Instruction

This project must be built carefully.

Do not rush by generating large amounts of random code.

For every task:

1. Understand the existing structure.
2. Make the smallest clean change.
3. Follow Clean Architecture.
4. Use BLoC/Cubit.
5. Keep Firebase isolated in data sources.
6. Keep UI professional and realistic.
7. Avoid generic AI-looking designs.
8. Support Arabic and English localization.
9. Make layouts work correctly in RTL and LTR.
10. Do not hardcode visible UI text.
11. Respect company isolation and permissions.
12. Keep mobile and web both usable.
13. Summarize the work clearly.
