function formatRussianPhone(value) {
  let digits = value.replace(/\D/g, "");
  if (!digits) return "";

  if (digits.startsWith("8")) digits = `7${digits.slice(1)}`;
  if (!digits.startsWith("7")) digits = `7${digits}`;
  digits = digits.slice(0, 11);

  const local = digits.slice(1);
  let result = "+7";

  if (local.length > 0) result += ` (${local.slice(0, 3)}`;
  if (local.length >= 3) result += ")";
  if (local.length > 3) result += ` ${local.slice(3, 6)}`;
  if (local.length > 6) result += `-${local.slice(6, 8)}`;
  if (local.length > 8) result += `-${local.slice(8, 10)}`;

  return result;
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

    if (input.value.trim() !== "") input.value = formatRussianPhone(input.value);

    input.addEventListener("input", () => {
      input.value = formatRussianPhone(input.value);
    });
  });
}

document.addEventListener("DOMContentLoaded", initAccountProfile);
document.addEventListener("turbo:load", initAccountProfile);
document.addEventListener("turbo:render", initAccountProfile);
