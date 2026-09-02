function dashboardSidebarPreference() {
  try {
    return window.localStorage.getItem("petjournal.dashboard.sidebarCollapsed");
  } catch (_error) {
    return null;
  }
}

function saveDashboardSidebarPreference(collapsed) {
  try {
    window.localStorage.setItem("petjournal.dashboard.sidebarCollapsed", String(collapsed));
  } catch (_error) {
    // The sidebar still works when storage is unavailable.
  }
}

function closeDashboardProfileMenus(except = null) {
  document.querySelectorAll("[data-dashboard-profile-menu][open]").forEach((menu) => {
    if (menu !== except) menu.removeAttribute("open");
  });
}

function closeDashboardMobileSheets() {
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

function openDashboardMobileSheet(name, button) {
  const sheet = document.querySelector(`[data-dashboard-sheet="${name}"]`);
  if (!sheet) return;

  const alreadyOpen = sheet.classList.contains("is-open");
  closeDashboardMobileSheets();
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

function initDashboardMobileSheets() {
  document.querySelectorAll("[data-dashboard-sheet-toggle]").forEach((button) => {
    if (button.dataset.dashboardSheetBound === "true") return;
    button.dataset.dashboardSheetBound = "true";

    button.addEventListener("click", () => {
      openDashboardMobileSheet(button.dataset.dashboardSheetToggle, button);
    });
  });

  document.querySelectorAll("[data-dashboard-sheet-close]").forEach((button) => {
    if (button.dataset.dashboardSheetCloseBound === "true") return;
    button.dataset.dashboardSheetCloseBound = "true";
    button.addEventListener("click", closeDashboardMobileSheets);
  });

  document.querySelectorAll("[data-dashboard-sheet-backdrop]").forEach((backdrop) => {
    if (backdrop.dataset.dashboardSheetBackdropBound === "true") return;
    backdrop.dataset.dashboardSheetBackdropBound = "true";
    backdrop.addEventListener("click", closeDashboardMobileSheets);
  });

  document.querySelectorAll("[data-dashboard-sheet] a").forEach((link) => {
    if (link.dataset.dashboardSheetLinkBound === "true") return;
    link.dataset.dashboardSheetLinkBound = "true";
    link.addEventListener("click", closeDashboardMobileSheets);
  });
}

function initDashboardJournalPetPicker() {
  const addSheet = document.querySelector('[data-dashboard-sheet="add"]');
  const sourcePetSheet = document.querySelector('[data-dashboard-sheet="public-access-pet"]');

  if (!addSheet || !sourcePetSheet || document.querySelector('[data-dashboard-sheet="journal-pet"]')) return;

  const journalLink = [...addSheet.querySelectorAll("a.pj-mobile-sheet__action")]
    .find((link) => /\/pets\/\d+\/events\/new(?:$|[?#])/.test(link.getAttribute("href") || ""));

  if (!journalLink) return;

  const journalPetSheet = sourcePetSheet.cloneNode(true);
  journalPetSheet.dataset.dashboardSheet = "journal-pet";
  journalPetSheet.setAttribute("aria-labelledby", "pj-mobile-journal-pet-title");

  const heading = journalPetSheet.querySelector("h2");
  if (heading) {
    heading.id = "pj-mobile-journal-pet-title";
    heading.textContent = "Для какого питомца?";
  }

  const kicker = journalPetSheet.querySelector(".pj-mobile-sheet__head small");
  if (kicker) kicker.textContent = "Запись в журнал";

  journalPetSheet.querySelectorAll('a[href*="/profile_shares/new"]').forEach((link) => {
    link.setAttribute("href", link.getAttribute("href").replace("/profile_shares/new", "/events/new"));
  });

  const trigger = document.createElement("button");
  trigger.type = "button";
  trigger.className = journalLink.className;
  trigger.innerHTML = journalLink.innerHTML;
  trigger.setAttribute("aria-expanded", "false");
  trigger.dataset.dashboardSheetToggle = "journal-pet";

  const description = trigger.querySelector("small");
  if (description) description.textContent = "Сначала выберите питомца";

  journalLink.replaceWith(trigger);
  sourcePetSheet.insertAdjacentElement("beforebegin", journalPetSheet);
}

function initDashboardSidebar() {
  document.querySelectorAll("[data-dashboard-root]").forEach((root) => {
    const button = root.querySelector("[data-dashboard-sidebar-toggle]");
    if (!button || button.dataset.dashboardSidebarBound === "true") return;

    button.dataset.dashboardSidebarBound = "true";

    const storedPreference = dashboardSidebarPreference();
    const defaultCollapsed = window.matchMedia("(min-width: 821px) and (max-width: 1100px)").matches;
    let collapsed = storedPreference === null ? defaultCollapsed : storedPreference === "true";

    const render = () => {
      root.classList.toggle("is-sidebar-collapsed", collapsed);
      button.setAttribute("aria-expanded", String(!collapsed));
      button.setAttribute("aria-label", collapsed ? "Развернуть боковое меню" : "Свернуть боковое меню");
      button.title = collapsed ? "Развернуть меню" : "Свернуть меню";
    };

    button.addEventListener("click", () => {
      closeDashboardProfileMenus();
      collapsed = !collapsed;
      saveDashboardSidebarPreference(collapsed);
      render();
    });

    root.querySelectorAll("[data-dashboard-profile-menu]").forEach((menu) => {
      menu.addEventListener("toggle", () => {
        if (menu.open) closeDashboardProfileMenus(menu);
      });
    });

    render();
  });
}

function initDashboardUi() {
  initDashboardSidebar();
  initDashboardJournalPetPicker();
  initDashboardMobileSheets();
}

document.addEventListener("click", (event) => {
  if (event.target.closest?.("[data-dashboard-sheet-close]")) {
    closeDashboardMobileSheets();
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

  closeDashboardMobileSheets();
});

document.addEventListener("DOMContentLoaded", initDashboardUi);
document.addEventListener("turbo:load", initDashboardUi);
document.addEventListener("turbo:render", initDashboardUi);
document.addEventListener("turbo:before-cache", closeDashboardMobileSheets);
