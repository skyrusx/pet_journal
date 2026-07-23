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

  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: "/icon.png",
      badge: "/icon.png",
      data: { path: payload.path || "/pets" }
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      const targetPath = event.notification.data.path || "/pets";

      for (const client of clientList) {
        const clientPath = new URL(client.url).pathname;

        if (clientPath === targetPath && "focus" in client) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetPath);
      }
    })
  );
});
