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
    icon: "/icon.png",
    badge: "/icon.png",
    data: { path: payload.path || "/pets" },
    silent: false
  };

  if (payload.tag) {
    notificationOptions.tag = payload.tag;
    notificationOptions.renotify = true;
  }

  if (payload.timestamp) {
    notificationOptions.timestamp = payload.timestamp;
  }

  if (payload.require_interaction === true) {
    notificationOptions.requireInteraction = true;
  }

  event.waitUntil(
    self.registration.showNotification(payload.title, notificationOptions)
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      const targetPath = event.notification.data?.path || "/pets";
      const targetUrl = new URL(targetPath, self.location.origin);

      for (const client of clientList) {
        const clientUrl = new URL(client.url);

        if (clientUrl.pathname === targetUrl.pathname && clientUrl.search === targetUrl.search && "focus" in client) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetUrl.href);
      }
    })
  );
});
