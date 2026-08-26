const CACHE_VERSION = "2026-08-26-v2";
const STATIC_CACHE = `petjournal-static-${CACHE_VERSION}`;
const OFFLINE_URL = "/offline.html";
const PRECACHE_URLS = [
  OFFLINE_URL,
  "/pwa/icon-192.png",
  "/pwa/icon-512.png",
  "/pwa/icon-maskable-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(PRECACHE_URLS))
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((key) => key.startsWith("petjournal-static-") && key !== STATIC_CACHE)
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") self.skipWaiting();
});

function cacheableStaticRequest(request, url) {
  if (url.origin !== self.location.origin) return false;
  if (request.method !== "GET") return false;

  return url.pathname.startsWith("/assets/") ||
    url.pathname.startsWith("/pwa/") ||
    url.pathname === "/favicon.ico";
}

async function staticResponse(request) {
  const cache = await caches.open(STATIC_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  if (response.ok && response.type === "basic") {
    await cache.put(request, response.clone());
  }
  return response;
}

async function navigationResponse(request) {
  try {
    return await fetch(request);
  } catch (_error) {
    return (await caches.match(OFFLINE_URL)) || Response.error();
  }
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);

  // Authenticated HTML is intentionally never cached: PetJournal may contain
  // health records, contact details and documents. Offline only serves a safe
  // static shell instead of persisting private pages in Cache Storage.
  if (request.mode === "navigate") {
    event.respondWith(navigationResponse(request));
    return;
  }

  if (cacheableStaticRequest(request, url)) {
    event.respondWith(staticResponse(request));
  }
});

self.addEventListener("push", (event) => {
  let payload = {
    title: "PetJournal",
    body: "У вас новое напоминание",
    path: "/pets"
  };

  if (event.data) {
    try {
      payload = Object.assign(payload, event.data.json());
    } catch (_error) {
      payload.body = event.data.text();
    }
  }

  const notificationOptions = {
    body: payload.body,
    icon: "/pwa/icon-512.png",
    badge: "/pwa/icon-192.png",
    data: { path: payload.path || "/pets" },
    silent: false
  };

  if (payload.tag) {
    notificationOptions.tag = payload.tag;
    notificationOptions.renotify = true;
  }

  if (payload.timestamp) notificationOptions.timestamp = payload.timestamp;
  if (payload.require_interaction === true) notificationOptions.requireInteraction = true;

  event.waitUntil(self.registration.showNotification(payload.title, notificationOptions));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  event.waitUntil((async () => {
    const targetPath = event.notification.data?.path || "/pets";
    const targetUrl = new URL(targetPath, self.location.origin);
    const clientList = await clients.matchAll({ type: "window", includeUncontrolled: true });

    const exactClient = clientList.find((client) => {
      const clientUrl = new URL(client.url);
      return clientUrl.pathname === targetUrl.pathname && clientUrl.search === targetUrl.search;
    });

    if (exactClient?.focus) return exactClient.focus();

    const appClient = clientList.find((client) => new URL(client.url).origin === self.location.origin);
    if (appClient) {
      if (appClient.navigate) {
        const navigated = await appClient.navigate(targetUrl.href);
        return navigated?.focus ? navigated.focus() : appClient.focus();
      }
      return appClient.focus();
    }

    if (clients.openWindow) return clients.openWindow(targetUrl.href);
    return undefined;
  })());
});
