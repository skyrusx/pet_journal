const TELEGRAM_CONNECT_STORAGE_KEY = "pjTelegramConnectReturn";
let telegramReturnListenerBound = false;

function base64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = window.atob(base64);
  const output = new Uint8Array(rawData.length);

  for (let index = 0; index < rawData.length; index += 1) {
    output[index] = rawData.charCodeAt(index);
  }

  return output;
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content") || "";
}

function applicationServerKeyMatches(subscription, expectedKey) {
  const existingKey = subscription?.options?.applicationServerKey;
  if (!existingKey) return true;

  const existing = new Uint8Array(existingKey);
  if (existing.length !== expectedKey.length) return false;

  return existing.every((value, index) => value === expectedKey[index]);
}

async function ensurePushRegistration() {
  await navigator.serviceWorker.register("/service-worker", { scope: "/" });
  return navigator.serviceWorker.ready;
}

async function savePushSubscription(subscription) {
  const response = await fetch("/web_push_subscription", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: JSON.stringify({ subscription: subscription.toJSON() })
  });
  const body = await response.json();

  if (!response.ok) throw new Error(body.message || "Не удалось сохранить push-подписку.");
  return body;
}

async function deletePushSubscription(endpoint) {
  const response = await fetch("/web_push_subscription", {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: JSON.stringify({ endpoint })
  });
  const body = await response.json();

  if (!response.ok) throw new Error(body.message || "Не удалось отключить push-подписку.");
  return body;
}

function initWebPushControls() {
  document.querySelectorAll("[data-web-push-panel]").forEach((panel) => {
    // application.js contains the legacy implementation. Claim the same guard
    // before its DOM/Turbo handler runs so only this production-ready flow binds.
    if (panel.hasAttribute("data-pj-bound-web-push-panel")) return;
    panel.setAttribute("data-pj-bound-web-push-panel", "true");

    const enableButton = panel.querySelector("[data-web-push-enable]");
    const disableButton = panel.querySelector("[data-web-push-disable]");
    const status = panel.querySelector("[data-web-push-status]");
    const vapidPublicKey = panel.dataset.vapidPublicKey;

    if (!enableButton || !disableButton || !status || !vapidPublicKey) return;

    const supported = "serviceWorker" in navigator && "PushManager" in window && "Notification" in window;
    if (!supported) {
      enableButton.disabled = true;
      disableButton.disabled = true;
      status.textContent = "Этот браузер не поддерживает Web Push.";
      return;
    }

    const refreshState = async () => {
      if (Notification.permission === "denied") {
        enableButton.disabled = true;
        disableButton.disabled = true;
        status.textContent = "Уведомления запрещены в настройках браузера. Разрешите их для PetJournal и обновите страницу.";
        return;
      }

      try {
        const registration = await navigator.serviceWorker.getRegistration("/");
        const subscription = await registration?.pushManager.getSubscription();

        if (subscription) {
          enableButton.disabled = true;
          disableButton.disabled = false;
          status.textContent = "Push-уведомления включены для этого браузера.";
        } else {
          enableButton.disabled = false;
          disableButton.disabled = true;
          status.textContent = Notification.permission === "granted"
            ? "Разрешение уже выдано. Нажмите «Включить push», чтобы подключить этот браузер."
            : "Браузер запросит разрешение только после нажатия «Включить push».";
        }
      } catch (_error) {
        enableButton.disabled = false;
        disableButton.disabled = true;
        status.textContent = "Не удалось проверить состояние push. Попробуйте обновить страницу.";
      }
    };

    enableButton.addEventListener("click", async () => {
      enableButton.disabled = true;
      disableButton.disabled = true;
      status.textContent = "Подключаем push-уведомления...";

      try {
        const permission = Notification.permission === "granted"
          ? "granted"
          : await Notification.requestPermission();

        if (permission !== "granted") {
          status.textContent = permission === "denied"
            ? "Уведомления запрещены. Разрешите их в настройках браузера для PetJournal."
            : "Разрешение на уведомления не выдано.";
          await refreshState();
          return;
        }

        const registration = await ensurePushRegistration();
        const expectedKey = base64ToUint8Array(vapidPublicKey);
        let subscription = await registration.pushManager.getSubscription();

        // A subscription is bound to the VAPID public key. If keys were rotated,
        // recreate it instead of keeping a subscription that the server cannot use.
        if (subscription && !applicationServerKeyMatches(subscription, expectedKey)) {
          await subscription.unsubscribe();
          subscription = null;
        }

        subscription ||= await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: expectedKey
        });

        const body = await savePushSubscription(subscription);
        status.textContent = body.message;
        enableButton.disabled = true;
        disableButton.disabled = false;
      } catch (error) {
        status.textContent = error?.message || "Не удалось включить push-уведомления.";
        await refreshState();
      }
    });

    disableButton.addEventListener("click", async () => {
      enableButton.disabled = true;
      disableButton.disabled = true;
      status.textContent = "Отключаем push-уведомления...";

      try {
        const registration = await navigator.serviceWorker.getRegistration("/");
        const subscription = await registration?.pushManager.getSubscription();

        if (!subscription) {
          status.textContent = "В этом браузере нет активной push-подписки.";
          await refreshState();
          return;
        }

        // First remove the server-side channel. If that fails, keep the browser
        // subscription intact so the user can safely retry the operation.
        const body = await deletePushSubscription(subscription.endpoint);
        await subscription.unsubscribe();
        status.textContent = body.message;
        enableButton.disabled = false;
        disableButton.disabled = true;
      } catch (error) {
        status.textContent = error?.message || "Не удалось отключить push-уведомления.";
        await refreshState();
      }
    });

    refreshState();
  });
}

function initTelegramReturnListener() {
  if (telegramReturnListenerBound) return;
  telegramReturnListenerBound = true;

  const returnToChannels = () => {
    const raw = sessionStorage.getItem(TELEGRAM_CONNECT_STORAGE_KEY);
    if (!raw) return;

    try {
      const state = JSON.parse(raw);
      const elapsed = Date.now() - Number(state.startedAt || 0);
      if (elapsed < 1200) return;

      sessionStorage.removeItem(TELEGRAM_CONNECT_STORAGE_KEY);
      window.location.assign(state.returnUrl || "/notification_channels");
    } catch (_error) {
      sessionStorage.removeItem(TELEGRAM_CONNECT_STORAGE_KEY);
    }
  };

  window.addEventListener("focus", returnToChannels);
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") returnToChannels();
  });
}

function initNotificationChannelForms() {
  initTelegramReturnListener();
  initWebPushControls();

  document.querySelectorAll("[data-telegram-connect-link]").forEach((link) => {
    if (link.dataset.pjTelegramBound === "true") return;
    link.dataset.pjTelegramBound = "true";

    link.addEventListener("click", () => {
      sessionStorage.setItem(TELEGRAM_CONNECT_STORAGE_KEY, JSON.stringify({
        startedAt: Date.now(),
        returnUrl: link.dataset.returnUrl || "/notification_channels"
      }));
    });
  });

  document.querySelectorAll("[data-notification-channel-form]").forEach((form) => {
    const select = form.querySelector("[data-channel-type-select]");
    if (!select || select.dataset.pjNotificationBound === "true") return;

    const label = form.querySelector("[data-channel-address-label]");
    const input = form.querySelector("[data-channel-address-input]");
    const hint = form.querySelector("[data-channel-hint]");
    const nameInput = form.querySelector("[data-channel-name-input]");
    const telegramPanel = form.querySelector("[data-telegram-connect-panel]");
    const standardFields = form.querySelectorAll("[data-standard-channel-field]");
    const standardActions = form.querySelector("[data-standard-channel-actions]");
    const telegramActions = form.querySelector("[data-telegram-only-actions]");

    select.dataset.pjNotificationBound = "true";

    const copy = {
      email: {
        name: "Email",
        label: "Email",
        placeholder: "name@example.ru",
        hint: "Укажите адрес электронной почты, на который будут приходить уведомления."
      },
      telegram: {
        name: "Telegram",
        label: "Telegram",
        placeholder: "Подключается через бота",
        hint: "Telegram подключается через бота PetJournal — никаких chat_id вводить не нужно."
      },
      vk: {
        name: "VK",
        label: "Ваш профиль VK",
        placeholder: "Например, vk.ru/username или @username",
        hint: "Можно вставить ссылку на профиль, короткое имя или числовой ID. Остальное PetJournal определит сам."
      }
    };

    const defaultNames = Object.values(copy).map((item) => item.name);

    const refresh = () => {
      const currentType = select.value;
      const current = copy[currentType] || copy.email;
      const telegram = currentType === "telegram";

      if (label) label.textContent = current.label;
      if (input) {
        input.placeholder = current.placeholder;
        input.required = !telegram;
      }
      if (hint) hint.textContent = current.hint;

      if (nameInput && (nameInput.value.trim() === "" || defaultNames.includes(nameInput.value.trim()))) {
        nameInput.value = current.name;
      }

      standardFields.forEach((field) => { field.hidden = telegram; });
      if (telegramPanel) telegramPanel.hidden = !telegram;
      if (standardActions) standardActions.hidden = telegram;
      if (telegramActions) telegramActions.hidden = !telegram;
    };

    select.addEventListener("change", refresh);
    refresh();
  });
}

// Module scripts run after HTML parsing, so claim the Web Push panel immediately
// before application.js gets its DOMContentLoaded callback.
initWebPushControls();

document.addEventListener("DOMContentLoaded", initNotificationChannelForms);
document.addEventListener("turbo:load", initNotificationChannelForms, true);
document.addEventListener("turbo:render", initNotificationChannelForms, true);
