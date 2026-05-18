# Masar CRM

Masar CRM is a production-grade real estate CRM built with Flutter Web/Mobile and Firebase for company-scoped real estate sales operations.

The app supports Arabic and English, RTL/LTR layouts, role-based access, team management, platform-level SaaS administration, and Firebase-backed security.

## Current status

The project is in an active stabilization/product-hardening phase. The latest confirmed stable work includes:

- Lead create/update/reassign stabilized through the `saveLeadRecord` Cloud Function.
- Admin can create, assign, and reassign leads company-wide.
- Manager can assign/reassign only inside their own team.
- Sales/Marketing can update own assigned leads where policy allows.
- Manager Recent Activity is scoped to the manager team.
- Lead timeline logs normal updates and changed-field details.
- Admin/Manager Recent Activity shows useful update details.
- Arabic old/new value display uses `من old إلى new` to avoid RTL arrow issues.
- Global Search exists and is role-scoped.
- Profile image flow is stabilized with safe fallbacks and no noisy URL logs.
- Platform Data Health is SaaS monitoring mode.
- Company Admin Data Health is Admin-only operational repair mode.
- Data Health reports persist after running until a new check is triggered.
- Data Health hides raw missing-assignee UIDs and shows clean issue labels.

Current app version is around `1.2.7+9`.

## Tech stack

- Flutter Web/Mobile
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Hosting
- BLoC/Cubit state management
- go_router routing
- ARB-based localization

## Architecture

The project follows feature-first Clean Architecture:

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

Firebase calls should remain inside data sources. Privileged operations and sensitive repair/reassignment flows should run through Cloud Functions/Admin SDK.

## Main modules

- Dashboard
- Leads
- Clients
- Properties
- Tasks
- Deals
- Reports
- Team Management
- Data Health
- Profile
- Settings
- Platform Dashboard

## Roles

- Platform owner/admin
- Admin
- Manager
- Sales Agent
- Marketing
- Viewer

Role behavior summary:

- Platform owner manages the SaaS platform and monitors companies. Platform owner should not manually operate tenant business records.
- Admin sees company-wide CRM data and can repair operational data health issues.
- Manager sees and manages own team scope only.
- Sales/Marketing see own assigned records only.
- Viewer is restricted/read-only according to policy.

## Assignment policy

Assignable roles by module:

- Leads: `salesAgent`, `marketing`
- Tasks: `salesAgent`, `marketing`
- Clients: `salesAgent`
- Deals: `salesAgent`
- Properties: `salesAgent` only if assignment exists in the current business flow

Assigned records should keep these snapshots where supported:

```text
assignedTo
assignedToName
assignedToEmail
teamId
teamName
managerId
managerName
```

New lead save/reassign logic is handled through `saveLeadRecord` to keep assignment validation stable and server-side.

## Data Health

There are two Data Health modes:

### Platform Data Health

Purpose: SaaS monitoring and safe technical snapshot backfill only.

Platform owner should be able to see issues, but should not decide which sales agent owns tenant CRM records.

### Company Admin Data Health

Purpose: operational repair mode for company Admin only.

Admin can:

- Run Data Health checks.
- Backfill safe missing/stale assignment snapshots.
- Reassign records with invalid/missing/inactive/ineligible assignees.

Manager Data Health is currently removed/disabled. Managers should not see Data Health navigation or access `/data-health`.

## Important Cloud Functions

Current important callable functions include:

- `saveLeadRecord`
- `getCompanyDataHealthReport`
- `getOperationalDataHealthReport`
- `backfillAssignedRecordSnapshots`
- `reassignDataHealthRecord`
- `createCompanyWithAdmin`
- `addUserToCompany`
- `setCompanyUserEmail`
- `setCompanyUserPassword`
- `generateCompanyUserPasswordResetLink`
- `updateCompanyPlatformSettings`
- `assignUserToTeam`
- `removeUserFromTeam`

## Local development

Install dependencies:

```powershell
flutter pub get
```

Run web locally:

```powershell
flutter run -d edge
```

Analyze before pushing:

```powershell
flutter analyze
```

## Build and deploy

Build Flutter web:

```powershell
flutter build web --release --dart-define-from-file=config/firebase.local.json
```

Deploy hosting:

```powershell
firebase deploy --only hosting
```

Deploy functions when changed:

```powershell
firebase deploy --only functions
```

Deploy Firestore rules when changed:

```powershell
firebase deploy --only firestore:rules
```

Deploy Storage rules when changed:

```powershell
firebase deploy --only storage
```

## Git hygiene

Work on `dev` unless explicitly told otherwise.

Do not commit local zip/backup files such as:

```text
*.zip
stable versions zip/
config.zip
pubspec.zip
```

Before commit:

```powershell
git status
git diff --cached --stat
```

## Next recommended phase

Recommended next phase:

```text
Notifications + Reminders Foundation
```

Suggested scope:

- Follow-up reminders
- Task due/overdue alerts
- Assignment/reassignment notifications
- In-app notification center
- Enable the currently disabled Notify Manager placeholders
- Later browser/FCM notifications
