// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  localStorage.setItem("petjournal-theme", theme);

  document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
    button.setAttribute("aria-label", theme === "dark" ? "Включить светлую тему" : "Включить темную тему");
    button.setAttribute("title", theme === "dark" ? "Светлая тема" : "Темная тема");
    button.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const currentTheme = document.documentElement.dataset.theme || "light";
  applyTheme(currentTheme);

  document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      applyTheme(document.documentElement.dataset.theme === "dark" ? "light" : "dark");
    });
  });

  document.querySelectorAll("[data-flash-toast]").forEach((toast) => {
    const close = toast.querySelector("[data-flash-close]");
    const dismiss = () => {
      toast.classList.add("closing");
      window.setTimeout(() => toast.remove(), 180);
    };

    close?.addEventListener("click", dismiss);
    window.setTimeout(dismiss, 5200);
  });
});
