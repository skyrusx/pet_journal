function visibleLightbox() {
  return [...document.querySelectorAll("[data-pet-lightbox]")].find((modal) => !modal.hidden);
}

function clickControl(modal, selector) {
  const control = modal.querySelector(selector);
  if (!control) return false;

  control.click();
  return true;
}

document.addEventListener("keydown", (event) => {
  const modal = visibleLightbox();
  if (!modal) return;

  if (event.key === "ArrowLeft") {
    if (clickControl(modal, "[data-pet-lightbox-prev]")) event.preventDefault();
  } else if (event.key === "ArrowRight") {
    if (clickControl(modal, "[data-pet-lightbox-next]")) event.preventDefault();
  } else if (event.key === "Escape") {
    if (clickControl(modal, "[data-pet-lightbox-close]")) event.preventDefault();
  }
});
