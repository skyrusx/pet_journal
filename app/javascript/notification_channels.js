const TELEGRAM_CONNECT_STORAGE_KEY = "pjTelegramConnectReturn";
let telegramReturnListenerBound = false;

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

document.addEventListener("DOMContentLoaded", initNotificationChannelForms);
document.addEventListener("turbo:load", initNotificationChannelForms);
document.addEventListener("turbo:render", initNotificationChannelForms);
