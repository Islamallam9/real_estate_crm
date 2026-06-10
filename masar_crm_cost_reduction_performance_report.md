# Masar CRM Cost Reduction and Performance Management Report

**Project:** Masar CRM / مسار CRM  
**Stack:** Flutter Web/Mobile, Firebase, Firestore, Cloud Functions, Firebase Hosting  
**Date:** 2026-06-10  
**Scope:** Cost reduction, performance improvement, production monitoring, Firebase operational management

---

## 1. Executive Summary

Based on the Firebase console screenshot and a static scan of the uploaded project ZIP, the current Firebase cost is still low, but the cost pattern already shows where the risk is.

From the screenshot:

| Service | Visible Cost |
|---|---:|
| Cloud Firestore | ~$0.03 |
| Cloud Functions | ~$0.46 |
| Total Project Cost | ~$0.48 |

The numbers are rounded in the Firebase console, so the service totals may not perfectly match the displayed project total.

**Main conclusion:**  
The current cost driver is **Cloud Functions**, not Firestore. Firestore is still cheap now, but it can become expensive later if realtime listeners, dashboards, notifications, and platform pages keep scaling without limits.

The professional management goal should be:

1. Reduce unnecessary scheduled Cloud Functions.
2. Keep Firestore queries limited, indexed, and paginated.
3. Use realtime streams only when the screen actually needs realtime.
4. Add proper performance monitoring and custom traces.
5. Add quotas, retention, and App Check protection.
6. Build a weekly cost/performance report instead of guessing.

---

## 2. Static ZIP Audit Findings

This is a static scan of the uploaded codebase. It is not a runtime billing export, so it identifies likely cost/performance risks, not exact production usage.

| Area | Finding | Risk Level | Notes |
|---|---:|---|---|
| Total scanned files | 510 | Info | Uploaded project ZIP |
| Cloud Functions exports | 71 | Medium | Large backend surface area |
| Callable Functions | 60 | Medium | Needs App Check, rate limiting, runtime limits |
| Scheduled Functions | 5 | High | Main suspect for current Cloud Functions cost |
| Firestore triggers | 5 | Medium | Watch duplicate notifications and repeated work |
| Storage trigger | 1 | Low/Medium | Image validation trigger |
| Flutter Firestore realtime `.snapshots()` calls | 44 | High later | Realtime listeners can become expensive if not screen-scoped |
| `.limit()` usage | 110 | Good | Indicates pagination/query limiting is already being applied |
| Firestore composite indexes | 103 | Normal/Medium | Normal for a complex CRM, but should be reviewed later |
| `firebase_performance` dependency | Not found | High | Missing important production performance visibility |

Correction from earlier rough scan: the uploaded ZIP shows **5 scheduled functions**, not 8.

---

## 3. Highest-Risk Scheduled Functions

The scheduled functions found in `src/index.js` are:

| Function | Schedule | Risk | Recommendation |
|---|---|---|---|
| `expireTrialCompanies` | Every 1 minute | High | Change to every 15 or 30 minutes unless minute-level trial expiry is truly required |
| `runPaymentReminderSweep` | Every 6 hours | Low/Medium | Reasonable, but must log scanned/updated counts |
| `createActionableReminderNotifications` | Every 5 minutes | High | Disable or remove if it still returns `liveAttentionOnly` |
| `createDueAppointmentNotifications` | Every 1 minute | High | Keep only if exact appointment timing is critical |
| `cleanupExpiredCompanyNotifications` | Every 24 hours | Good | Reasonable cleanup job |

### Important finding

`createActionableReminderNotifications` calls `refreshActionableReminderWindow`, but the function currently returns:

```js
return { checked: 0, created: 0, mode: 'liveAttentionOnly' };
```

That means the scheduled function may be running repeatedly while doing almost no useful business work. This is exactly the kind of thing that creates small but continuous Cloud Functions cost.

**Decision:**  
Remove it, disable it, or convert it into an on-demand callable action unless there is a real reason to run it every 5 minutes.

---

## 4. Professional Cost Reduction Strategy

### 4.1 Start with Billing Baseline

Before changing more code, create a weekly baseline report.

Track these metrics:

| Metric | Why It Matters |
|---|---|
| Total Firebase cost | Overall budget control |
| Cost by service | Know whether Firestore, Functions, Storage, or Hosting is growing |
| Cloud Functions invocations by function name | Finds noisy or abused functions |
| Cloud Functions duration P50/P95 | Long functions cost more and feel slower |
| Cloud Functions memory/CPU allocation | Oversized functions waste money |
| Firestore reads per screen load | Finds expensive dashboards/lists |
| Firestore writes per user action | Finds duplicate writes |
| Firestore listener count per screen | Finds hidden realtime costs |
| Missing index errors | Must be zero in production |
| Crash-free users | Reliability health |
| App load and screen load times | Real user performance |

Firebase budget alerts are useful, but they do **not** cap usage or charges. They are alerts only. So budget alerts are necessary, but not enough.

---

## 5. Cloud Functions Optimization Plan

Cloud Functions should be the first optimization target because the screenshot shows Functions as almost all visible cost.

### 5.1 Immediate Function Actions

| Priority | Action | Reason |
|---|---|---|
| P0 | Disable/remove useless scheduled functions | Stops recurring cost immediately |
| P0 | Change `expireTrialCompanies` from every 1 minute to every 15/30 minutes | Trial expiry does not need minute precision |
| P0 | Review `createDueAppointmentNotifications` every 1 minute | Keep only if product requires exact due-minute notifications |
| P1 | Add `maxInstances` to callables | Prevent runaway cost during bugs/abuse |
| P1 | Keep `minInstances: 0` unless truly needed | Warm instances can create idle billing |
| P1 | Set explicit timeout and memory per function | Prevent slow or oversized functions |
| P1 | Add structured logs per function | Required for cost attribution |
| P2 | Split heavy exports/backfills from normal user functions | Prevent heavy jobs from affecting CRM operations |
| P2 | Add idempotency keys for notification/export operations | Prevent duplicate writes and duplicate notifications |

### 5.2 Recommended Runtime Controls

Each function should explicitly define:

| Runtime Option | Recommendation |
|---|---|
| `region` | Use one consistent region close to users and Firestore |
| `timeoutSeconds` | Short for normal callables, longer only for exports/backfills |
| `memory` | Small by default; increase only when measured |
| `minInstances` | `0` unless low cold-start latency is truly needed |
| `maxInstances` | Set for every public/callable function |
| App Check enforcement | Start monitor mode first, enforce after validation |

### 5.3 Function Logging Standard

Every important function should log:

| Field | Example |
|---|---|
| Function name | `saveLeadRecord` |
| Company ID | `demo_company` |
| Actor UID | Auth user ID |
| Actor role | admin / manager / salesAgent |
| Duration | milliseconds |
| Docs read | estimated/known count |
| Docs written | count |
| Result | success / denied / validation_error / failed |
| Error code | if failed |
| App version/build | for client-triggered calls |

This makes cost investigation possible without guessing.

---

## 6. Firestore Optimization Plan

Firestore is low-cost now, but it becomes expensive when data grows and pages keep many active listeners.

### 6.1 Firestore Query Rules

| Rule | Required Pattern |
|---|---|
| Lists | Always use `orderBy + limit` |
| Pagination | Use query cursors, not offset |
| KPI counts | Use aggregate count or cached counter docs |
| Hot counters | Use summary docs or distributed counters |
| Search | Debounce input; do not query every keystroke |
| Detail pages | Stream only the selected record |
| Hidden tabs | Stop streams when tab is not active |
| Dashboard | Prefer summary docs instead of recomputing everything |
| Timeline/notes/history | Add pagination and Load More |
| Admin/platform pages | Avoid broad unbounded company/user streams |

### 6.2 Realtime Listener Rules

Realtime is good for CRM, but only when used carefully.

| Page Type | Recommended Behavior |
|---|---|
| Dashboard | Limited realtime summary docs, not many wide collection streams |
| Leads list | Paginated list; realtime only for first page or current active query |
| Appointments | Realtime for current relevant date window only |
| Deals | Realtime for current page/filter only |
| Tasks | Realtime for current page/filter only |
| Details page | Single-document realtime stream |
| Support/tickets | Limited list + Load More |
| Notifications | Limited unread/recent stream |
| Platform owner pages | Mostly paginated/on-demand, not always-on realtime |

### 6.3 Count Strategy

For KPI counts:

| Use Case | Best Option |
|---|---|
| Small/medium filtered count | Firestore aggregate `count()` |
| Very hot dashboard count | Cached summary document |
| High-write counter | Distributed counter/sharded counter |
| Historical report | Scheduled summary or export function |
| Rare admin count | On-demand aggregate query |

Do not fetch documents only to count them. That wastes reads and gets worse with scale.

---

## 7. Flutter Performance Plan

The app already uses BLoC/Cubit and pagination patterns, which is good. The next step is production measurement.

### 7.1 Add Firebase Performance Monitoring

The uploaded `pubspec.yaml` does not include `firebase_performance`.

Add it and create custom traces for:

| Trace Name | What It Measures |
|---|---|
| `dashboard_load` | Dashboard first useful render |
| `leads_list_load` | First page leads load |
| `appointments_load` | Appointment page load |
| `deals_list_load` | Deals first page load |
| `tasks_list_load` | Tasks first page load |
| `save_lead` | Lead mutation duration |
| `save_deal` | Deal mutation duration |
| `save_appointment` | Appointment mutation duration |
| `generate_export` | Export request duration |
| `login_flow` | Login to app shell ready |

### 7.2 Flutter UI Rules

| Area | Recommendation |
|---|---|
| Lists | Use `ListView.builder` or virtualized table patterns |
| Initial rows | Load 15 rows first |
| More rows | Use Load More/cursor pagination |
| Search | 400–600ms debounce |
| BLoC/Cubit | Use selectors to avoid rebuilding full pages |
| Tabs | Start stream only when tab is visible |
| Images | Compress, thumbnail, lazy load |
| Web tables | Avoid rebuilding entire table on every stream tick |
| Detail pages | Cancel streams when leaving page |
| Empty/loading states | Avoid repeated reload loops |
| Snackbars | Show success only after confirmed write/read-back when needed |

---

## 8. Security and Abuse Protection

Cost reduction is also security. If a fake client or script abuses callables, Firestore, Storage, or export functions, the bill grows.

### 8.1 Required Controls

| Control | Purpose |
|---|---|
| Firebase App Check | Reduce abuse from unauthorized clients |
| App Check monitor mode first | Avoid blocking real users accidentally |
| App Check enforcement later | Block invalid traffic after validation |
| Function `maxInstances` | Limit runaway cost |
| Rate limiting | Prevent spam operations |
| Server-side validation | Never trust Flutter client |
| Role-based Firestore rules | Security rules must enforce access, not only filter UI |
| Idempotency | Prevent duplicate writes/notifications |
| Quotas per company | Prevent one tenant from consuming everything |

### 8.2 Suggested Company Quotas

These are suggested starting points, not final business pricing.

| Plan | Active Properties | Images / Property | Max Image Size | Storage Cap |
|---|---:|---:|---:|---:|
| Starter | 300 | 6 | 1 MB | 500 MB |
| Growth | 800 | 12 | 2 MB | 2 GB |
| Pro | 2,000 | 18 | 3 MB | 6 GB |

Also add quotas for:

| Area | Suggested Limit |
|---|---|
| Users per company | Based on plan |
| Exports per day | Based on plan |
| Notifications retained | Based on retention policy |
| Support attachments | Based on plan |
| API/callable actions | Rate-limited per user/company |

---

## 9. Data Retention Policy

A professional CRM should not keep noisy operational data forever.

| Data Type | Suggested Retention |
|---|---|
| Read notifications | 90 days |
| Dismissed notifications | 30 days |
| Device heartbeat/session records | 30–60 days |
| Login activity | 90–180 days |
| Debug/client error logs | 30–90 days |
| Audit logs | 1–2 years, depending on business need |
| Export files | 7–30 days |
| Trial/invitation records | 30–90 days after expiry |
| Temporary upload validation logs | 7–30 days |

Retention reduces:

1. Firestore storage.
2. Firestore index storage.
3. Query scan size.
4. Admin page load time.
5. Long-term operational clutter.

---

## 10. Module-by-Module Audit Priorities

| Priority | Module/Area | Why It Matters |
|---|---|---|
| 1 | Scheduled notification functions | Most likely current Functions cost driver |
| 2 | Dashboard / Sales Command Center | Usually the highest Firestore read area |
| 3 | Notifications attention stream | Can combine multiple modules and timers |
| 4 | Platform owner pages | Can become expensive as tenants grow |
| 5 | Support tickets | Often becomes unbounded without pagination |
| 6 | Lead notes / timeline | Needs pagination and limited history loading |
| 7 | Teams/users lookup streams | Can grow with company size |
| 8 | Export functions | Heavy CPU/memory and document reads |
| 9 | Release/device heartbeat | Can grow fast if every session writes too often |
| 10 | Storage/image uploads | Needs size/compression/quota controls |

---

## 11. Weekly Cost and Performance Report Template

Use this every week.

### 11.1 Cost Summary

| Service | This Week | Last Week | Change | Notes |
|---|---:|---:|---:|---|
| Cloud Functions |  |  |  |  |
| Firestore reads |  |  |  |  |
| Firestore writes |  |  |  |  |
| Firestore storage/indexes |  |  |  |  |
| Cloud Storage |  |  |  |  |
| Hosting |  |  |  |  |
| Total |  |  |  |  |

### 11.2 Top Cost Drivers

| Rank | Driver | Evidence | Action |
|---|---|---|---|
| 1 | Scheduled Functions | Invocation count / cost | Reduce, merge, or disable |
| 2 | Dashboard reads | Reads per page load | Use summary docs |
| 3 | Notification scans | Scanned docs per run | Query due window only |
| 4 | Exports | Duration/memory/read count | Queue and isolate |
| 5 | Device heartbeat | Write count | Throttle and retain less |

### 11.3 Performance

| Screen/Action | P50 | P95 | Target | Status |
|---|---:|---:|---:|---|
| Login |  |  | < 2s |  |
| Dashboard load |  |  | < 2s |  |
| Leads list load |  |  | < 2s |  |
| Appointments load |  |  | < 2s |  |
| Deals list load |  |  | < 2s |  |
| Save lead |  |  | < 1.5s |  |
| Save deal |  |  | < 1.5s |  |
| Generate export |  |  | depends on size |  |

### 11.4 Reliability

| Metric | Target |
|---|---:|
| Crash-free users | 99%+ |
| Function error rate | < 1% |
| Permission-denied false errors | 0 |
| Missing Firestore index errors | 0 |
| Duplicate notification bugs | 0 |
| Failed writes after success snackbar | 0 |

---

## 12. Immediate Action Plan

### Phase 1 — Stop Waste

1. Open Google Cloud Billing details by SKU.
2. Confirm which Cloud Functions SKUs are charging.
3. Disable/remove `createActionableReminderNotifications` if it still returns `liveAttentionOnly`.
4. Change `expireTrialCompanies` from every 1 minute to every 15 or 30 minutes.
5. Review whether `createDueAppointmentNotifications` really needs to run every minute.
6. Add structured logs to every scheduled function.

### Phase 2 — Protect Functions

1. Add runtime options to all Cloud Functions:
   - region
   - timeout
   - memory
   - minInstances
   - maxInstances
2. Add App Check monitor mode.
3. Add rate limiting for risky callable functions:
   - exports
   - password reset
   - company/user changes
   - notification refresh
   - duplicate lead checks
4. Add idempotency protection to notification creation and export generation.

### Phase 3 — Firestore Control

1. Re-audit all realtime streams.
2. Stop hidden tab streams.
3. Add pagination to remaining unbounded subcollections:
   - lead notes
   - lead timeline
   - support tickets
   - notification history
   - platform users/companies
4. Keep KPI counts as aggregate counts or summary docs.
5. Add missing indexes before production release.

### Phase 4 — Performance Visibility

1. Add `firebase_performance`.
2. Add custom traces for dashboard, lists, mutations, login, and exports.
3. Add performance metrics to Platform Owner dashboard.
4. Track P50 and P95 load time weekly.
5. Track reads per screen load weekly.

### Phase 5 — Retention and Quotas

1. Define plan limits.
2. Enforce Storage/image limits.
3. Add notification retention cleanup.
4. Add device heartbeat retention cleanup.
5. Add export file cleanup.
6. Add per-company quota reporting.

---

## 13. Final Professional Opinion

The app is already moving in the right direction because pagination, role-scoped queries, and realtime fixes are being added.

But the next professional step is not more UI features. The next step is **operational control**:

- Know which function costs money.
- Know which screen reads too much.
- Know which stream stays open.
- Know which company uses the most resources.
- Know which release/build causes errors.
- Know when costs grow before they become a problem.

The highest-value next fix is:

> Reduce or remove unnecessary scheduled Cloud Functions, then add performance traces and billing-by-function visibility.

That will give the biggest cost reduction and the clearest management control.

---

## 14. Official References

- Firebase: Avoid surprise bills  
  https://firebase.google.com/docs/projects/billing/avoid-surprise-bills

- Firebase: Advanced billing alerts  
  https://firebase.google.com/docs/projects/billing/advanced-billing-alerts-logic

- Firestore: Understand billing  
  https://firebase.google.com/docs/firestore/pricing

- Firestore: Query cursors and pagination  
  https://firebase.google.com/docs/firestore/query-data/query-cursors

- Firestore: Aggregation queries  
  https://firebase.google.com/docs/firestore/query-data/aggregation-queries

- Firestore: Distributed counters  
  https://firebase.google.com/docs/firestore/solutions/counters

- Firebase Functions: Manage functions and runtime options  
  https://firebase.google.com/docs/functions/manage-functions

- Firebase Functions: Tips and idempotent functions  
  https://firebase.google.com/docs/functions/tips

- Firebase Performance Monitoring for Flutter  
  https://firebase.google.com/docs/perf-mon/flutter/get-started

- Firebase App Check  
  https://firebase.google.com/docs/app-check

- Firebase App Check metrics before enforcement  
  https://firebase.google.com/docs/app-check/monitor-metrics

- Firebase App Check for Cloud Functions  
  https://firebase.google.com/docs/app-check/cloud-functions
