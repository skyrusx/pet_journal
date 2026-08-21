function revokePreviewUrl(input) {
  if (!input.dataset.petPreviewUrl) return;

  URL.revokeObjectURL(input.dataset.petPreviewUrl);
  delete input.dataset.petPreviewUrl;
}

function petPhotoElements(input) {
  const control = input.closest("[data-pet-photo-control]");
  const upload = input.closest(".pj-pet-photo-upload");
  if (!control || !upload) return null;

  return {
    control,
    upload,
    empty: upload.querySelector(".pj-pet-photo-upload__empty"),
    change: upload.querySelector(".pj-pet-photo-upload__change"),
    removeButton: control.querySelector("[data-pet-photo-remove]"),
    removeFlag: control.querySelector("[data-pet-photo-remove-flag]")
  };
}

function renderPetPhotoPreview(input) {
  const file = input.files?.[0];
  if (!file || !file.type.startsWith("image/")) return;

  const elements = petPhotoElements(input);
  if (!elements) return;

  revokePreviewUrl(input);

  const previewUrl = URL.createObjectURL(file);
  input.dataset.petPreviewUrl = previewUrl;

  let preview = elements.upload.querySelector(".pj-pet-photo-upload__preview");
  if (!preview) {
    preview = document.createElement("img");
    preview.className = "pj-pet-photo-upload__preview";
    preview.alt = "Предпросмотр фото питомца";
    elements.upload.insertBefore(preview, elements.empty || input);
  }

  preview.src = previewUrl;
  preview.hidden = false;
  if (elements.empty) elements.empty.hidden = true;
  if (elements.change) elements.change.hidden = false;
  if (elements.removeButton) elements.removeButton.hidden = false;
  if (elements.removeFlag) elements.removeFlag.value = "0";
}

function clearPetPhoto(input) {
  const elements = petPhotoElements(input);
  if (!elements) return;

  revokePreviewUrl(input);
  input.value = "";

  const preview = elements.upload.querySelector(".pj-pet-photo-upload__preview");
  if (preview) preview.hidden = true;
  if (elements.empty) elements.empty.hidden = false;
  if (elements.change) elements.change.hidden = true;
  if (elements.removeButton) elements.removeButton.hidden = true;

  if (elements.removeFlag) {
    elements.removeFlag.value = elements.control.dataset.hasExistingPhoto === "true" ? "1" : "0";
  }
}

function initPetPhotoPreview() {
  document.querySelectorAll(".pj-pet-photo-upload__input").forEach((input) => {
    if (input.dataset.petPhotoPreviewBound === "true") return;

    input.dataset.petPhotoPreviewBound = "true";
    input.addEventListener("change", () => renderPetPhotoPreview(input));

    const control = input.closest("[data-pet-photo-control]");
    const removeButton = control?.querySelector("[data-pet-photo-remove]");
    if (removeButton && removeButton.dataset.petPhotoRemoveBound !== "true") {
      removeButton.dataset.petPhotoRemoveBound = "true";
      removeButton.addEventListener("click", () => clearPetPhoto(input));
    }
  });
}

function cleanupPetPhotoPreviews() {
  document.querySelectorAll(".pj-pet-photo-upload__input[data-pet-preview-url]").forEach(revokePreviewUrl);
}

document.addEventListener("DOMContentLoaded", initPetPhotoPreview);
document.addEventListener("turbo:load", initPetPhotoPreview);
document.addEventListener("turbo:render", initPetPhotoPreview);
document.addEventListener("turbo:before-cache", cleanupPetPhotoPreviews);
