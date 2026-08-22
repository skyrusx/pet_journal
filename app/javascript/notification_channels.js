function initNotificationChannelForms() {
  document.querySelectorAll("[data-notification-channel-form]").forEach((form) => {
    const select = form.querySelector("[data-channel-type-select]");
    const label = form.querySelector("[data-channel-address-label]");
    const input = form.querySelector("[data-channel-address-input]");
    const hint = form.querySelector("[data-channel-hint]");

    if (!select || !label || !input || !hint || select.dataset.pjNotificationBound === "true") return;
    select.dataset.pjNotificationBound = "true";

    const copy = {
      email: {
        label: "Email",
        placeholder: "name@example.ru",
        hint: "Укажите адрес электронной почты, на который будут приходить уведомления."
      },
      telegram: {
        label: "Chat ID Telegram",
        placeholder: "Например, 123456789",
        hint: "Укажите chat_id диалога с Telegram-ботом PetJournal."
      },
      vk: {
        label: "Peer ID VK",
        placeholder: "Например, 2000000001",
        hint: "Укажите peer_id диалога VK, куда PetJournal сможет отправлять сообщения."
      }
    };

    const refresh = () => {
      const current = copy[select.value] || copy.email;
      label.textContent = current.label;
      input.placeholder = current.placeholder;
      hint.textContent = current.hint;
    };

    select.addEventListener("change", refresh);
    refresh();
  });
}

document.addEventListener("DOMContentLoaded", initNotificationChannelForms);
document.addEventListener("turbo:load", initNotificationChannelForms);
document.addEventListener("turbo:render", initNotificationChannelForms);
