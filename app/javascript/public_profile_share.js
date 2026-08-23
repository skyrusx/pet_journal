function fallbackCopy(text) {
  if (navigator.clipboard?.writeText) {
    return navigator.clipboard.writeText(text);
  }

  return new Promise((resolve, reject) => {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();

    try {
      const copied = document.execCommand("copy");
      copied ? resolve() : reject(new Error("copy failed"));
    } catch (error) {
      reject(error);
    } finally {
      textarea.remove();
    }
  });
}

function setShareLabel(button, text) {
  const label = button.querySelector("span");
  if (label) label.textContent = text;
}

function initPublicProfileShare(root = document) {
  root.querySelectorAll("[data-public-share]").forEach((button) => {
    if (button.dataset.publicShareBound === "true") return;
    button.dataset.publicShareBound = "true";

    button.addEventListener("click", async () => {
      const url = button.dataset.publicShareUrl || window.location.href;
      const title = button.dataset.publicShareTitle || document.title;

      try {
        if (navigator.share) {
          await navigator.share({ title, url });
          return;
        }

        await fallbackCopy(url);
        setShareLabel(button, "Ссылка скопирована");
        window.setTimeout(() => setShareLabel(button, "Поделиться"), 1800);
      } catch (error) {
        if (error?.name === "AbortError") return;

        try {
          await fallbackCopy(url);
          setShareLabel(button, "Ссылка скопирована");
        } catch (_copyError) {
          setShareLabel(button, "Не удалось поделиться");
        }

        window.setTimeout(() => setShareLabel(button, "Поделиться"), 1800);
      }
    });
  });
}

document.addEventListener("DOMContentLoaded", () => initPublicProfileShare());
document.addEventListener("turbo:load", () => initPublicProfileShare());
document.addEventListener("turbo:render", () => initPublicProfileShare());
