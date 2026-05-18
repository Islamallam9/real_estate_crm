// Display retention only. Firestore notification documents are kept for history;
// a future cleanup can archive/delete old read notifications after 90 days.
const notificationDropdownLimit = 15;
const notificationHistoryPageLimit = 100;
const notificationMarkAllReadLimit = 100;
const notificationFutureReadRetentionDays = 90;
