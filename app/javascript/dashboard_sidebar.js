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

document.addEventListener("click", (event) => {
  document.querySelectorAll("[data-dashboard-profile-menu][open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.removeAttribute("open");
  });
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return;

  const openMenu = document.querySelector("[data-dashboard-profile-menu][open]");
  if (!openMenu) return;

  openMenu.removeAttribute("open");
  openMenu.querySelector("summary")?.focus();
});

document.addEventListener("DOMContentLoaded", initDashboardSidebar);
document.addEventListener("turbo:load", initDashboardSidebar);
document.addEventListener("turbo:render", initDashboardSidebar);
