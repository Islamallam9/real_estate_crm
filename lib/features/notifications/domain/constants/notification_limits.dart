// Display and cleanup retention. Unread/action-needed notifications stay visible;
// read/resolved/dismissed notifications get an expiresAt marker for backend cleanup.
const notificationDropdownLimit = 15;
const notificationHistoryPageLimit = 15;
const notificationMarkAllReadLimit = 100;
const notificationUnreadCountLimit = 1000;
const notificationFutureReadRetentionDays = 90;
const notificationReadRetentionDays = 90;
const notificationDismissedRetentionDays = 30;
