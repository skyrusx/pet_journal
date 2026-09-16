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

  let handled = false;

  if (event.key === "ArrowLeft") {
    handled = clickControl(modal, "[data-pet-lightbox-prev]");
  } else if (event.key === "ArrowRight") {
    handled = clickControl(modal, "[data-pet-lightbox-next]");
  } else if (event.key === "Escape") {
    handled = clickControl(modal, "[data-pet-lightbox-close]");
  }

  if (!handled) return;

  event.preventDefault();
  event.stopPropagation();
}, true);
