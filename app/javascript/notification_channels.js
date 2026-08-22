function initNotificationChannelForms() {
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
        placeholder: "Например, vk.ru/skyrusx или @skyrusx",
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
