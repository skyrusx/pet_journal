function initAccountProfile() {
  document.querySelectorAll("[data-account-avatar-input]").forEach((input) => {
    if (input.dataset.pjAccountAvatarBound === "true") return;
    input.dataset.pjAccountAvatarBound = "true";

    input.addEventListener("change", () => {
      const file = input.files?.[0];
      const preview = input.closest("form")?.querySelector("[data-account-avatar-preview]");
      if (!file || !preview || !file.type.startsWith("image/")) return;

      const url = URL.createObjectURL(file);
      preview.innerHTML = "";
      const image = document.createElement("img");
      image.src = url;
      image.alt = "Предпросмотр фото профиля";
      image.addEventListener("load", () => URL.revokeObjectURL(url), { once: true });
      preview.appendChild(image);
    });
  });

  document.querySelectorAll("[data-account-password-toggle]").forEach((button) => {
    if (button.dataset.pjAccountPasswordBound === "true") return;
    button.dataset.pjAccountPasswordBound = "true";

    button.addEventListener("click", () => {
      const field = button.closest(".pj-account-password-field");
      const input = field?.querySelector("[data-account-password-input]");
      if (!input) return;

      const shouldShow = input.type === "password";
      input.type = shouldShow ? "text" : "password";
      button.textContent = shouldShow ? "Скрыть" : "Показать";
      button.setAttribute("aria-label", shouldShow ? "Скрыть пароль" : "Показать пароль");
    });
  });
}

document.addEventListener("DOMContentLoaded", initAccountProfile);
document.addEventListener("turbo:load", initAccountProfile);
document.addEventListener("turbo:render", initAccountProfile);
