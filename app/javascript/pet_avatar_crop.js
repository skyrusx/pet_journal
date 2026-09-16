function applyResponsiveCrop(image) {
  const frame = image.closest(".pj-pet-avatar-frame");
  if (!frame || !image.naturalWidth || !image.naturalHeight) return;

  const cropX = Number(image.dataset.cropX || 0);
  const cropY = Number(image.dataset.cropY || 0);
  const cropWidth = Number(image.dataset.cropWidth || 0);
  const cropHeight = Number(image.dataset.cropHeight || 0);
  if (cropWidth <= 0 || cropHeight <= 0) return;

  const frameWidth = frame.clientWidth;
  const frameHeight = frame.clientHeight;
  if (!frameWidth || !frameHeight) return;

  const naturalWidth = image.naturalWidth;
  const naturalHeight = image.naturalHeight;
  const cropPixelWidth = naturalWidth * cropWidth;
  const cropPixelHeight = naturalHeight * cropHeight;
  const cropCenterX = naturalWidth * (cropX + cropWidth / 2);
  const cropCenterY = naturalHeight * (cropY + cropHeight / 2);

  // The crop editor stores a square selection. On non-square cards we keep
  // that selection centered and fully visible along the shorter side, while
  // allowing extra image context along the longer side.
  const targetSize = Math.min(frameWidth, frameHeight);
  const cropScale = targetSize / Math.max(cropPixelWidth, cropPixelHeight);
  const coverScale = Math.max(frameWidth / naturalWidth, frameHeight / naturalHeight);
  const scale = Math.max(cropScale, coverScale);

  const renderedWidth = naturalWidth * scale;
  const renderedHeight = naturalHeight * scale;

  let left = frameWidth / 2 - cropCenterX * scale;
  let top = frameHeight / 2 - cropCenterY * scale;

  left = Math.min(0, Math.max(frameWidth - renderedWidth, left));
  top = Math.min(0, Math.max(frameHeight - renderedHeight, top));

  image.classList.remove("is-cover");
  image.style.setProperty("width", `${renderedWidth}px`, "important");
  image.style.setProperty("height", `${renderedHeight}px`, "important");
  image.style.setProperty("left", `${left}px`, "important");
  image.style.setProperty("top", `${top}px`, "important");
  image.style.setProperty("object-fit", "initial", "important");
}

function initResponsivePetAvatarCrops(root = document) {
  root.querySelectorAll("[data-pet-avatar-crop]").forEach((image) => {
    if (image.dataset.petAvatarCropBound === "true") {
      applyResponsiveCrop(image);
      return;
    }

    image.dataset.petAvatarCropBound = "true";

    const apply = () => applyResponsiveCrop(image);
    if (image.complete) apply();
    image.addEventListener("load", apply);

    const frame = image.closest(".pj-pet-avatar-frame");
    if (frame && window.ResizeObserver) {
      const observer = new ResizeObserver(apply);
      observer.observe(frame);
      image._petAvatarCropObserver = observer;
    } else {
      window.addEventListener("resize", apply);
    }
  });
}

function installLightboxBlankAreaClose() {
  if (document.documentElement.dataset.petLightboxBlankClose === "true") return;
  document.documentElement.dataset.petLightboxBlankClose = "true";

  document.addEventListener("click", (event) => {
    const lightbox = event.target.closest?.("[data-pet-lightbox]");
    if (!lightbox || lightbox.hidden) return;

    const stage = lightbox.querySelector("[data-pet-lightbox-stage]");
    const dialog = lightbox.querySelector(".pj-pet-lightbox__dialog");

    const clickedBlankArea = event.target === lightbox || event.target === dialog || event.target === stage;
    if (!clickedBlankArea) return;

    lightbox.querySelector("[data-pet-lightbox-close]")?.click();
  });
}

function initPetAvatarCropEnhancements(root = document) {
  initResponsivePetAvatarCrops(root);
  installLightboxBlankAreaClose();
}

document.addEventListener("DOMContentLoaded", () => initPetAvatarCropEnhancements());
document.addEventListener("turbo:load", () => initPetAvatarCropEnhancements());
document.addEventListener("turbo:render", () => initPetAvatarCropEnhancements());
