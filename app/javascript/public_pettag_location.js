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
        // Native Web Share is reliable on mobile browsers. On desktop browsers
        // support is inconsistent, so copying the link gives an immediate,
        // predictable result instead of a click that appears to do nothing.
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

const setupPublicInteractions = () => {
  setupPublicPetTagLocation()
  setupPublicProfileShare()
}

document.addEventListener("DOMContentLoaded", setupPublicInteractions)
document.addEventListener("turbo:load", setupPublicInteractions)
document.addEventListener("turbo:render", setupPublicInteractions)
