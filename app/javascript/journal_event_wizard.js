function initJournalEventWizard() {
  document.querySelectorAll("[data-journal-wizard]").forEach((form) => {
    if (form.dataset.journalWizardBound === "true") return;
    form.dataset.journalWizardBound = "true";

    const steps = [...form.querySelectorAll("[data-journal-wizard-step]")];
    const navButtons = [...form.querySelectorAll("[data-journal-wizard-nav]")];
    const typeInputs = [...form.querySelectorAll("[data-journal-wizard-type]")];
    const message = form.querySelector("[data-journal-wizard-message]");

    let currentStep = Number.parseInt(form.dataset.initialStep || "1", 10);
    let maxReached = currentStep;

    const sectionFor = (step) => steps.find((section) => Number(section.dataset.journalWizardStep) === step);

    const hasSelectedType = () => typeInputs.some((input) => input.checked);

    const validateStep = (step) => {
      if (step === 1 && !hasSelectedType()) {
        if (message) message.hidden = false;
        typeInputs[0]?.focus();
        return false;
      }

      const section = sectionFor(step);
      if (!section) return true;

      const invalid = [...section.querySelectorAll("input, select, textarea")]
        .find((input) => !input.disabled && !input.checkValidity());

      if (invalid) {
        invalid.reportValidity();
        return false;
      }

      return true;
    };

    const render = () => {
      steps.forEach((section) => {
        const step = Number(section.dataset.journalWizardStep);
        section.hidden = step !== currentStep;
      });

      navButtons.forEach((button) => {
        const step = Number(button.dataset.journalWizardNav);
        const active = step === currentStep;
        button.classList.toggle("active", active);
        button.classList.toggle("is-complete", step < currentStep || step < maxReached);
        button.disabled = step > maxReached;
        button.toggleAttribute("aria-current", active);
        if (active) button.setAttribute("aria-current", "step");
      });

      const stepOneNext = sectionFor(1)?.querySelector("[data-journal-wizard-next]");
      if (stepOneNext) stepOneNext.disabled = !hasSelectedType();

      if (message && hasSelectedType()) message.hidden = true;

      form.dataset.currentStep = String(currentStep);

      const activeSection = sectionFor(currentStep);
      activeSection?.querySelector("h1")?.focus({ preventScroll: true });
      activeSection?.scrollIntoView({ behavior: "smooth", block: "start" });
    };

    const goTo = (step, { validate = false } = {}) => {
      if (step < 1 || step > 3) return;
      if (validate && !validateStep(currentStep)) return;
      if (step > maxReached + 1) return;

      currentStep = step;
      maxReached = Math.max(maxReached, step);
      render();
    };

    form.querySelectorAll("[data-journal-wizard-next]").forEach((button) => {
      button.addEventListener("click", () => goTo(currentStep + 1, { validate: true }));
    });

    form.querySelectorAll("[data-journal-wizard-back]").forEach((button) => {
      button.addEventListener("click", () => goTo(currentStep - 1));
    });

    navButtons.forEach((button) => {
      button.addEventListener("click", () => {
        const target = Number(button.dataset.journalWizardNav);
        if (target <= maxReached) goTo(target);
      });
    });

    typeInputs.forEach((input) => {
      input.addEventListener("change", () => {
        if (message) message.hidden = true;
        const stepOneNext = sectionFor(1)?.querySelector("[data-journal-wizard-next]");
        if (stepOneNext) stepOneNext.disabled = false;
      });
    });

    render();
  });
}

document.addEventListener("DOMContentLoaded", initJournalEventWizard);
document.addEventListener("turbo:load", initJournalEventWizard);
document.addEventListener("turbo:render", initJournalEventWizard);
