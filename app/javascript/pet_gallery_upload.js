function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content || "";
}

function refreshPage() {
  if (window.Turbo?.visit) {
    window.Turbo.visit(window.location.href, { action: "replace" });
  } else {
    window.location.reload();
  }
}

function initPetGalleryDirectUpload() {
  document.querySelectorAll("[data-pet-gallery-direct-upload]").forEach((input) => {
    if (input.dataset.petGalleryDirectUploadBound === "true") return;

    input.dataset.petGalleryDirectUploadBound = "true";
    input.addEventListener("change", async () => {
      const files = [...(input.files || [])];
      if (files.length === 0) return;

      const editor = input.closest("[data-pet-gallery-editor]");
      const status = editor?.querySelector("[data-pet-gallery-status]");
      const existingCount = Number(input.dataset.existingCount || 0);
      const maxCount = Number(input.dataset.maxCount || 20);
      const maxBytes = Number(input.dataset.maxBytes || 5242880);
      const acceptedTypes = ["image/jpeg", "image/png", "image/webp"];

      if (existingCount + files.length > maxCount) {
        input.value = "";
        if (status) status.textContent = `Можно загрузить не больше ${maxCount} фотографий питомца.`;
        return;
      }

      const invalidFile = files.find((file) => !acceptedTypes.includes(file.type) || file.size > maxBytes);
      if (invalidFile) {
        input.value = "";
        if (status) status.textContent = "Поддерживаются JPEG, PNG и WebP до 5 МБ каждый.";
        return;
      }

      const formData = new FormData();
      files.forEach((file) => formData.append("images[]", file));

      input.disabled = true;
      if (status) status.textContent = files.length === 1 ? "Добавляем фотографию…" : `Добавляем ${files.length} фото…`;

      try {
        const response = await fetch(input.dataset.uploadUrl, {
          method: "POST",
          headers: {
            Accept: "application/json",
            "X-CSRF-Token": csrfToken()
          },
          body: formData
        });

        let payload = {};
        try {
          payload = await response.json();
        } catch (_error) {
          payload = {};
        }

        if (!response.ok) throw new Error(payload.error || "Не удалось добавить фотографии.");

        if (status) status.textContent = "Фотографии добавлены.";
        refreshPage();
      } catch (error) {
        input.disabled = false;
        input.value = "";
        if (status) status.textContent = error.message;
      }
    });
  });
}

document.addEventListener("DOMContentLoaded", initPetGalleryDirectUpload);
document.addEventListener("turbo:load", initPetGalleryDirectUpload);
document.addEventListener("turbo:render", initPetGalleryDirectUpload);
