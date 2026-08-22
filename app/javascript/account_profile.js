function normalizeRussianPhonePrefix(value) {
  const raw = value.toString();
  const trimmed = raw.trim();
  if (!trimmed) return "";

  if (trimmed.startsWith("+7")) return trimmed;
  if (trimmed.startsWith("8")) return `+7${trimmed.slice(1)}`;
  if (trimmed.startsWith("7")) return `+7${trimmed.slice(1)}`;

  return `+7 ${trimmed}`;
}

function initAccountProfile() {
  document.querySelectorAll("[data-account-avatar-input]").forEach((input) => {
    if (input.dataset.pjAccountAvatarBound === "true") return;
    input.dataset.pjAccountAvatarBound = "true";

    input.addEventListener("change", () => {
      const file = input.files?.[0];
      const form = input.closest("form");
      const preview = form?.querySelector("[data-account-avatar-preview]");
      const removeFlag = form?.querySelector("[data-account-avatar-remove-flag]");
      const removeButton = form?.querySelector("[data-account-avatar-remove]");
      if (!file || !preview || !file.type.startsWith("image/")) return;

      if (removeFlag) removeFlag.value = "0";
      if (removeButton) removeButton.hidden = false;

      const url = URL.createObjectURL(file);
      preview.innerHTML = "";
      const image = document.createElement("img");
      image.src = url;
      image.alt = "Предпросмотр фото профиля";
      image.addEventListener("load", () => URL.revokeObjectURL(url), { once: true });
      preview.appendChild(image);
    });
  });

  document.querySelectorAll("[data-account-avatar-remove]").forEach((button) => {
    if (button.dataset.pjAccountAvatarRemoveBound === "true") return;
    button.dataset.pjAccountAvatarRemoveBound = "true";

    button.addEventListener("click", () => {
      const form = button.closest("form");
      const preview = form?.querySelector("[data-account-avatar-preview]");
      const input = form?.querySelector("[data-account-avatar-input]");
      const removeFlag = form?.querySelector("[data-account-avatar-remove-flag]");
      if (!preview || !removeFlag) return;

      removeFlag.value = "1";
      if (input) input.value = "";
      preview.innerHTML = "";

      const fallback = document.createElement("span");
      fallback.dataset.accountAvatarFallback = "true";
      fallback.textContent = preview.dataset.accountAvatarLetter || "P";
      preview.appendChild(fallback);
      button.hidden = true;
    });
  });

  document.querySelectorAll("[data-account-phone-input]").forEach((input) => {
    if (input.dataset.pjAccountPhoneBound === "true") return;
    input.dataset.pjAccountPhoneBound = "true";

    if (input.value.trim() !== "") input.value = normalizeRussianPhonePrefix(input.value);

    input.addEventListener("focus", () => {
      if (input.value.trim() === "") {
        input.value = "+7 ";
        input.setSelectionRange(input.value.length, input.value.length);
      }
    });

    input.addEventListener("input", () => {
      const value = input.value;
      if (value === "" || value.startsWith("+7")) return;

      input.value = normalizeRussianPhonePrefix(value);
      input.setSelectionRange(input.value.length, input.value.length);
    });

    input.addEventListener("blur", () => {
      if (/^\+7\s*$/.test(input.value)) input.value = "";
    });
  });
}

document.addEventListener("DOMContentLoaded", initAccountProfile);
document.addEventListener("turbo:load", initAccountProfile);
document.addEventListener("turbo:render", initAccountProfile);
