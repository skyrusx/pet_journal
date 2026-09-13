function sidebarPreference() {
  try {
    return window.localStorage.getItem("petjournal.dashboard.sidebarCollapsed");
  } catch (_error) {
    return null;
  }
}

function saveSidebarPreference(collapsed) {
  try {
    window.localStorage.setItem("petjournal.dashboard.sidebarCollapsed", String(collapsed));
  } catch (_error) {
    // The shell still works when storage is unavailable.
  }
}

function closeProfileMenus(except = null) {
  document.querySelectorAll("[data-dashboard-profile-menu][open]").forEach((menu) => {
    if (menu !== except) menu.removeAttribute("open");
  });
}

function closeMobileSheets() {
  document.querySelectorAll("[data-dashboard-sheet].is-open").forEach((sheet) => {
    sheet.classList.remove("is-open");
    sheet.setAttribute("aria-hidden", "true");
  });

  document.querySelectorAll("[data-dashboard-sheet-toggle]").forEach((button) => {
    button.setAttribute("aria-expanded", "false");
  });

  const backdrop = document.querySelector("[data-dashboard-sheet-backdrop]");
  if (backdrop) backdrop.hidden = true;
  document.body.classList.remove("pj-dashboard-sheet-open");
}

function openMobileSheet(name, button) {
  const sheet = document.querySelector(`[data-dashboard-sheet="${name}"]`);
  if (!sheet) return;

  const alreadyOpen = sheet.classList.contains("is-open");
  closeMobileSheets();
  if (alreadyOpen) return;

  sheet.classList.add("is-open");
  sheet.setAttribute("aria-hidden", "false");
  button?.setAttribute("aria-expanded", "true");

  const backdrop = document.querySelector("[data-dashboard-sheet-backdrop]");
  if (backdrop) backdrop.hidden = false;
  document.body.classList.add("pj-dashboard-sheet-open");

  window.setTimeout(() => {
    sheet.querySelector("a, button")?.focus();
  }, 40);
}

function initMobileSheets() {
  document.querySelectorAll("[data-dashboard-sheet-toggle]").forEach((button) => {
    if (button.dataset.dashboardSheetBound === "true") return;
    button.dataset.dashboardSheetBound = "true";

    button.addEventListener("click", () => {
      openMobileSheet(button.dataset.dashboardSheetToggle, button);
    });
  });

  document.querySelectorAll("[data-dashboard-sheet-close]").forEach((button) => {
    if (button.dataset.dashboardSheetCloseBound === "true") return;
    button.dataset.dashboardSheetCloseBound = "true";
    button.addEventListener("click", closeMobileSheets);
  });

  document.querySelectorAll("[data-dashboard-sheet-backdrop]").forEach((backdrop) => {
    if (backdrop.dataset.dashboardSheetBackdropBound === "true") return;
    backdrop.dataset.dashboardSheetBackdropBound = "true";
    backdrop.addEventListener("click", closeMobileSheets);
  });

  document.querySelectorAll("[data-dashboard-sheet] a").forEach((link) => {
    if (link.dataset.dashboardSheetLinkBound === "true") return;
    link.dataset.dashboardSheetLinkBound = "true";
    link.addEventListener("click", closeMobileSheets);
  });
}

function initSidebar() {
  document.querySelectorAll("[data-dashboard-root]").forEach((root) => {
    const button = root.querySelector("[data-dashboard-sidebar-toggle]");
    if (!button || button.dataset.dashboardSidebarBound === "true") return;

    button.dataset.dashboardSidebarBound = "true";

    const storedPreference = sidebarPreference();
    const defaultCollapsed = window.matchMedia("(min-width: 821px) and (max-width: 1100px)").matches;
    let collapsed = storedPreference === null ? defaultCollapsed : storedPreference === "true";

    const render = () => {
      root.classList.toggle("is-sidebar-collapsed", collapsed);
      button.setAttribute("aria-expanded", String(!collapsed));
      button.setAttribute("aria-label", collapsed ? "Развернуть боковое меню" : "Свернуть боковое меню");
      button.title = collapsed ? "Развернуть меню" : "Свернуть меню";
    };

    button.addEventListener("click", () => {
      closeProfileMenus();
      collapsed = !collapsed;
      saveSidebarPreference(collapsed);
      render();
    });

    root.querySelectorAll("[data-dashboard-profile-menu]").forEach((menu) => {
      menu.addEventListener("toggle", () => {
        if (menu.open) closeProfileMenus(menu);
      });
    });

    render();
  });
}

function initAuthenticatedShell() {
  initSidebar();
  initMobileSheets();
}

document.addEventListener("click", (event) => {
  if (event.target.closest?.("[data-dashboard-sheet-close]")) {
    closeMobileSheets();
  }

  document.querySelectorAll("[data-dashboard-profile-menu][open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.removeAttribute("open");
  });
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return;

  const openMenu = document.querySelector("[data-dashboard-profile-menu][open]");
  if (openMenu) {
    openMenu.removeAttribute("open");
    openMenu.querySelector("summary")?.focus();
  }

  closeMobileSheets();
});

document.addEventListener("DOMContentLoaded", initAuthenticatedShell);
document.addEventListener("turbo:load", initAuthenticatedShell);
document.addEventListener("turbo:render", initAuthenticatedShell);
document.addEventListener("turbo:before-cache", closeMobileSheets);
