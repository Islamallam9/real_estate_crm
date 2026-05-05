# AGENTS.md

## Project Name

Real Estate CRM

## Project Description

This project is a full functional CRM system for a real estate company.

It will be built using Flutter for mobile and web, with Firebase as the backend.

The project must be clean, scalable, professional, and easy to maintain.

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
- Cloud Storage
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

---

# Codex Operational Defaults

These rules apply to every Codex task unless the user explicitly says otherwise.

## Working Branch

- Work on branch `dev`.
- Do not work directly on `main`.
- Do not assume changes are committed.
- Keep each task small and focused.

## Command Usage

- Do not run CLI commands unless explicitly requested.
- Do not run:
  - flutter analyze
  - flutter pub get
  - flutter gen-l10n
  - dart format
  - flutter run
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

## Reporting Format

After every task, report only:

```text
Files changed:
What was implemented:
Assumptions:
Issues:
```

Do not include long explanations unless there is a real problem.

## Architecture Defaults

- Use feature-first Clean Architecture.
- Use BLoC/Cubit only.
- Do not use Riverpod, Provider directly, GetX, or MobX.
- UI must call BLoC/Cubit.
- BLoC/Cubit must call use cases.
- Use cases must call repositories.
- Repositories must call data sources.
- Firebase calls must stay inside data sources only.

## Firebase and Company Isolation Defaults

- Never create global CRM collections such as:
  - `/leads`
  - `/clients`
  - `/properties`
  - `/tasks`
  - `/deals`
- All company data must live under:

```text
companies/{companyId}
companies/{companyId}/users/{userId}
companies/{companyId}/leads/{leadId}
companies/{companyId}/clients/{clientId}
companies/{companyId}/properties/{propertyId}
companies/{companyId}/tasks/{taskId}
companies/{companyId}/deals/{dealId}
companies/{companyId}/audit_logs/{auditLogId}
```

- Every CRM operation must require `companyId`.
- Never allow cross-company access.
- Never hard delete CRM business records unless explicitly requested.
- Prefer archive/soft delete for leads, clients, properties, tasks, and deals.

## Security Defaults

- Do not add secrets.
- Do not add `.env` files.
- Do not add Firebase Admin SDK keys.
- Do not add service account JSON files.
- Do not store passwords in Firestore.
- Do not store auth tokens in SharedPreferences.
- SharedPreferences may only be used for non-sensitive preferences such as selected language.

## Localization Defaults

- The app supports Arabic and English.
- Arabic must support RTL.
- English must support LTR.
- Do not hardcode visible UI text.
- Add English and Arabic ARB keys for all new visible text.
- Use localized labels, errors, empty states, buttons, and navigation text.
- Keep layouts working in both RTL and LTR.

## UI/UX Defaults

- Design must look like a real CRM, not a generic AI-generated dashboard.
- Avoid flashy gradients, glassmorphism, huge shadows, fake futuristic cards, and decorative clutter.
- Web layout should use sidebar/top bar/content.
- Mobile layout should use app bar/bottom navigation/card lists.
- Tables/lists must not overflow on web resize.
- Forms must be smooth, readable, and consistent.
- Use existing core widgets before creating new widgets.

## Package Defaults

- Do not add packages unless required by the task.
- If a package is needed, explain why in the report.
- Approved current exception:
  - `shared_preferences` for non-sensitive local preferences.
  - `google_fonts` for El Messiri Arabic font.



# State Management Rules

Use BLoC / Cubit only.

Allowed:

- flutter_bloc
- bloc
- equatable

Not allowed:

- Riverpod
- Provider
- GetX
- MobX

## When to Use Cubit

Use Cubit for simple state flows such as:

- Loading a list
- Creating an item
- Updating a form
- Simple CRUD screens
- Search and filters
- UI tab state

## When to Use Bloc

Use Bloc for more complex event-driven flows such as:

- Authentication flow
- Multi-step forms
- Lead pipeline updates
- Role and permission changes
- Complex dashboard filters
- Notification handling

## BLoC Rules

- UI should only read states and trigger events or cubit methods.
- BLoC/Cubit should not call Firebase directly.
- BLoC/Cubit should call use cases only.
- Use cases should call repositories.
- Repositories should communicate with data sources.
- Firebase logic should stay inside data sources.
- Every state should clearly represent the UI condition.

Example flow:

```text
Page
  -> Bloc/Cubit
  -> UseCase
  -> Repository
  -> RemoteDataSource
  -> Firebase
```

---

# Architecture Style

Use feature-first Clean Architecture.

Each main feature should have:

```text
feature/
  data/
  domain/
  presentation/
```

## Data Layer

Responsible for:

- Firebase calls
- Firestore queries
- Storage uploads
- Model mapping
- DTOs
- Remote data sources
- Repository implementations

## Domain Layer

Responsible for:

- Entities
- Repository contracts
- Use cases
- Business rules

The domain layer must not depend on Firebase.

## Presentation Layer

Responsible for:

- Pages
- Widgets
- BLoC/Cubit
- UI state
- Form handling
- User interactions

---

# Recommended Folder Structure

Use this structure as the base project structure:

```text
lib/
  main.dart
  app.dart

  core/
    constants/
      app_constants.dart
      firebase_paths.dart
      role_constants.dart

    errors/
      app_exception.dart
      failure.dart
      error_mapper.dart

    firebase/
      firebase_initializer.dart
      firestore_refs.dart
      firebase_result_handler.dart

    routing/
      app_router.dart
      route_names.dart
      route_guard.dart

    theme/
      app_theme.dart
      app_colors.dart
      app_text_styles.dart
      app_spacing.dart
      app_radius.dart
      app_shadows.dart

    utils/
      date_formatter.dart
      validators.dart
      debounce.dart

    widgets/
      app_button.dart
      app_text_field.dart
      app_dropdown.dart
      app_search_field.dart
      app_status_badge.dart
      app_empty_state.dart
      app_loading.dart
      app_error_view.dart
      responsive_layout.dart

  features/
    auth/
      data/
        datasources/
          auth_remote_data_source.dart
        models/
          app_user_model.dart
        repositories/
          auth_repository_impl.dart
      domain/
        entities/
          app_user.dart
        repositories/
          auth_repository.dart
        usecases/
          sign_in_usecase.dart
          sign_out_usecase.dart
          get_current_user_usecase.dart
      presentation/
        bloc/
          auth_bloc.dart
          auth_event.dart
          auth_state.dart
        pages/
          login_page.dart
        widgets/
          login_form.dart

    users/
      data/
      domain/
      presentation/

    leads/
      data/
      domain/
      presentation/

    clients/
      data/
      domain/
      presentation/

    properties/
      data/
      domain/
      presentation/

    deals/
      data/
      domain/
      presentation/

    tasks/
      data/
      domain/
      presentation/

    appointments/
      data/
      domain/
      presentation/

    dashboard/
      data/
      domain/
      presentation/

    reports/
      data/
      domain/
      presentation/

    notifications/
      data/
      domain/
      presentation/
```


---

# Localization / Internationalization Rules

The app must support both Arabic and English from the beginning.

Supported languages:

```text
Arabic: ar
English: en
```

## Direction Rules

- Arabic must use RTL layout direction.
- English must use LTR layout direction.
- All screens must work correctly in both RTL and LTR.
- Do not build layouts that break when direction changes.
- Do not hardcode left/right spacing when directional spacing is needed.
- Prefer `EdgeInsetsDirectional` instead of `EdgeInsets.only(left/right)` when the spacing depends on reading direction.
- Prefer `AlignmentDirectional` instead of `Alignment.centerLeft` or `Alignment.centerRight` when alignment depends on reading direction.
- Icons that imply direction, such as arrows, should behave correctly in RTL and LTR.

## Text Rules

Do not hardcode visible UI text directly inside widgets.

Avoid:

```dart
Text('Login')
Text('Dashboard')
Text('Leads')
```

Use localization instead.

Preferred approach:

```dart
Text(context.l10n.login)
Text(context.l10n.dashboard)
Text(context.l10n.leads)
```

or the generated Flutter localization class used in the project.

## Localization Files

Use Flutter localization with ARB files.

Recommended structure:

```text
lib/l10n/app_en.arb
lib/l10n/app_ar.arb
l10n.yaml
```

The app should include localization keys for all visible text, including:

```text
appName
login
email
password
signIn
logout
dashboard
leads
properties
clients
tasks
deals
reports
settings
language
arabic
english
save
cancel
search
filter
create
edit
delete
details
loading
noData
tryAgain
```

## UI Design with Localization

- Arabic text must look natural and professional.
- English text must remain clean and business-like.
- Avoid layouts that depend on fixed text length.
- Buttons, cards, tables, forms, and navigation should handle longer Arabic labels.
- Mobile and web layouts must both support Arabic and English.
- Sidebar navigation on web must support RTL positioning when Arabic is active.
- Bottom navigation on mobile must support translated labels.

## Date, Number, and Currency Formatting

Use localization-aware formatting for:

- Dates
- Times
- Numbers
- Prices
- Currency
- Percentages

Do not manually concatenate localized strings in a way that breaks Arabic grammar.

Avoid:

```dart
Text('Price: $price')
```

Use proper localized strings or formatting helpers.

## Codex Localization Rules

When adding or editing UI:

- Add English and Arabic keys for new visible text.
- Do not add English-only screens.
- Do not hardcode labels, button text, error messages, empty states, or navigation labels.
- Check that the UI remains usable in RTL and LTR.
- Keep localization clean and centralized.
- Do not introduce a localization package unless explicitly requested.
- Use Flutter's official localization approach unless the project later chooses another approach.


---

# Firebase Structure

Use a company-based structure from the beginning.

Even if the first version has only one company, the structure must support future multi-company usage.

```text
companies/{companyId}

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

Avoid global collections like:

```text
users/
leads/
properties/
```

unless there is a strong reason.

---

# Firebase Auth Rules

Use Firebase Authentication for login.

First version should support:

- Email and password login
- Logout
- Current user session
- Forgot password

User profile and role data should be stored in Firestore:

```text
companies/{companyId}/users/{userId}
```

Each user document should include:

```text
uid
companyId
fullName
email
phone
role
isActive
createdAt
updatedAt
createdBy
```

---

# Roles

The system should support these roles:

```text
admin
manager
salesAgent
marketing
viewer
```

## Role Meaning

### Admin

Can manage everything.

### Manager

Can manage leads, users, properties, deals, and reports, but not system-level settings.

### Sales Agent

Can manage assigned leads, assigned clients, assigned tasks, and assigned deals.

### Marketing

Can create and view leads from campaigns, but limited access to deals and financial data.

### Viewer

Read-only access.

---

# Permission Rules

Never rely only on UI hiding.

Permissions must be checked in:

1. UI
2. BLoC/use cases when needed
3. Firestore Security Rules

UI hiding is not enough.

---

# Main CRM Modules

## 1. Authentication

Required screens:

- Login page
- Forgot password page
- Loading/splash page

Required features:

- Login with email/password
- Logout
- Auth state listener
- Role loading from Firestore
- Route protection

---

## 2. Dashboard

Dashboard should show useful CRM information, not fake decorative cards.

Required data:

- Total leads
- New leads today
- Follow-ups due today
- Open deals
- Won deals
- Lost deals
- Available properties
- Agent performance summary

The dashboard should be simple, practical, and professional.

---

## 3. Leads

Lead fields:

```text
id
companyId
fullName
phone
email
source
status
priority
budgetMin
budgetMax
preferredLocation
preferredPropertyType
assignedTo
notes
createdAt
updatedAt
createdBy
updatedBy
```

Lead source values:

```text
facebook
website
phoneCall
whatsapp
referral
walkIn
other
```

Lead status values:

```text
new
contacted
interested
visitScheduled
negotiation
won
lost
```

Lead priority values:

```text
low
medium
high
```

Required screens:

- Leads list
- Lead details
- Create lead
- Edit lead
- Lead filters
- Assigned leads view

Required features:

- Create lead
- Edit lead
- Assign lead to agent
- Change lead status
- Search leads
- Filter by status, source, priority, and assigned agent
- Add notes
- View lead history

---

## 4. Clients

Client fields:

```text
id
companyId
fullName
phone
email
budgetMin
budgetMax
preferredLocation
preferredPropertyType
notes
createdAt
updatedAt
createdBy
updatedBy
```

Required features:

- Create client
- Edit client
- View client profile
- Link client to leads
- Link client to deals
- View client interaction history

---

## 5. Properties

Property fields:

```text
id
companyId
title
description
propertyType
listingType
price
area
bedrooms
bathrooms
location
compound
status
ownerName
ownerPhone
assignedTo
imageUrls
createdAt
updatedAt
createdBy
updatedBy
```

Property types:

```text
apartment
villa
office
shop
land
studio
duplex
penthouse
```

Listing types:

```text
sale
rent
```

Property status:

```text
available
reserved
sold
rented
inactive
```

Required features:

- Create property
- Edit property
- Upload property images
- View property details
- Search properties
- Filter by type, price, location, status, and listing type

---

## 6. Deals

Deal fields:

```text
id
companyId
clientId
leadId
propertyId
assignedTo
stage
expectedValue
commission
closingDate
lostReason
notes
createdAt
updatedAt
createdBy
updatedBy
```

Deal stages:

```text
new
qualified
proposal
negotiation
won
lost
```

Required features:

- Create deal
- Update deal stage
- Assign deal
- Mark as won
- Mark as lost
- Add lost reason
- Track commission

---

## 7. Tasks and Follow-ups

Task fields:

```text
id
companyId
title
description
assignedTo
relatedType
relatedId
dueDate
status
priority
createdAt
updatedAt
createdBy
updatedBy
```

Related type values:

```text
lead
client
property
deal
general
```

Task status:

```text
pending
inProgress
completed
cancelled
```

Required features:

- Create task
- Assign task
- Mark as completed
- View today's follow-ups
- View overdue tasks
- Filter by assigned user

---

## 8. Appointments

Appointment fields:

```text
id
companyId
title
description
clientId
leadId
propertyId
assignedTo
startTime
endTime
location
status
createdAt
updatedAt
createdBy
updatedBy
```

Appointment status:

```text
scheduled
completed
cancelled
missed
```

---

## 9. Notifications

Notifications should be used for important updates only.

Examples:

- New lead assigned
- Task due soon
- Follow-up overdue
- Deal status changed

Do not overuse notifications in version 1.

---

## 10. Audit Logs

Important actions should be logged.

Audit log fields:

```text
id
companyId
userId
action
module
documentId
oldValue
newValue
createdAt
```

Actions:

```text
create
update
delete
assign
statusChange
login
logout
```

Audit logs are important for CRM trust and accountability.

---

# UI / UX Design Rules

The design must be modern, professional, and clean.

Very important:

Do not create generic AI-looking designs.

## What “AI-looking design” means

Avoid:

- Random purple/blue gradients everywhere
- Glassmorphism everywhere
- Huge glowing cards
- Fake futuristic dashboards
- Unnecessary 3D shapes
- Random illustrations that do not help the user
- Over-decorated layouts
- Oversized shadows
- Too many colors
- Too many rounded elements
- Fake charts with no meaning
- Empty dashboard cards just for decoration
- Generic SaaS landing-page style inside the actual CRM
- Complex UI that looks nice but is slow to use

## Desired Design Direction

The CRM should feel like a real business tool.

Design style:

- Modern
- Minimal
- Professional
- Calm
- Practical
- Fast to scan
- Clean spacing
- Clear hierarchy
- Real CRM dashboard style
- Not flashy
- Not childish
- Not overdesigned

## Visual Style

Use:

- Neutral background
- Clean white or dark cards
- Subtle borders
- Soft shadows only when needed
- Consistent spacing
- Consistent typography
- Clear status badges
- Good table design for web
- Good card/list design for mobile
- Practical filters
- Clear empty states
- Clear loading states
- Clear error states

## Colors

Use a professional real estate CRM palette.

Suggested style:

```text
Primary: Deep navy, dark blue, or elegant teal
Background: Light gray / off-white
Surface: White
Text: Dark neutral
Borders: Soft gray
Success: Green
Warning: Amber
Error: Red
Info: Blue
```

Do not use too many colors.

Each status should have a clear and consistent color.

## Typography

Use clean typography.

Rules:

- Clear titles
- Readable body text
- No tiny unreadable labels
- No excessive font sizes
- Use hierarchy, not decoration
- Keep text aligned and consistent

## Layout Rules

For web:

- Use sidebar navigation.
- Use top bar for search, profile, and quick actions.
- Use tables for large data.
- Use filters above tables.
- Use dashboard cards only when they show useful data.
- Use responsive grid layout.
- Avoid horizontal overflow.

For mobile:

- Use bottom navigation or drawer.
- Use cards/lists instead of large tables.
- Keep forms simple.
- Use clear primary actions.
- Avoid too many controls on one screen.

## CRM Screen Design Rules

Every list screen should usually include:

- Page title
- Main action button
- Search field
- Filters
- List/table
- Empty state
- Loading state
- Error state
- Pagination or lazy loading if needed

Every details screen should usually include:

- Header summary
- Status badge
- Key information section
- Related records
- Activity history
- Notes
- Edit action

Every form screen should usually include:

- Clear section grouping
- Required field indicators
- Validation messages
- Cancel button
- Save button
- Loading state while saving

---

# Reusable UI Components

Create reusable widgets for:

```text
AppButton
AppTextField
AppDropdown
AppDatePickerField
AppSearchField
AppStatusBadge
AppUserAvatar
AppEmptyState
AppLoadingView
AppErrorView
AppTable
AppDataCard
AppPageHeader
AppFilterBar
ResponsiveLayout
```

Do not duplicate the same UI code across screens.

---

# Responsive Design

The app must work on:

- Mobile
- Tablet
- Web desktop

Use breakpoints:

```text
mobile: width < 600
tablet: width >= 600 and width < 1024
desktop: width >= 1024
```

Use different layouts when needed.

Do not simply stretch mobile UI on web.

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

---

# Security Rules

Security is required from the beginning.

Firestore rules must protect:

- Company isolation
- User roles
- User active status
- Read permissions
- Write permissions
- Delete permissions

Never allow:

```text
allow read, write: if true;
```

except for temporary local testing, and it must not stay in production.

---

# Cloud Storage Rules

Property images and attachments should be stored under company paths:

```text
companies/{companyId}/properties/{propertyId}/images/{fileName}
companies/{companyId}/leads/{leadId}/attachments/{fileName}
```

Rules:

- Users must be authenticated.
- Users must belong to the company.
- File size should be limited.
- File type should be validated when possible.

---

# Cloud Functions Usage

Do not use Cloud Functions for everything.

Use Cloud Functions only when the logic must be trusted server-side.

Possible Cloud Functions:

- Create user profile after Firebase Auth user creation
- Assign custom claims if needed
- Send notifications
- Maintain counters
- Generate reports
- Validate sensitive operations
- Audit important actions

For version 1, avoid overcomplicating Cloud Functions.

---

# Code Style

Use clear names.

Good examples:

```text
CreateLeadUseCase
LeadRepository
FirebaseLeadRepository
LeadRemoteDataSource
LeadListCubit
LeadDetailsPage
LeadStatusBadge
```

Bad examples:

```text
Manager
Helper
DataService
Utils2
NewPage
TestScreen
FirebaseStuff
```

## Naming Rules

- Use meaningful names.
- Avoid abbreviations.
- Avoid unclear generic names.
- Keep folder names lowercase.
- Keep class names PascalCase.
- Keep variables camelCase.

---

# Error Handling

Do not show raw Firebase errors directly to users.

Use mapped user-friendly errors.

Examples:

```text
Invalid email or password.
You do not have permission to perform this action.
Unable to load leads. Please try again.
Connection error. Check your internet connection.
```

Technical errors can be logged, but UI should show clean messages.

---

# Loading and Empty States

Every async screen must handle:

- Initial loading
- Success
- Empty state
- Error state
- Refreshing state when needed

Do not leave blank screens.

---

# Forms and Validation

All forms should validate input before saving.

Examples:

- Required fields
- Valid email
- Valid phone number
- Price must be positive
- Area must be positive
- End date must be after start date

Validation should be clear and close to the field.

---

# Testing Rules

When practical, add tests for:

- Use cases
- Repositories
- BLoC/Cubit logic
- Validators

Do not skip testing critical business logic.

---

# Git Rules

When making changes:

- Keep changes small.
- Do not mix unrelated features in one change.
- Summarize changed files.
- Mention how to test.
- Mention any assumptions.

Each completed task should include:

```text
Files changed:
What was implemented:
How to test:
Assumptions:
Remaining issues:
```

---

# Development Order

Do not start with the dashboard.

Build in this order:

```text
1. Project setup
2. Theme and shared UI components
3. Firebase initialization
4. Authentication
5. User profile and roles
6. App routing and route guards
7. Leads module
8. Properties module
9. Clients module
10. Tasks and follow-ups
11. Deals module
12. Dashboard
13. Reports
14. Notifications
15. Security rules review
16. Testing
17. Deployment
```

The first complete business module should be Leads.

---

# MVP Scope

Version 1 should include:

- Login
- Logout
- User roles
- Leads CRUD
- Properties CRUD
- Clients CRUD
- Tasks/follow-ups
- Basic deals
- Basic dashboard
- Basic reports
- Firestore security rules
- Firebase hosting for web
- Mobile and web responsive UI

---

# Delay to Version 2

Do not build these in version 1 unless explicitly requested:

- WhatsApp integration
- Payment system
- Subscription billing
- AI lead scoring
- Advanced analytics
- Advanced automation
- Calendar sync
- Complex PDF templates
- Multi-branch accounting
- Public real estate website
- SEO website
- Complex chat system

---

# Design Quality Checklist

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
11. Summarize the work clearly.

---

# How Codex Should Report Back After Each Task

After every completed task, Codex must provide a clear summary using this format:

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

# Codex Task Behavior

When working on this repository:

- Read this AGENTS.md file first.
- Respect the architecture.
- Respect the design rules.
- Respect the state management decision.
- Do not introduce another state management package.
- Do not add backend systems outside Firebase unless explicitly requested.
- Do not overbuild version 1.
- Do not hardcode visible UI text.
- Add Arabic and English localization keys for new visible UI text.
- Respect RTL for Arabic and LTR for English.
- Ask for confirmation only when the decision would strongly affect architecture, security, or data design.
- Otherwise, make the safest minimal implementation and document the assumption.

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
