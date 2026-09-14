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
  if (!avatar || !trigger || avatar.dataset.petProfileZoomBound === "true") return;

  avatar.dataset.petProfileZoomBound = "true";
  avatar.classList.add("pj-pet-profile-avatar--zoomable");
  avatar.setAttribute("role", "button");
  avatar.setAttribute("tabindex", "0");
  avatar.setAttribute("aria-label", "Открыть полное фото питомца");
  avatar.setAttribute("title", "Открыть фото");

  if (!avatar.querySelector(".pj-photo-zoom-overlay")) {
    avatar.appendChild(magnifierOverlay());
  }

  const open = () => trigger.click();

  avatar.addEventListener("click", open);
  avatar.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    open();
  });
}

document.addEventListener("DOMContentLoaded", () => initPetProfilePhotoZoom());
document.addEventListener("turbo:load", () => initPetProfilePhotoZoom());
document.addEventListener("turbo:render", () => initPetProfilePhotoZoom());
