// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

function base64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; i += 1) {
    outputArray[i] = rawData.charCodeAt(i);
  }

  return outputArray;
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
}

function bindOnce(element, key) {
  const attr = `data-pj-bound-${key}`;
  if (element.hasAttribute(attr)) return false;

  element.setAttribute(attr, "true");
  return true;
}

function setMobileMenu(panel, open) {
  if (!panel) return;

  const root = panel.closest("[data-mobile-menu-root]") || document;
  const backdrop = root.querySelector("[data-mobile-menu-backdrop]");
  const controls = document.querySelectorAll(`[aria-controls="${panel.id}"]`);

  panel.hidden = !open;
  panel.setAttribute("aria-hidden", String(!open));
  backdrop?.toggleAttribute("hidden", !open);
  document.body.classList.toggle("mobile-menu-open", open);

  controls.forEach((control) => {
    control.setAttribute("aria-expanded", String(open));
  });

  if (open) {
    window.setTimeout(() => panel.querySelector("a, button")?.focus(), 0);
  }
}

function sheetFocusable(panel) {
  return [...panel.querySelectorAll("a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled])")]
    .filter((item) => item.offsetParent !== null);
}

function setMobileSheet(panel, open, control = null) {
  if (!panel) return;

  const root = panel.closest("[data-mobile-sheet-root]") || document;
  const backdrop = root.querySelector("[data-mobile-sheet-backdrop]");
  const controls = document.querySelectorAll(`[aria-controls="${panel.id}"]`);

  if (open) {
    closeAllMobileSheets();
    panel.dataset.returnFocus = control ? control.getAttribute("data-mobile-sheet-control-id") || "" : "";
    if (control && !panel.dataset.returnFocus) {
      const controlId = `mobile-sheet-control-${Math.random().toString(36).slice(2)}`;
      control.setAttribute("data-mobile-sheet-control-id", controlId);
      panel.dataset.returnFocus = controlId;
    }
  }

  panel.hidden = !open;
  panel.setAttribute("aria-hidden", String(!open));
  backdrop?.toggleAttribute("hidden", !open);
  document.body.classList.toggle("mobile-sheet-open", open);

  controls.forEach((item) => {
    item.setAttribute("aria-expanded", String(open));
  });

  if (open) {
    window.setTimeout(() => {
      const focusable = sheetFocusable(panel);
      (focusable[0] || panel).focus();
    }, 0);
  } else {
    const returnFocus = panel.dataset.returnFocus;
    if (returnFocus) document.querySelector(`[data-mobile-sheet-control-id="${returnFocus}"]`)?.focus();
    delete panel.dataset.returnFocus;
  }
}

function closeAllMobileMenus() {
  document.querySelectorAll("[data-mobile-menu-panel]").forEach((panel) => {
    setMobileMenu(panel, false);
  });
}

function closeAllMobileSheets({ restoreFocus = true } = {}) {
  document.querySelectorAll("[data-mobile-sheet]").forEach((panel) => {
    if (!restoreFocus) delete panel.dataset.returnFocus;
    setMobileSheet(panel, false);
  });
}

function closeAllOverlays({ restoreFocus = true } = {}) {
  closeAllMobileMenus();
  closeAllMobileSheets({ restoreFocus });
}

function initPetJournal(root = document) {
  root.querySelectorAll("[data-mobile-menu-open]").forEach((button) => {
    if (!bindOnce(button, "mobile-menu-open")) return;

    button.addEventListener("click", () => {
      const panel = document.getElementById(button.getAttribute("aria-controls"));
      const isOpen = panel?.getAttribute("aria-hidden") === "false";

      closeAllMobileMenus();
      setMobileMenu(panel, !isOpen);
    });
  });

  root.querySelectorAll("[data-mobile-menu-close], [data-mobile-menu-backdrop], [data-mobile-menu-link]").forEach((element) => {
    if (!bindOnce(element, "mobile-menu-close")) return;

    element.addEventListener("click", closeAllMobileMenus);
  });

  root.querySelectorAll("[data-mobile-menu-panel]").forEach((panel) => {
    if (!bindOnce(panel, "mobile-menu-keydown")) return;

    panel.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        const control = document.querySelector(`[aria-controls="${panel.id}"]`);
        closeAllMobileMenus();
        control?.focus();
        return;
      }

      if (event.key !== "Tab") return;

      const focusable = [...panel.querySelectorAll("a[href], button:not([disabled])")].filter((item) => item.offsetParent !== null);
      if (focusable.length === 0) return;

      const first = focusable[0];
      const last = focusable[focusable.length - 1];

      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    });
  });

  root.querySelectorAll("[data-mobile-sheet-open]").forEach((button) => {
    if (!bindOnce(button, "mobile-sheet-open")) return;

    button.addEventListener("click", () => {
      const panel = document.getElementById(button.getAttribute("aria-controls"));
      const isOpen = panel?.getAttribute("aria-hidden") === "false";

      setMobileSheet(panel, !isOpen, button);
    });
  });

  root.querySelectorAll("[data-mobile-sheet-close], [data-mobile-sheet-backdrop], [data-mobile-sheet-link]").forEach((element) => {
    if (!bindOnce(element, "mobile-sheet-close")) return;

    element.addEventListener("click", () => closeAllMobileSheets({ restoreFocus: false }));
  });

  root.querySelectorAll("[data-mobile-sheet]").forEach((panel) => {
    if (!bindOnce(panel, "mobile-sheet-keydown")) return;

    panel.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        event.preventDefault();
        setMobileSheet(panel, false);
        return;
      }

      if (event.key !== "Tab") return;

      const focusable = sheetFocusable(panel);
      if (focusable.length === 0) return;

      const first = focusable[0];
      const last = focusable[focusable.length - 1];

      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    });
  });

  root.querySelectorAll(".app-user-menu").forEach((menu) => {
    if (!bindOnce(menu, "user-menu")) return;

    menu.addEventListener("keydown", (event) => {
      if (event.key !== "Escape") return;

      menu.removeAttribute("open");
      menu.querySelector("summary")?.focus();
    });
  });

  root.querySelectorAll("[data-flash-toast]").forEach((toast) => {
    if (!bindOnce(toast, "flash-toast")) return;

    const close = toast.querySelector("[data-flash-close]");
    const dismiss = () => {
      toast.classList.add("closing");
      window.setTimeout(() => toast.remove(), 180);
    };

    close?.addEventListener("click", dismiss);
    window.setTimeout(dismiss, 5200);
  });

  root.querySelectorAll("[data-password-toggle]").forEach((button) => {
    if (!bindOnce(button, "password-toggle")) return;

    button.addEventListener("click", () => {
      const field = button.closest(".auth-password-field");
      const input = field?.querySelector("[data-password-input]");
      if (!input) return;

      const shouldShow = input.type === "password";
      input.type = shouldShow ? "text" : "password";
      button.classList.toggle("is-visible", shouldShow);
      button.setAttribute("aria-label", shouldShow ? "Скрыть пароль" : "Показать пароль");
    });
  });

  root.querySelectorAll("[data-reminder-preset]").forEach((button) => {
    if (!bindOnce(button, "reminder-preset")) return;

    button.addEventListener("click", () => {
      const input = document.querySelector("[data-reminder-datetime]");
      if (input) input.value = button.dataset.reminderPreset;
    });
  });

  root.querySelectorAll("[data-copy-url]").forEach((button) => {
    if (!bindOnce(button, "copy-url")) return;

    button.addEventListener("click", async () => {
      const originalText = button.textContent;

      try {
        await navigator.clipboard.writeText(button.dataset.copyUrl);
        button.textContent = "Скопировано";
      } catch (_error) {
        button.textContent = "Скопируйте вручную";
      }

      window.setTimeout(() => {
        button.textContent = originalText;
      }, 1800);
    });
  });

  root.querySelectorAll("[data-repeat-rule]").forEach((select) => {
    if (!bindOnce(select, "repeat-rule")) return;

    const form = select.closest("form");
    const customFields = form ? form.querySelectorAll("[data-custom-repeat]") : [];
    const updateCustomFields = () => {
      customFields.forEach((field) => {
        field.hidden = select.value !== "custom";
      });
    };

    select.addEventListener("change", updateCustomFields);
    updateCustomFields();
  });

  root.querySelectorAll("[data-event-type-radio]").forEach((radio) => {
    if (!bindOnce(radio, "event-type-radio")) return;

    const form = radio.closest("form");
    if (!form) return;

    const sections = form.querySelectorAll("[data-event-fields]");
    const updateEventFields = () => {
      const selected = form.querySelector("[data-event-type-radio]:checked")?.value;

      sections.forEach((section) => {
        const active = section.dataset.eventFields === selected;
        section.hidden = !active;
        section.querySelectorAll("input, select, textarea").forEach((input) => {
          input.disabled = !active;
        });
      });
    };

    radio.addEventListener("change", updateEventFields);
    updateEventFields();
  });

  root.querySelectorAll("[data-web-push-panel]").forEach((panel) => {
    if (!bindOnce(panel, "web-push-panel")) return;

    const enableButton = panel.querySelector("[data-web-push-enable]");
    const disableButton = panel.querySelector("[data-web-push-disable]");
    const status = panel.querySelector("[data-web-push-status]");
    const vapidPublicKey = panel.dataset.vapidPublicKey;

    if (!enableButton || !status || !vapidPublicKey) return;

    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      enableButton.disabled = true;
      if (disableButton) disableButton.disabled = true;
      status.textContent = "Этот браузер не поддерживает push-уведомления.";
      return;
    }

    enableButton.addEventListener("click", async () => {
      enableButton.disabled = true;
      status.textContent = "Запрашиваем разрешение...";

      try {
        const permission = await Notification.requestPermission();

        if (permission !== "granted") {
          status.textContent = "Разрешение на уведомления не выдано.";
          enableButton.disabled = false;
          return;
        }

        const registration = await navigator.serviceWorker.register("/service-worker");
        const subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: base64ToUint8Array(vapidPublicKey)
        });

        const response = await fetch("/web_push_subscription", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken()
          },
          body: JSON.stringify({ subscription: subscription.toJSON() })
        });
        const body = await response.json();

        if (!response.ok) throw new Error(body.message || "Не удалось сохранить подписку.");

        status.textContent = body.message;
      } catch (error) {
        status.textContent = error.message;
        enableButton.disabled = false;
      }
    });

    disableButton?.addEventListener("click", async () => {
      disableButton.disabled = true;
      status.textContent = "Отключаем push...";

      try {
        const registration = await navigator.serviceWorker.getRegistration("/service-worker");
        const subscription = await registration?.pushManager.getSubscription();

        if (!subscription) {
          status.textContent = "В этом браузере нет активной push-подписки.";
          disableButton.disabled = false;
          return;
        }

        const endpoint = subscription.endpoint;
        await subscription.unsubscribe();

        const response = await fetch("/web_push_subscription", {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken()
          },
          body: JSON.stringify({ endpoint })
        });
        const body = await response.json();

        if (!response.ok) throw new Error(body.message || "Не удалось отключить подписку.");

        status.textContent = body.message;
      } catch (error) {
        status.textContent = error.message;
      } finally {
        disableButton.disabled = false;
        enableButton.disabled = false;
      }
    });
  });
}

document.addEventListener("click", (event) => {
  document.querySelectorAll(".app-user-menu[open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.removeAttribute("open");
  });
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeAllOverlays();
});

document.addEventListener("DOMContentLoaded", () => initPetJournal());
document.addEventListener("turbo:load", () => initPetJournal());
document.addEventListener("turbo:render", () => initPetJournal());
document.addEventListener("turbo:before-cache", () => closeAllOverlays({ restoreFocus: false }));
