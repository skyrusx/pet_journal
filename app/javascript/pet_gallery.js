function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content || "";
}

function bindOnce(element, key) {
  const attribute = `data-pet-gallery-bound-${key}`;
  if (element.hasAttribute(attribute)) return false;
  element.setAttribute(attribute, "true");
  return true;
}

async function jsonRequest(url, method, body = null) {
  const response = await fetch(url, {
    method,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: body ? JSON.stringify(body) : null
  });

  let payload = {};
  if (response.status !== 204) {
    try {
      payload = await response.json();
    } catch (_error) {
      payload = {};
    }
  }

  if (!response.ok) throw new Error(payload.error || "Не удалось сохранить изменения.");
  return payload;
}

function refreshPage() {
  if (window.Turbo?.visit) {
    window.Turbo.visit(window.location.href, { action: "replace" });
  } else {
    window.location.reload();
  }
}

function initUploadPreview(root) {
  root.querySelectorAll("[data-pet-gallery-upload]").forEach((upload) => {
    if (!bindOnce(upload, "upload")) return;

    const input = upload.querySelector("[data-pet-gallery-file-input]");
    const staged = upload.querySelector("[data-pet-gallery-staged]");
    const message = upload.querySelector("[data-pet-gallery-upload-message]");
    if (!input || !staged) return;

    const existingCount = Number(upload.dataset.existingCount || 0);
    const maxCount = Number(upload.dataset.maxCount || 20);
    const maxBytes = Number(upload.dataset.maxBytes || 5242880);
    const accepted = ["image/jpeg", "image/png", "image/webp"];
    let objectUrls = [];

    input.addEventListener("change", () => {
      objectUrls.forEach((url) => URL.revokeObjectURL(url));
      objectUrls = [];
      staged.replaceChildren();
      if (message) message.textContent = "";

      const files = [...input.files];
      if (existingCount + files.length > maxCount) {
        input.value = "";
        if (message) message.textContent = `Можно загрузить не больше ${maxCount} фотографий питомца.`;
        return;
      }

      const invalid = files.find((file) => !accepted.includes(file.type) || file.size > maxBytes);
      if (invalid) {
        input.value = "";
        if (message) message.textContent = "Поддерживаются JPEG, PNG и WebP до 5 МБ каждый.";
        return;
      }

      files.forEach((file) => {
        const url = URL.createObjectURL(file);
        objectUrls.push(url);
        const item = document.createElement("span");
        item.className = "pj-pet-gallery-staged__item";
        const image = document.createElement("img");
        image.src = url;
        image.alt = "Новое фото";
        item.appendChild(image);
        staged.appendChild(item);
      });

      if (message && files.length > 0) {
        message.textContent = `${files.length} фото будет добавлено после сохранения профиля.`;
      }
    });
  });
}

function initSorting(root) {
  root.querySelectorAll("[data-pet-gallery-editor]").forEach((editor) => {
    if (!bindOnce(editor, "sorting")) return;

    const list = editor.querySelector("[data-pet-gallery-sort-list]");
    const status = editor.querySelector("[data-pet-gallery-status]");
    if (!list) return;

    editor.querySelectorAll("[data-pet-gallery-drag]").forEach((handle) => {
      handle.addEventListener("pointerdown", (event) => {
        if (event.button !== 0 && event.pointerType === "mouse") return;

        const card = handle.closest("[data-pet-gallery-card]");
        if (!card) return;

        event.preventDefault();
        handle.setPointerCapture?.(event.pointerId);
        card.classList.add("is-sorting");
        const initialOrder = [...list.querySelectorAll("[data-pet-gallery-card]")].map((item) => item.dataset.photoId).join(",");

        const move = (moveEvent) => {
          const target = document.elementFromPoint(moveEvent.clientX, moveEvent.clientY)?.closest("[data-pet-gallery-card]");
          if (!target || target === card || target.parentElement !== list) return;

          const rect = target.getBoundingClientRect();
          const sameRow = moveEvent.clientY >= rect.top && moveEvent.clientY <= rect.bottom;
          const before = moveEvent.clientY < rect.top + rect.height / 2 ||
            (sameRow && Math.abs(moveEvent.clientY - (rect.top + rect.height / 2)) < rect.height * 0.35 && moveEvent.clientX < rect.left + rect.width / 2);
          list.insertBefore(card, before ? target : target.nextSibling);
        };

        const finish = async () => {
          handle.removeEventListener("pointermove", move);
          handle.removeEventListener("pointerup", finish);
          handle.removeEventListener("pointercancel", cancel);
          card.classList.remove("is-sorting");

          const ids = [...list.querySelectorAll("[data-pet-gallery-card]")].map((item) => Number(item.dataset.photoId));
          if (ids.join(",") === initialOrder) return;

          if (status) status.textContent = "Сохраняем порядок…";
          try {
            await jsonRequest(editor.dataset.reorderUrl, "PATCH", { photo_ids: ids });
            if (status) status.textContent = "Порядок сохранён.";
          } catch (error) {
            if (status) status.textContent = error.message;
            window.setTimeout(refreshPage, 900);
          }
        };

        const cancel = () => {
          handle.removeEventListener("pointermove", move);
          handle.removeEventListener("pointerup", finish);
          handle.removeEventListener("pointercancel", cancel);
          card.classList.remove("is-sorting");
          refreshPage();
        };

        handle.addEventListener("pointermove", move);
        handle.addEventListener("pointerup", finish, { once: true });
        handle.addEventListener("pointercancel", cancel, { once: true });
      });
    });

    editor.querySelectorAll("[data-pet-gallery-delete]").forEach((button) => {
      button.addEventListener("click", async () => {
        if (!window.confirm(button.dataset.confirm || "Удалить фотографию?")) return;

        button.disabled = true;
        if (status) status.textContent = "Удаляем фотографию…";
        try {
          await jsonRequest(button.dataset.url, "DELETE");
          refreshPage();
        } catch (error) {
          button.disabled = false;
          if (status) status.textContent = error.message;
        }
      });
    });
  });
}

function initCropModal(root) {
  const modal = root.querySelector("[data-pet-crop-modal]");
  if (!modal || !bindOnce(modal, "modal")) return;

  const stage = modal.querySelector("[data-pet-crop-stage]");
  const image = modal.querySelector("[data-pet-crop-image]");
  const zoomInput = modal.querySelector("[data-pet-crop-zoom]");
  const saveButton = modal.querySelector("[data-pet-crop-save]");
  const errorBox = modal.querySelector("[data-pet-crop-error]");
  let activeTrigger = null;
  let returnFocus = null;
  let naturalWidth = 0;
  let naturalHeight = 0;
  let minScale = 1;
  let scale = 1;
  let offsetX = 0;
  let offsetY = 0;

  const viewport = () => stage.getBoundingClientRect();

  const clampOffsets = () => {
    const rect = viewport();
    const renderedWidth = naturalWidth * scale;
    const renderedHeight = naturalHeight * scale;
    offsetX = Math.min(0, Math.max(rect.width - renderedWidth, offsetX));
    offsetY = Math.min(0, Math.max(rect.height - renderedHeight, offsetY));
  };

  const render = () => {
    clampOffsets();
    image.style.width = `${naturalWidth}px`;
    image.style.height = `${naturalHeight}px`;
    image.style.transform = `translate(${offsetX}px, ${offsetY}px) scale(${scale})`;
  };

  const centerImage = () => {
    const rect = viewport();
    offsetX = (rect.width - naturalWidth * scale) / 2;
    offsetY = (rect.height - naturalHeight * scale) / 2;
    render();
  };

  const applyInitialCrop = () => {
    const rect = viewport();
    minScale = Math.max(rect.width / naturalWidth, rect.height / naturalHeight);
    const cropWidth = Number(activeTrigger?.dataset.cropWidth || 0);
    const cropHeight = Number(activeTrigger?.dataset.cropHeight || 0);
    const cropX = Number(activeTrigger?.dataset.cropX || 0);
    const cropY = Number(activeTrigger?.dataset.cropY || 0);

    if (cropWidth > 0 && cropHeight > 0) {
      scale = rect.width / (naturalWidth * cropWidth);
      const zoom = Math.min(4, Math.max(1, scale / minScale));
      scale = minScale * zoom;
      zoomInput.value = String(zoom);
      offsetX = -(naturalWidth * cropX * scale);
      offsetY = -(naturalHeight * cropY * scale);
      render();
    } else {
      scale = minScale;
      zoomInput.value = "1";
      centerImage();
    }
  };

  const close = () => {
    modal.hidden = true;
    modal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("pj-modal-open");
    image.removeAttribute("src");
    errorBox.textContent = "";
    returnFocus?.focus();
    activeTrigger = null;
  };

  root.querySelectorAll("[data-pet-crop-trigger]").forEach((trigger) => {
    if (!bindOnce(trigger, "crop-trigger")) return;

    trigger.addEventListener("click", () => {
      activeTrigger = trigger;
      returnFocus = trigger;
      errorBox.textContent = "";
      modal.hidden = false;
      modal.setAttribute("aria-hidden", "false");
      document.body.classList.add("pj-modal-open");
      image.src = trigger.dataset.photoSrc;
      window.setTimeout(() => modal.querySelector("[data-pet-crop-close]")?.focus(), 0);
    });
  });

  image.addEventListener("load", () => {
    naturalWidth = image.naturalWidth;
    naturalHeight = image.naturalHeight;
    applyInitialCrop();
  });

  zoomInput.addEventListener("input", () => {
    if (!naturalWidth || !naturalHeight) return;

    const rect = viewport();
    const sourceCenterX = (rect.width / 2 - offsetX) / scale;
    const sourceCenterY = (rect.height / 2 - offsetY) / scale;
    scale = minScale * Number(zoomInput.value);
    offsetX = rect.width / 2 - sourceCenterX * scale;
    offsetY = rect.height / 2 - sourceCenterY * scale;
    render();
  });

  stage.addEventListener("pointerdown", (event) => {
    if (!naturalWidth || !naturalHeight) return;

    event.preventDefault();
    stage.setPointerCapture?.(event.pointerId);
    const startX = event.clientX;
    const startY = event.clientY;
    const initialX = offsetX;
    const initialY = offsetY;

    const move = (moveEvent) => {
      offsetX = initialX + moveEvent.clientX - startX;
      offsetY = initialY + moveEvent.clientY - startY;
      render();
    };

    const finish = () => {
      stage.removeEventListener("pointermove", move);
      stage.removeEventListener("pointerup", finish);
      stage.removeEventListener("pointercancel", finish);
    };

    stage.addEventListener("pointermove", move);
    stage.addEventListener("pointerup", finish, { once: true });
    stage.addEventListener("pointercancel", finish, { once: true });
  });

  modal.querySelectorAll("[data-pet-crop-close]").forEach((button) => button.addEventListener("click", close));

  saveButton.addEventListener("click", async () => {
    if (!activeTrigger || !naturalWidth || !naturalHeight) return;

    const rect = viewport();
    const crop = {
      avatar_crop_x: Math.max(0, -offsetX / (naturalWidth * scale)),
      avatar_crop_y: Math.max(0, -offsetY / (naturalHeight * scale)),
      avatar_crop_width: Math.min(1, rect.width / (naturalWidth * scale)),
      avatar_crop_height: Math.min(1, rect.height / (naturalHeight * scale))
    };

    saveButton.disabled = true;
    errorBox.textContent = "";
    try {
      await jsonRequest(activeTrigger.dataset.url, "PATCH", { pet_photo: crop });
      refreshPage();
    } catch (error) {
      errorBox.textContent = error.message;
      saveButton.disabled = false;
    }
  });

  modal.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
  });
}

function initLightbox(root) {
  const modal = root.querySelector("[data-pet-lightbox]");
  const triggers = [...root.querySelectorAll("[data-pet-lightbox-open]")];
  if (!modal || triggers.length === 0 || !bindOnce(modal, "lightbox")) return;

  const image = modal.querySelector("[data-pet-lightbox-image]");
  const counter = modal.querySelector("[data-pet-lightbox-counter]");
  const stage = modal.querySelector("[data-pet-lightbox-stage]");
  let index = 0;
  let returnFocus = null;

  const render = () => {
    const trigger = triggers[index];
    image.src = trigger.dataset.src;
    image.alt = trigger.dataset.alt || "Фото питомца";
    counter.textContent = `${index + 1} / ${triggers.length}`;
  };

  const open = (nextIndex, trigger) => {
    index = nextIndex;
    returnFocus = trigger;
    render();
    modal.hidden = false;
    modal.setAttribute("aria-hidden", "false");
    document.body.classList.add("pj-modal-open");
    window.setTimeout(() => modal.querySelector("[data-pet-lightbox-close]")?.focus(), 0);
  };

  const close = () => {
    modal.hidden = true;
    modal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("pj-modal-open");
    image.removeAttribute("src");
    returnFocus?.focus();
  };

  const previous = () => {
    index = (index - 1 + triggers.length) % triggers.length;
    render();
  };

  const next = () => {
    index = (index + 1) % triggers.length;
    render();
  };

  triggers.forEach((trigger, triggerIndex) => trigger.addEventListener("click", () => open(triggerIndex, trigger)));
  modal.querySelectorAll("[data-pet-lightbox-close]").forEach((button) => button.addEventListener("click", close));
  modal.querySelector("[data-pet-lightbox-prev]")?.addEventListener("click", previous);
  modal.querySelector("[data-pet-lightbox-next]")?.addEventListener("click", next);

  modal.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
    if (event.key === "ArrowLeft") previous();
    if (event.key === "ArrowRight") next();
  });

  let swipeStartX = null;
  stage?.addEventListener("pointerdown", (event) => {
    swipeStartX = event.clientX;
    stage.setPointerCapture?.(event.pointerId);
  });
  stage?.addEventListener("pointerup", (event) => {
    if (swipeStartX === null) return;
    const distance = event.clientX - swipeStartX;
    swipeStartX = null;
    if (Math.abs(distance) < 45) return;
    distance > 0 ? previous() : next();
  });
}

function initPetGallery(root = document) {
  initUploadPreview(root);
  initSorting(root);
  initCropModal(root);
  initLightbox(root);
}

document.addEventListener("DOMContentLoaded", () => initPetGallery());
document.addEventListener("turbo:load", () => initPetGallery());
document.addEventListener("turbo:render", () => initPetGallery());
