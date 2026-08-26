const locationErrorMessage = (error) => {
  if (!error) return "Не удалось получить геолокацию. Укажите место вручную."

  switch (error.code) {
    case error.PERMISSION_DENIED:
      return "Доступ к геолокации запрещён. Разрешите геолокацию для этого сайта в настройках браузера или укажите место вручную."
    case error.POSITION_UNAVAILABLE:
      return "Не удалось определить текущее местоположение. Укажите место вручную."
    case error.TIMEOUT:
      return "Не удалось определить местоположение вовремя. Попробуйте ещё раз или укажите место вручную."
    default:
      return "Не удалось получить геолокацию. Укажите место вручную."
  }
}

const setupPublicPetTagLocation = () => {
  const button = document.querySelector("[data-location-button]")
  const status = document.querySelector("[data-location-status]")
  const latitude = document.getElementById("location-latitude")
  const longitude = document.getElementById("location-longitude")

  if (!button || !status || !latitude || !longitude || button.dataset.locationReady === "true") return

  button.dataset.locationReady = "true"

  button.addEventListener("click", () => {
    if (!window.isSecureContext) {
      status.textContent = "Браузер разрешает геолокацию только по HTTPS. Для локальной проверки по IP укажите место вручную; на HTTPS-домене геолокация будет доступна."
      status.classList.add("is-error")
      return
    }

    if (!navigator.geolocation) {
      status.textContent = "Геолокация недоступна в этом браузере. Укажите место вручную."
      status.classList.add("is-error")
      return
    }

    button.disabled = true
    button.classList.add("is-loading")
    status.classList.remove("is-error", "is-success")
    status.textContent = "Запрашиваем ваше местоположение…"

    navigator.geolocation.getCurrentPosition(
      (position) => {
        latitude.value = position.coords.latitude
        longitude.value = position.coords.longitude
        button.classList.remove("is-loading")
        button.classList.add("is-ready")
        button.disabled = false
        status.classList.add("is-success")
        status.textContent = "Геолокация добавлена и будет отправлена владельцу вместе с сообщением."
      },
      (error) => {
        button.classList.remove("is-loading")
        button.disabled = false
        status.classList.add("is-error")
        status.textContent = locationErrorMessage(error)
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 60000 }
    )
  })
}

const copyPublicShareUrl = async (url) => {
  if (navigator.clipboard?.writeText && window.isSecureContext) {
    await navigator.clipboard.writeText(url)
    return
  }

  const textarea = document.createElement("textarea")
  textarea.value = url
  textarea.setAttribute("readonly", "")
  textarea.style.position = "fixed"
  textarea.style.left = "-9999px"
  document.body.appendChild(textarea)
  textarea.select()

  const copied = document.execCommand("copy")
  textarea.remove()

  if (!copied) throw new Error("copy failed")
}

const setPublicShareLabel = (button, text) => {
  const label = button.querySelector("span")
  if (label) label.textContent = text
}

const nativeShareIsUseful = () => {
  if (typeof navigator.share !== "function") return false

  const coarsePointer = window.matchMedia?.("(pointer: coarse)")?.matches
  return navigator.maxTouchPoints > 0 || coarsePointer
}

const setupPublicProfileShare = () => {
  document.querySelectorAll("[data-public-share]").forEach((button) => {
    if (button.dataset.publicShareReady === "true") return

    button.dataset.publicShareReady = "true"
    button.addEventListener("click", async () => {
      const url = button.dataset.publicShareUrl || window.location.href
      const title = button.dataset.publicShareTitle || document.title
      const originalLabel = "Поделиться"

      button.disabled = true

      try {
        if (nativeShareIsUseful()) {
          try {
            await navigator.share({ title, url })
            return
          } catch (error) {
            if (error?.name === "AbortError") return
          }
        }

        await copyPublicShareUrl(url)
        setPublicShareLabel(button, "Ссылка скопирована")
      } catch (_error) {
        setPublicShareLabel(button, "Не удалось скопировать")
      } finally {
        button.disabled = false
        window.setTimeout(() => setPublicShareLabel(button, originalLabel), 2200)
      }
    })
  })
}

const setupPublicShareCopy = () => {
  document.querySelectorAll(".pj-public-share-sheet__link").forEach((field) => {
    if (field.dataset.copyControlReady === "true") return

    const input = field.querySelector("input")
    if (!input) return

    field.dataset.copyControlReady = "true"

    const row = document.createElement("div")
    row.className = "pj-public-share-sheet__link-row"
    input.parentNode.insertBefore(row, input)
    row.appendChild(input)

    const button = document.createElement("button")
    button.type = "button"
    button.className = "pj-public-share-sheet__copy"
    button.setAttribute("aria-label", "Скопировать ссылку на профиль")
    button.title = "Скопировать ссылку"
    button.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="8" width="11" height="11" rx="2"></rect><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"></path></svg>'
    row.appendChild(button)

    const feedback = document.createElement("p")
    feedback.className = "pj-public-share-sheet__copy-feedback"
    feedback.setAttribute("aria-live", "polite")
    field.appendChild(feedback)

    let resetTimer
    button.addEventListener("click", async () => {
      window.clearTimeout(resetTimer)

      try {
        await copyPublicShareUrl(input.value)
        feedback.textContent = "Ссылка скопирована"
        button.setAttribute("aria-label", "Ссылка скопирована")
      } catch (_error) {
        input.focus()
        input.select()
        feedback.textContent = "Не удалось скопировать автоматически"
      }

      resetTimer = window.setTimeout(() => {
        feedback.textContent = ""
        button.setAttribute("aria-label", "Скопировать ссылку на профиль")
      }, 2200)
    })
  })
}

const setupPublicInteractions = () => {
  setupPublicPetTagLocation()
  setupPublicProfileShare()
  setupPublicShareCopy()
}

// The public script is loaded with defer, so the DOM is normally ready here.
// Calling once immediately also avoids depending only on lifecycle events.
setupPublicInteractions()
document.addEventListener("DOMContentLoaded", setupPublicInteractions)
document.addEventListener("turbo:load", setupPublicInteractions)
document.addEventListener("turbo:render", setupPublicInteractions)
