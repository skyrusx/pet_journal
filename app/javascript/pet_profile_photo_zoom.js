function magnifierOverlay() {
  const overlay = document.createElement("span");
  overlay.className = "pj-photo-zoom-overlay";
  overlay.setAttribute("aria-hidden", "true");
  overlay.innerHTML = `
    <svg viewBox="0 0 24 24">
      <circle cx="10.5" cy="10.5" r="5.5"></circle>
      <path d="m15 15 4.5 4.5"></path>
    </svg>
  `;
  return overlay;
}

function initPetProfilePhotoZoom(root = document) {
  const page = root.querySelector?.(".pj-pet-profile-page") || document.querySelector(".pj-pet-profile-page");
  if (!page) return;

  const avatar = page.querySelector(".pj-pet-profile-avatar");
  const trigger = page.querySelector("[data-pet-profile-lightbox-trigger]");
  const modal = page.querySelector("[data-pet-profile-lightbox]");
  const image = modal?.querySelector("[data-pet-profile-lightbox-image]");
  const closeButtons = modal ? [...modal.querySelectorAll("[data-pet-profile-lightbox-close]")] : [];

  if (!avatar || !trigger || !modal || !image || avatar.dataset.petProfileZoomBound === "true") return;

  avatar.dataset.petProfileZoomBound = "true";
  avatar.classList.add("pj-pet-profile-avatar--zoomable");
  avatar.setAttribute("role", "button");
  avatar.setAttribute("tabindex", "0");
  avatar.setAttribute("aria-label", "Открыть полное фото питомца");
  avatar.setAttribute("title", "Открыть фото");

  if (!avatar.querySelector(".pj-photo-zoom-overlay")) {
    avatar.appendChild(magnifierOverlay());
  }

  const open = () => {
    image.src = trigger.dataset.src;
    image.alt = trigger.dataset.alt || "Фото питомца";
    modal.hidden = false;
    modal.setAttribute("aria-hidden", "false");
    document.body.classList.add("pj-modal-open");
    window.setTimeout(() => closeButtons[0]?.focus(), 0);
  };

  const close = () => {
    modal.hidden = true;
    modal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("pj-modal-open");
    image.removeAttribute("src");
    avatar.focus();
  };

  avatar.addEventListener("click", open);
  avatar.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    open();
  });

  closeButtons.forEach((button) => button.addEventListener("click", close));
  modal.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
  });
}

document.addEventListener("DOMContentLoaded", () => initPetProfilePhotoZoom());
document.addEventListener("turbo:load", () => initPetProfilePhotoZoom());
document.addEventListener("turbo:render", () => initPetProfilePhotoZoom());
