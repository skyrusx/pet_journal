function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content || "";
}

document.addEventListener("click", async (event) => {
  const button = event.target.closest?.("[data-pet-main-photo-delete]");
  if (!button || button.disabled) return;

  event.preventDefault();
  event.stopPropagation();

  if (!window.confirm(button.dataset.confirm || "Удалить фото профиля?")) return;

  button.disabled = true;

  try {
    const response = await fetch(button.dataset.url, {
      method: "DELETE",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": csrfToken()
      }
    });

    let payload = {};
    try {
      payload = await response.json();
    } catch (_error) {
      payload = {};
    }

    if (!response.ok) throw new Error(payload.error || "Не удалось удалить фото профиля.");

    if (window.Turbo?.visit) {
      window.Turbo.visit(window.location.href, { action: "replace" });
    } else {
      window.location.reload();
    }
  } catch (error) {
    button.disabled = false;
    window.alert(error.message);
  }
});
