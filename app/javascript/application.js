// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  localStorage.setItem("petjournal-theme", theme);

  document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
    button.setAttribute("aria-label", theme === "dark" ? "Включить светлую тему" : "Включить темную тему");
    button.setAttribute("title", theme === "dark" ? "Светлая тема" : "Темная тема");
    button.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
  });
}

function base64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; i += 1) {
    outputArray[i] = rawData.charCodeAt(i);
  }

  return outputArray;
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
}

document.addEventListener("DOMContentLoaded", () => {
  const currentTheme = document.documentElement.dataset.theme || "light";
  applyTheme(currentTheme);

  document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      applyTheme(document.documentElement.dataset.theme === "dark" ? "light" : "dark");
    });
  });

  document.querySelectorAll("[data-flash-toast]").forEach((toast) => {
    const close = toast.querySelector("[data-flash-close]");
    const dismiss = () => {
      toast.classList.add("closing");
      window.setTimeout(() => toast.remove(), 180);
    };

    close?.addEventListener("click", dismiss);
    window.setTimeout(dismiss, 5200);
  });

  document.querySelectorAll("[data-web-push-panel]").forEach((panel) => {
    const button = panel.querySelector("[data-web-push-enable]");
    const status = panel.querySelector("[data-web-push-status]");
    const vapidPublicKey = panel.dataset.vapidPublicKey;

    if (!button || !status || !vapidPublicKey) return;

    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      button.disabled = true;
      status.textContent = "Этот браузер не поддерживает push-уведомления.";
      return;
    }

    button.addEventListener("click", async () => {
      button.disabled = true;
      status.textContent = "Запрашиваем разрешение...";

      try {
        const permission = await Notification.requestPermission();

        if (permission !== "granted") {
          status.textContent = "Разрешение на уведомления не выдано.";
          button.disabled = false;
          return;
        }

        const registration = await navigator.serviceWorker.register("/service-worker");
        const subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: base64ToUint8Array(vapidPublicKey)
        });

        const response = await fetch("/web_push_subscription", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken()
          },
          body: JSON.stringify({ subscription: subscription.toJSON() })
        });
        const body = await response.json();

        if (!response.ok) throw new Error(body.message || "Не удалось сохранить подписку.");

        status.textContent = body.message;
      } catch (error) {
        status.textContent = error.message;
        button.disabled = false;
      }
    });
  });
});
