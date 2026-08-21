function revokePreviewUrl(input) {
  if (!input.dataset.petPreviewUrl) return;

  URL.revokeObjectURL(input.dataset.petPreviewUrl);
  delete input.dataset.petPreviewUrl;
}

function renderPetPhotoPreview(input) {
  const file = input.files?.[0];
  if (!file) return;
  if (!file.type.startsWith("image/")) return;

  const upload = input.closest(".pj-pet-photo-upload");
  if (!upload) return;

  revokePreviewUrl(input);

  const previewUrl = URL.createObjectURL(file);
  input.dataset.petPreviewUrl = previewUrl;

  let preview = upload.querySelector(".pj-pet-photo-upload__preview");
  if (!preview) {
    preview = document.createElement("img");
    preview.className = "pj-pet-photo-upload__preview";
    preview.alt = "Предпросмотр фото питомца";
    upload.insertBefore(preview, input);
  }

  preview.src = previewUrl;

  let change = upload.querySelector(".pj-pet-photo-upload__change");
  if (!change) {
    change = document.createElement("span");
    change.className = "pj-pet-photo-upload__change";
    change.setAttribute("aria-hidden", "true");
    change.textContent = "↻";
    upload.insertBefore(change, input);
  }
}

function initPetPhotoPreview() {
  document.querySelectorAll(".pj-pet-photo-upload__input").forEach((input) => {
    if (input.dataset.petPhotoPreviewBound === "true") return;

    input.dataset.petPhotoPreviewBound = "true";
    input.addEventListener("change", () => renderPetPhotoPreview(input));
  });
}

function cleanupPetPhotoPreviews() {
  document.querySelectorAll(".pj-pet-photo-upload__input[data-pet-preview-url]").forEach(revokePreviewUrl);
}

document.addEventListener("DOMContentLoaded", initPetPhotoPreview);
document.addEventListener("turbo:load", initPetPhotoPreview);
document.addEventListener("turbo:render", initPetPhotoPreview);
document.addEventListener("turbo:before-cache", cleanupPetPhotoPreviews);
