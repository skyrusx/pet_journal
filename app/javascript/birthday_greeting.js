function syncBirthdayStack() {
  const greeting = document.querySelector("[data-birthday-greeting]");

  if (!greeting) {
    document.body?.classList.remove("pj-has-birthday-greeting");
    document.documentElement.style.removeProperty("--pj-birthday-stack-offset");
    return;
  }

  document.body?.classList.add("pj-has-birthday-greeting");
  document.documentElement.style.setProperty(
    "--pj-birthday-stack-offset",
    `${Math.ceil(greeting.getBoundingClientRect().height) + 16}px`
  );
}

function initBirthdayGreeting() {
  const greeting = document.querySelector("[data-birthday-greeting]");

  if (!greeting) {
    syncBirthdayStack();
    return;
  }

  if (greeting.dataset.birthdayGreetingReady === "true") {
    syncBirthdayStack();
    return;
  }

  greeting.dataset.birthdayGreetingReady = "true";
  const closeButton = greeting.querySelector("[data-birthday-greeting-close]");

  closeButton?.addEventListener("click", () => {
    greeting.classList.add("is-closing");
    greeting.classList.remove("is-visible");

    window.setTimeout(() => {
      greeting.remove();
      syncBirthdayStack();
    }, 220);
  });

  requestAnimationFrame(() => {
    greeting.classList.add("is-visible");
    syncBirthdayStack();
  });
}

document.addEventListener("DOMContentLoaded", initBirthdayGreeting);
document.addEventListener("turbo:load", initBirthdayGreeting);
window.addEventListener("resize", syncBirthdayStack);
