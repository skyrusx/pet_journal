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

document.addEventListener("DOMContentLoaded", setupPublicPetTagLocation)
document.addEventListener("turbo:load", setupPublicPetTagLocation)
