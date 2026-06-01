/*
 * Firebase Cloud Messaging service worker for Masar CRM web push.
 * Uses Firebase Hosting reserved URLs so the live Firebase web config is not
 * hardcoded in source files. This works after Hosting deploy; for local web
 * testing, use Firebase Hosting emulator/serve if the /__/firebase URLs are
 * unavailable from flutter run.
 */
importScripts('/__/firebase/8.10.1/firebase-app.js');
importScripts('/__/firebase/8.10.1/firebase-messaging.js');
importScripts('/__/firebase/init.js');

try {
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const data = payload && payload.data ? payload.data : {};
    const notification = payload && payload.notification ? payload.notification : {};
    const title = notification.title || data.title || 'Masar CRM';
    const body = notification.body || data.body || '';
    const route = data.route || '/dashboard';

    self.registration.showNotification(title, {
      body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: data.dedupeKey || data.notificationId || undefined,
      data: {
        route,
        notificationId: data.notificationId || '',
        companyId: data.companyId || '',
        platform: data.platform || '',
      },
    });
  });
} catch (error) {
  // Keep the worker installable even if Firebase Hosting reserved config is not
  // available in a local non-hosting web run.
  console.warn('Masar FCM service worker initialization skipped.', error);
}

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification && event.notification.data ? event.notification.data : {};
  const route = typeof data.route === 'string' && data.route.trim()
    ? data.route.trim()
    : '/dashboard';
  const targetUrl = new URL(route.startsWith('/#') ? route : `/#${route}`, self.location.origin).href;

  event.waitUntil((async () => {
    const windowClients = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of windowClients) {
      if ('focus' in client) {
        await client.focus();
        if ('navigate' in client) {
          await client.navigate(targetUrl);
        }
        return;
      }
    }
    if (clients.openWindow) {
      await clients.openWindow(targetUrl);
    }
  })());
});
