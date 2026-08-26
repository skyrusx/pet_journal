const SERVICE_WORKER_URL = "/service-worker";

export function initPwa() {
  if (!("serviceWorker" in navigator)) return;

  navigator.serviceWorker.register(SERVICE_WORKER_URL, {
    scope: "/",
    updateViaCache: "none"
  }).catch((error) => {
    console.warn("PetJournal PWA registration failed", error);
  });
}

document.addEventListener("DOMContentLoaded", initPwa, { once: true });
