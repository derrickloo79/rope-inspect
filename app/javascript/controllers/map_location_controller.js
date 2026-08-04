import { Controller } from "@hotwired/stimulus"

// Map location field: Google Places address autocomplete (when API key set),
// free-text / pasted Maps links, and an in-field clear control.
let mapsLoaderPromise = null

function loadGoogleMapsPlaces(apiKey) {
  if (window.google?.maps?.places) return Promise.resolve()
  if (mapsLoaderPromise) return mapsLoaderPromise

  mapsLoaderPromise = new Promise((resolve, reject) => {
    const existing = document.querySelector("script[data-google-maps-places]")
    if (existing) {
      if (window.google?.maps?.places) {
        resolve()
        return
      }
      existing.addEventListener("load", () => resolve(), { once: true })
      existing.addEventListener("error", () => reject(new Error("Google Maps failed to load")), { once: true })
      return
    }

    const callbackName = `__initGoogleMapsPlaces_${Date.now()}`
    window[callbackName] = () => {
      delete window[callbackName]
      resolve()
    }

    const script = document.createElement("script")
    script.src =
      `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}` +
      `&libraries=places&callback=${callbackName}`
    script.async = true
    script.defer = true
    script.dataset.googleMapsPlaces = "true"
    script.onerror = () => {
      delete window[callbackName]
      mapsLoaderPromise = null
      reject(new Error("Google Maps failed to load"))
    }
    document.head.appendChild(script)
  })

  return mapsLoaderPromise
}

export default class extends Controller {
  static targets = [ "input", "clear" ]
  static values = {
    apiKey: { type: String, default: "" }
  }

  connect() {
    this.autocomplete = null
    this.refresh()
    if (this.apiKeyValue) {
      this.ensureAutocomplete()
    }
  }

  disconnect() {
    if (this.autocomplete && window.google?.maps?.event) {
      google.maps.event.clearInstanceListeners(this.autocomplete)
    }
    this.autocomplete = null
  }

  refresh() {
    const hasValue = this.inputTarget.value.trim().length > 0
    if (this.hasClearTarget) {
      this.clearTarget.hidden = !hasValue
    }
  }

  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.refresh()
    this.inputTarget.focus()
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  async ensureAutocomplete() {
    if (this.autocomplete || !this.apiKeyValue) return

    try {
      await loadGoogleMapsPlaces(this.apiKeyValue)
    } catch (_error) {
      return
    }

    if (this.autocomplete || !this.hasInputTarget) return
    if (!window.google?.maps?.places) return

    // No `types` restriction so both addresses and businesses are suggested.
    this.autocomplete = new google.maps.places.Autocomplete(this.inputTarget, {
      fields: [ "formatted_address", "name", "url", "place_id", "geometry" ]
    })

    this.autocomplete.addListener("place_changed", () => this.onPlaceChanged())

    // Keep pac-container above cards / sticky chrome.
    this.inputTarget.addEventListener("focus", () => this.bumpPacZIndex())
  }

  onPlaceChanged() {
    const place = this.autocomplete?.getPlace()
    if (!place) return

    // Use the place *name* when present. Relying only on formatted_address often
    // collapses a specific site (e.g. "Woh Hup WCP Site 2") to a nearby street
    // ("Woodlands Centre Rd"). Prefer "Name, Address" for establishments.
    const value = this.displayValueForPlace(place)
    if (value) {
      this.inputTarget.value = value
    }

    this.closeSuggestions()
    this.refresh()
  }

  displayValueForPlace(place) {
    const name = (place.name || "").trim()
    const formatted = (place.formatted_address || "").trim()

    if (name && formatted) {
      if (formatted.toLowerCase().includes(name.toLowerCase())) {
        return formatted
      }
      return `${name}, ${formatted}`
    }

    return name || formatted || place.url || ""
  }

  closeSuggestions() {
    // Google's .pac-container can linger after a click selection (esp. when we
    // rewrite the input value). Hide it and blur so it doesn't stay open.
    document.querySelectorAll(".pac-container").forEach((el) => {
      el.style.display = "none"
    })
    this.inputTarget.blur()
  }

  bumpPacZIndex() {
    // Google injects .pac-container on the body; ensure it stacks above UI chrome
    // and re-show if it was hidden after a previous selection.
    requestAnimationFrame(() => {
      document.querySelectorAll(".pac-container").forEach((el) => {
        el.style.zIndex = "10000"
        el.style.display = ""
      })
    })
  }
}
