function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function initPetCropZoomSteps(root = document) {
  root.querySelectorAll?.(".pj-pet-crop-zoom").forEach((control) => {
    if (control.dataset.petCropZoomStepsBound === "true") return;

    const input = control.querySelector("[data-pet-crop-zoom]");
    const steps = control.querySelectorAll(":scope > span");
    const decrease = steps[0];
    const increase = steps[steps.length - 1];
    if (!input || !decrease || !increase) return;

    control.dataset.petCropZoomStepsBound = "true";

    const min = Number(input.min || 1);
    const max = Number(input.max || 4);
    const clickStep = 0.15;

    const prepareButton = (element, label) => {
      element.setAttribute("role", "button");
      element.setAttribute("tabindex", "0");
      element.setAttribute("aria-label", label);
      element.style.cursor = "pointer";
      element.style.userSelect = "none";
      element.style.display = "grid";
      element.style.placeItems = "center";
      element.style.width = "22px";
      element.style.height = "22px";
      element.style.borderRadius = "50%";
      element.style.transition = "background 150ms ease, opacity 150ms ease";
    };

    prepareButton(decrease, "Уменьшить фото");
    prepareButton(increase, "Увеличить фото");

    const updateState = () => {
      const value = Number(input.value);
      const setState = (element, disabled) => {
        element.setAttribute("aria-disabled", String(disabled));
        element.style.opacity = disabled ? "0.35" : "1";
        element.style.cursor = disabled ? "default" : "pointer";
      };

      setState(decrease, value <= min + 0.0001);
      setState(increase, value >= max - 0.0001);
    };

    const changeZoom = (direction) => {
      const current = Number(input.value);
      const next = clamp(current + direction * clickStep, min, max);
      if (Math.abs(next - current) < 0.0001) return;

      input.value = next.toFixed(2);
      input.dispatchEvent(new Event("input", { bubbles: true }));
      updateState();
    };

    const bindStep = (element, direction) => {
      element.addEventListener("click", () => changeZoom(direction));
      element.addEventListener("keydown", (event) => {
        if (event.key !== "Enter" && event.key !== " ") return;

        event.preventDefault();
        changeZoom(direction);
      });
      element.addEventListener("mouseenter", () => {
        if (element.getAttribute("aria-disabled") !== "true") {
          element.style.background = "rgba(111, 159, 73, .12)";
        }
      });
      element.addEventListener("mouseleave", () => {
        element.style.background = "transparent";
      });
    };

    bindStep(decrease, -1);
    bindStep(increase, 1);
    input.addEventListener("input", updateState);
    updateState();
  });
}

document.addEventListener("DOMContentLoaded", () => initPetCropZoomSteps());
document.addEventListener("turbo:load", () => initPetCropZoomSteps());
document.addEventListener("turbo:render", () => initPetCropZoomSteps());
