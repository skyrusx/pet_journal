const SERVICE_WORKER_URL = "/service-worker";
const INSTALL_DISMISS_KEY = "petjournal:pwa-install-dismissed-at";
const INSTALL_DISMISS_TTL = 7 * 24 * 60 * 60 * 1000;
const UPDATE_CHECK_INTERVAL = 60 * 60 * 1000;

let deferredInstallPrompt = null;
let registration = null;
let reloadAfterUpdate = false;
let lastUpdateCheckAt = 0;
let installTimer = null;

function standalone() {
  return window.matchMedia?.("(display-mode: standalone)").matches || window.navigator.standalone === true;
}

function ios() {
  const ua = navigator.userAgent || "";
  return /iPhone|iPad|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
}

function installAutopromptEnabled() {
  return document.body?.dataset.pwaInstallAutoprompt === "true";
}

function readDismissedAt() {
  try {
    return Number(localStorage.getItem(INSTALL_DISMISS_KEY)) || 0;
  } catch (_error) {
    return 0;
  }
}

function saveDismissedAt() {
  try {
    localStorage.setItem(INSTALL_DISMISS_KEY, String(Date.now()));
  } catch (_error) {
    // Storage can be unavailable in strict privacy modes.
  }
}

function recentlyDismissed() {
  const dismissedAt = readDismissedAt();
  return dismissedAt > 0 && Date.now() - dismissedAt < INSTALL_DISMISS_TTL;
}

function makeButton(label, className, handler, ariaLabel = null) {
  const element = document.createElement("button");
  element.type = "button";
  element.className = className;
  element.textContent = label;
  if (ariaLabel) element.setAttribute("aria-label", ariaLabel);
  element.addEventListener("click", handler);
  return element;
}

function removeOffer(kind) {
  document.querySelector(`[data-pwa-offer="${kind}"]`)?.remove();
}

function createOffer({ kind, eyebrow, title, text, primaryLabel, primaryAction, secondaryLabel = "Не сейчас", secondaryAction }) {
  if (document.querySelector(`[data-pwa-offer="${kind}"]`)) return;

  const card = document.createElement("aside");
  card.className = `pwa-offer pwa-offer--${kind}`;
  card.dataset.pwaOffer = kind;
  card.setAttribute("role", "region");
  card.setAttribute("aria-label", title);

  const mark = document.createElement("div");
  mark.className = "pwa-offer__mark";
  mark.textContent = "🐾";
  mark.setAttribute("aria-hidden", "true");

  const content = document.createElement("div");
  content.className = "pwa-offer__content";

  const small = document.createElement("span");
  small.className = "pwa-offer__eyebrow";
  small.textContent = eyebrow;

  const heading = document.createElement("strong");
  heading.className = "pwa-offer__title";
  heading.textContent = title;

  const copy = document.createElement("p");
  copy.className = "pwa-offer__text";
  copy.textContent = text;

  const actions = document.createElement("div");
  actions.className = "pwa-offer__actions";
  actions.append(
    makeButton(primaryLabel, "pwa-offer__button pwa-offer__button--primary", primaryAction),
    makeButton(secondaryLabel, "pwa-offer__button pwa-offer__button--secondary", secondaryAction)
  );

  const close = makeButton("", "pwa-offer__close", secondaryAction, "Закрыть");

  content.append(small, heading, copy, actions);
  card.append(mark, content, close);
  document.body.append(card);
  requestAnimationFrame(() => card.classList.add("is-visible"));
}

function dismissInstallOffer() {
  saveDismissedAt();
  removeOffer("install");
  refreshInstallButtons();
}

async function runBrowserInstall() {
  if (!deferredInstallPrompt) return;

  const promptEvent = deferredInstallPrompt;
  deferredInstallPrompt = null;
  removeOffer("install");

  try {
    await promptEvent.prompt();
    const choice = await promptEvent.userChoice;
    if (choice?.outcome !== "accepted") saveDismissedAt();
  } catch (_error) {
    saveDismissedAt();
  }

  refreshInstallButtons();
}

function closeIosGuide() {
  const guide = document.querySelector("[data-pwa-ios-guide]");
  if (!guide) return;
  guide.classList.remove("is-visible");
  window.setTimeout(() => guide.remove(), 180);
}

function showIosGuide() {
  removeOffer("install");
  if (document.querySelector("[data-pwa-ios-guide]")) return;

  const overlay = document.createElement("div");
  overlay.className = "pwa-guide";
  overlay.dataset.pwaIosGuide = "true";
  overlay.setAttribute("role", "dialog");
  overlay.setAttribute("aria-modal", "true");
  overlay.setAttribute("aria-label", "Как установить PetJournal");

  const panel = document.createElement("div");
  panel.className = "pwa-guide__panel";

  const label = document.createElement("span");
  label.className = "pwa-guide__eyebrow";
  label.textContent = "Установка PetJournal";

  const title = document.createElement("h2");
  title.textContent = "Два шага — и готово";

  const copy = document.createElement("p");
  copy.textContent = "PetJournal появится среди приложений и будет открываться отдельно от браузера.";

  const steps = document.createElement("ol");
  steps.className = "pwa-guide__steps";

  const stepOne = document.createElement("li");
  stepOne.textContent = "1. Откройте меню «Поделиться» в браузере.";
  const stepTwo = document.createElement("li");
  stepTwo.textContent = "2. Выберите «На экран “Домой”», затем «Добавить».";
  steps.append(stepOne, stepTwo);

  const done = makeButton("Понятно", "pwa-guide__button", () => {
    saveDismissedAt();
    closeIosGuide();
    refreshInstallButtons();
  });
  const close = makeButton("", "pwa-guide__close", closeIosGuide, "Закрыть");

  panel.append(label, title, copy, steps, done, close);
  overlay.append(panel);
  overlay.addEventListener("click", (event) => {
    if (event.target === overlay) closeIosGuide();
  });
  overlay.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeIosGuide();
  });

  document.body.append(overlay);
  requestAnimationFrame(() => {
    overlay.classList.add("is-visible");
    done.focus();
  });
}

function showInstallOffer() {
  if (!installAutopromptEnabled() || standalone() || recentlyDismissed()) return;

  if (deferredInstallPrompt) {
    createOffer({
      kind: "install",
      eyebrow: "PetJournal на устройстве",
      title: "Всегда рядом",
      text: "Установите PetJournal как приложение — без адресной строки и с быстрым запуском с главного экрана.",
      primaryLabel: "Установить",
      primaryAction: runBrowserInstall,
      secondaryAction: dismissInstallOffer
    });
  } else if (ios()) {
    createOffer({
      kind: "install",
      eyebrow: "PetJournal на iPhone",
      title: "Добавьте на экран «Домой»",
      text: "Покажем короткую инструкцию для установки приложения.",
      primaryLabel: "Как установить",
      primaryAction: showIosGuide,
      secondaryAction: dismissInstallOffer
    });
  }
}

function scheduleInstallOffer(delay = 7000) {
  if (!installAutopromptEnabled() || standalone() || recentlyDismissed() || installTimer) return;
  installTimer = window.setTimeout(() => {
    installTimer = null;
    showInstallOffer();
  }, delay);
}

function showUpdateOffer(currentRegistration = registration) {
  if (!currentRegistration?.waiting || !navigator.serviceWorker.controller) return;

  removeOffer("install");
  createOffer({
    kind: "update",
    eyebrow: "Новая версия PetJournal",
    title: "Обновление готово",
    text: "Обновитесь одним нажатием — без очистки кэша и ручного перезапуска.",
    primaryLabel: "Обновить",
    primaryAction: () => {
      reloadAfterUpdate = true;
      currentRegistration.waiting?.postMessage({ type: "SKIP_WAITING" });
    },
    secondaryLabel: "Позже",
    secondaryAction: () => removeOffer("update")
  });
}

function watchRegistration(currentRegistration) {
  if (currentRegistration.waiting) showUpdateOffer(currentRegistration);

  currentRegistration.addEventListener("updatefound", () => {
    const worker = currentRegistration.installing;
    if (!worker) return;

    worker.addEventListener("statechange", () => {
      if (worker.state === "installed" && navigator.serviceWorker.controller) {
        showUpdateOffer(currentRegistration);
      }
    });
  });
}

async function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return;

  try {
    registration = await navigator.serviceWorker.register(SERVICE_WORKER_URL, {
      scope: "/",
      updateViaCache: "none"
    });
    lastUpdateCheckAt = Date.now();
    watchRegistration(registration);
  } catch (error) {
    console.warn("PetJournal PWA registration failed", error);
  }
}

async function checkForUpdate() {
  if (!registration || Date.now() - lastUpdateCheckAt < UPDATE_CHECK_INTERVAL) return;
  lastUpdateCheckAt = Date.now();

  try {
    await registration.update();
  } catch (_error) {
    // Being offline is a normal state for a PWA.
  }
}

function showConnectionToast(online) {
  document.querySelector("[data-pwa-connection]")?.remove();
  const toast = document.createElement("div");
  toast.className = `pwa-connection ${online ? "is-online" : "is-offline"}`;
  toast.dataset.pwaConnection = "true";
  toast.setAttribute("role", "status");
  toast.textContent = online ? "Связь восстановлена" : "Нет подключения к интернету";
  document.body.append(toast);
  requestAnimationFrame(() => toast.classList.add("is-visible"));
  window.setTimeout(() => toast.remove(), online ? 2400 : 3800);
}

function setNetworkState(announce = false) {
  const online = navigator.onLine;
  document.documentElement.classList.toggle("pwa-offline", !online);
  if (announce) showConnectionToast(online);
}

function refreshInstallButtons() {
  document.querySelectorAll("[data-pwa-install-button]").forEach((buttonElement) => {
    buttonElement.hidden = standalone() || (!deferredInstallPrompt && !ios());
  });
}

function bindInstallButtons() {
  document.querySelectorAll("[data-pwa-install-button]").forEach((buttonElement) => {
    if (buttonElement.dataset.pwaBound === "true") return;
    buttonElement.dataset.pwaBound = "true";
    buttonElement.addEventListener("click", () => {
      if (deferredInstallPrompt) runBrowserInstall();
      else if (ios()) showIosGuide();
    });
  });
  refreshInstallButtons();
}

function initPage() {
  bindInstallButtons();
  setNetworkState();

  if (installAutopromptEnabled() && (deferredInstallPrompt || ios())) {
    scheduleInstallOffer(5000);
  }
}

window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault();
  deferredInstallPrompt = event;
  refreshInstallButtons();
  scheduleInstallOffer();
});

window.addEventListener("appinstalled", () => {
  deferredInstallPrompt = null;
  removeOffer("install");
  saveDismissedAt();
  refreshInstallButtons();
});

window.addEventListener("online", () => setNetworkState(true));
window.addEventListener("offline", () => setNetworkState(true));

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (!reloadAfterUpdate) return;
    reloadAfterUpdate = false;
    window.location.reload();
  });
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") checkForUpdate();
});

document.addEventListener("DOMContentLoaded", initPage);
document.addEventListener("turbo:load", initPage);

window.addEventListener("load", () => {
  registerServiceWorker();
  if (installAutopromptEnabled() && ios() && !standalone()) scheduleInstallOffer(9000);
}, { once: true });
