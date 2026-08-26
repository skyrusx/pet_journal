function extractRussianLocalDigits(value) {
  let digits = value.toString().replace(/\D/g, "");
  const trimmed = value.toString().trim();

  if (trimmed.startsWith("+7")) {
    digits = digits.slice(1);
  } else if (digits.length > 10 && (digits.startsWith("7") || digits.startsWith("8"))) {
    digits = digits.slice(1);
  }

  return digits.slice(0, 10);
}

function formatRussianPhone(value) {
  const local = extractRussianLocalDigits(value);
  let result = "+7";

  if (local.length === 0) return "+7 ";

  result += ` (${local.slice(0, 3)}`;
  if (local.length >= 3) result += ")";
  if (local.length > 3) result += ` ${local.slice(3, 6)}`;
  if (local.length > 6) result += `-${local.slice(6, 8)}`;
  if (local.length > 8) result += `-${local.slice(8, 10)}`;

  return result;
}

function phoneCaretPosition(formattedValue, localDigitCount) {
  if (localDigitCount <= 0) return Math.min(3, formattedValue.length);

  let seen = 0;
  let position = Math.min(3, formattedValue.length);

  for (let index = 2; index < formattedValue.length; index += 1) {
    if (/\d/.test(formattedValue[index])) {
      seen += 1;
      position = index + 1;

      if (seen >= localDigitCount) {
        while (position < formattedValue.length && !/\d/.test(formattedValue[position])) {
          position += 1;
        }
        break;
      }
    }
  }

  return position;
}

function removePhoneDigitAt(input, localIndex) {
  const local = extractRussianLocalDigits(input.value).split("");
  if (localIndex < 0 || localIndex >= local.length) return false;

  local.splice(localIndex, 1);
  input.value = formatRussianPhone(local.join(""));
  const caret = phoneCaretPosition(input.value, localIndex);
  input.setSelectionRange(caret, caret);
  return true;
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

    input.addEventListener("focus", () => {
      if (input.value.trim() === "") {
        input.value = "+7 ";
        input.setSelectionRange(input.value.length, input.value.length);
      }
    });

    input.addEventListener("beforeinput", (event) => {
      if (event.inputType !== "deleteContentBackward" && event.inputType !== "deleteContentForward") return;
      if (input.selectionStart == null || input.selectionEnd == null || input.selectionStart !== input.selectionEnd) return;

      const caret = input.selectionStart;
      const isBackward = event.inputType === "deleteContentBackward";
      const adjacentIndex = isBackward ? caret - 1 : caret;
      const adjacentChar = input.value[adjacentIndex];

      if (adjacentIndex < 0 || /\d/.test(adjacentChar || "")) return;

      const digitsBeforeCaret = extractRussianLocalDigits(input.value.slice(0, caret)).length;
      const localIndex = isBackward ? digitsBeforeCaret - 1 : digitsBeforeCaret;

      if (removePhoneDigitAt(input, localIndex)) event.preventDefault();
    });

    input.addEventListener("input", () => {
      const caret = input.selectionStart ?? input.value.length;
      const digitsBeforeCaret = extractRussianLocalDigits(input.value.slice(0, caret)).length;

      input.value = formatRussianPhone(input.value);

      const nextCaret = phoneCaretPosition(input.value, digitsBeforeCaret);
      input.setSelectionRange(nextCaret, nextCaret);
    });

    input.addEventListener("blur", () => {
      if (/^\+7\s*$/.test(input.value)) input.value = "";
    });
  });
}

document.addEventListener("DOMContentLoaded", initAccountProfile);
document.addEventListener("turbo:load", initAccountProfile);
document.addEventListener("turbo:render", initAccountProfile);
