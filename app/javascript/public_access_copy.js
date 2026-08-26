const copyPublicAccessText = async (value) => {
  if (navigator.clipboard?.writeText && window.isSecureContext) {
    await navigator.clipboard.writeText(value)
    return
  }

  const textarea = document.createElement("textarea")
  textarea.value = value
  textarea.setAttribute("readonly", "")
  textarea.style.position = "fixed"
  textarea.style.left = "-9999px"
  document.body.appendChild(textarea)
  textarea.select()

  const copied = document.execCommand("copy")
  textarea.remove()

  if (!copied) throw new Error("copy failed")
}

document.addEventListener("click", async (event) => {
  const button = event.target.closest(".pj-public-access-copy-icon")
  if (!button) return

  event.preventDefault()
  event.stopImmediatePropagation()

  const value = button.dataset.copyUrl
  if (!value) return

  const originalLabel = button.getAttribute("aria-label") || "Скопировать ссылку"
  const originalTitle = button.getAttribute("title") || "Скопировать ссылку"

  try {
    await copyPublicAccessText(value)
    button.classList.add("is-copied")
    button.setAttribute("aria-label", "Ссылка скопирована")
    button.setAttribute("title", "Ссылка скопирована")
  } catch (_error) {
    button.setAttribute("aria-label", "Не удалось скопировать ссылку")
    button.setAttribute("title", "Не удалось скопировать ссылку")
  }

  window.setTimeout(() => {
    button.classList.remove("is-copied")
    button.setAttribute("aria-label", originalLabel)
    button.setAttribute("title", originalTitle)
  }, 1800)
}, true)
