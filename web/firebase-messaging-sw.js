/* Masar CRM Firebase Messaging service worker. */
const MASAR_FCM_SW_VERSION = '2.30.2+99';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCteQzvKC5G4z4J-X8jivrtbYX4GObFOGU',
  appId: '1:138177769693:web:7c3cc46c0cd53057ae6b34',
  projectId: 'real-escrm-ia',
  authDomain: 'real-escrm-ia.firebaseapp.com',
  storageBucket: 'real-escrm-ia.firebasestorage.app',
  messagingSenderId: '138177769693',
});

const messaging = firebase.messaging();

function cleanRoute(route) {
  if (!route || typeof route !== 'string') return '/notifications';
  const trimmed = route.trim();
  if (!trimmed || trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('javascript:')) return '/notifications';
  if (trimmed.startsWith('/#')) {
    const hashRoute = trimmed.slice(trimmed.indexOf('#') + 1).trim();
    return hashRoute.startsWith('/') ? hashRoute : '/notifications';
  }
  if (trimmed.startsWith('#/')) return trimmed.slice(1);
  return trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
}
function routeUrl(data) { return `${self.location.origin}/#${cleanRoute(data && data.route)}`; }
function safeNotificationText(payload, field, fallback) {
  const notificationValue = payload && payload.notification && payload.notification[field];
  const dataValue = payload && payload.data && payload.data[field];
  return (notificationValue || dataValue || fallback || '').toString().slice(0, 220);
}

messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {};
  const title = safeNotificationText(payload, 'title', 'Masar CRM');
  const body = safeNotificationText(payload, 'body', 'Open Masar CRM to review the latest update.');
  const tag = data.dedupeKey || data.notificationId || undefined;
  return self.registration.showNotification(title, {
    body,
    tag,
    renotify: true,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { ...data, type: 'MASAR_FCM_NOTIFICATION_CLICK', route: cleanRoute(data.route), url: routeUrl(data) },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const route = cleanRoute(data.route);
  const targetUrl = data.url || routeUrl(data);
  event.waitUntil((async () => {
    const windows = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of windows) {
      if (client.url && client.url.startsWith(self.location.origin)) {
        try { client.postMessage({ type: 'MASAR_FCM_NOTIFICATION_CLICK', route }); } catch (_) {}
        if ('navigate' in client) { try { await client.navigate(targetUrl); } catch (_) {} }
        return client.focus();
      }
    }
    return clients.openWindow(targetUrl);
  })());
});
