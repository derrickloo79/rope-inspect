import { Controller } from "@hotwired/stimulus"

// Map location: Places Autocomplete (New) when a key is set, plus free-text / pasted links.

// Official Maps JS bootstrap — defines google.maps.importLibrary, then loads the API.
function installMapsBootstrap(apiKey) {
  const googleNs = (window.google = window.google || {})
  const maps = (googleNs.maps = googleNs.maps || {})
  if (typeof maps.importLibrary === "function") return

  const pending = new Set()
  let loading = null

  const startLoad = () => {
    loading ||= new Promise((resolve, reject) => {
      const params = new URLSearchParams()
      params.set("key", apiKey)
      params.set("v", "weekly")
      params.set("libraries", Array.from(pending).join(","))
      params.set("callback", "google.maps.__ib__")
      maps.__ib__ = resolve

      const script = document.createElement("script")
      script.src = `https://maps.googleapis.com/maps/api/js?${params}`
      script.async = true
      script.onerror = () => reject(new Error("Google Maps failed to load"))
      document.head.appendChild(script)
    })
    return loading
  }

  maps.importLibrary = (name, ...args) => {
    pending.add(name)
    return startLoad().then(() => maps.importLibrary(name, ...args))
  }
}

function loadPlacesLibrary(apiKey) {
  installMapsBootstrap(apiKey)
  return google.maps.importLibrary("places")
}

export default class extends Controller {
  static targets = [ "input", "clear", "list" ]
  static values = {
    apiKey: { type: String, default: "" }
  }

  connect() {
    this.places = null
    this.sessionToken = null
    this.suggestions = []
    this.activeIndex = -1
    this.debounceTimer = null
    this.legacyAutocomplete = null
    this.boundClose = this.closeOnOutside.bind(this)
    document.addEventListener("mousedown", this.boundClose)
    this.refresh()
  }

  disconnect() {
    this.clearTimer()
    this.teardownLegacy()
    this.hideList()
    if (this.boundClose) document.removeEventListener("mousedown", this.boundClose)
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
    this.hideList()
    this.refresh()
    this.inputTarget.focus()
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  async prepare() {
    if (!this.apiKeyValue) return

    try {
      this.places = await loadPlacesLibrary(this.apiKeyValue)
    } catch (error) {
      console.warn("Google Places failed to load.", error)
      return
    }

    if (this.places?.AutocompleteSuggestion) return

    // Older keys: fall back to the legacy widget once the field is visible.
    this.bindLegacyAutocomplete()
  }

  suggest() {
    this.refresh()
    if (!this.apiKeyValue) return

    this.clearTimer()
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this.hideList()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchSuggestions(query), 220)
  }

  keydown(event) {
    if (!this.hasListTarget || this.listTarget.hidden) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveActive(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveActive(-1)
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.pick(this.activeIndex)
    } else if (event.key === "Escape") {
      this.hideList()
    }
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.hideList()
  }

  async fetchSuggestions(query) {
    if (!this.places?.AutocompleteSuggestion) {
      await this.prepare()
    }
    if (!this.places?.AutocompleteSuggestion) return

    try {
      if (!this.sessionToken && this.places.AutocompleteSessionToken) {
        this.sessionToken = new this.places.AutocompleteSessionToken()
      }

      const { suggestions } = await this.places.AutocompleteSuggestion.fetchAutocompleteSuggestions({
        input: query,
        sessionToken: this.sessionToken
      })

      this.suggestions = suggestions || []
      this.renderList()
    } catch (error) {
      console.warn("Places autocomplete request failed.", error)
      this.hideList()
    }
  }

  renderList() {
    if (!this.hasListTarget) return

    this.listTarget.innerHTML = ""
    this.activeIndex = -1

    if (this.suggestions.length === 0) {
      this.hideList()
      return
    }

    this.suggestions.forEach((suggestion, index) => {
      const label = this.predictionLabel(suggestion)
      if (!label) return

      const item = document.createElement("li")
      item.className = "map-suggest__item"
      item.setAttribute("role", "option")
      item.dataset.index = String(index)
      item.textContent = label
      item.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.pick(index)
      })
      this.listTarget.appendChild(item)
    })

    if (this.listTarget.children.length === 0) {
      this.hideList()
      return
    }

    this.listTarget.hidden = false
  }

  async pick(index) {
    const suggestion = this.suggestions[index]
    if (!suggestion) return

    const value = await this.displayValueForSuggestion(suggestion)
    if (value) this.inputTarget.value = value

    this.sessionToken = null
    this.hideList()
    this.refresh()
  }

  async displayValueForSuggestion(suggestion) {
    const prediction = suggestion.placePrediction
    if (!prediction) return this.predictionLabel(suggestion)

    try {
      const place = prediction.toPlace()
      await place.fetchFields({ fields: [ "displayName", "formattedAddress" ] })
      const name = this.asText(place.displayName)
      const formatted = this.asText(place.formattedAddress)
      if (name && formatted) {
        if (formatted.toLowerCase().includes(name.toLowerCase())) return formatted
        return `${name}, ${formatted}`
      }
      return name || formatted || this.predictionLabel(suggestion)
    } catch (_error) {
      return this.predictionLabel(suggestion)
    }
  }

  predictionLabel(suggestion) {
    const prediction = suggestion.placePrediction
    if (!prediction) return ""
    return this.asText(prediction.text)
  }

  asText(value) {
    if (!value) return ""
    if (typeof value === "string") return value.trim()
    if (typeof value.text === "string") return value.text.trim()
    if (typeof value.toString === "function") {
      const text = value.toString()
      if (text && text !== "[object Object]") return text.trim()
    }
    return ""
  }

  moveActive(delta) {
    const items = Array.from(this.listTarget.querySelectorAll(".map-suggest__item"))
    if (items.length === 0) return

    this.activeIndex = (this.activeIndex + delta + items.length) % items.length
    items.forEach((item, i) => {
      item.classList.toggle("is-active", i === this.activeIndex)
    })
    items[this.activeIndex].scrollIntoView({ block: "nearest" })
  }

  hideList() {
    this.suggestions = []
    this.activeIndex = -1
    if (this.hasListTarget) {
      this.listTarget.innerHTML = ""
      this.listTarget.hidden = true
    }
  }

  bindLegacyAutocomplete() {
    if (this.legacyAutocomplete || !this.hasInputTarget) return
    if (!this.inputVisible()) return
    if (!window.google?.maps?.places?.Autocomplete) return

    this.legacyAutocomplete = new google.maps.places.Autocomplete(this.inputTarget, {
      fields: [ "formatted_address", "name", "url", "place_id", "geometry" ]
    })
    this.legacyAutocomplete.addListener("place_changed", () => {
      const place = this.legacyAutocomplete.getPlace()
      if (!place) return
      const name = (place.name || "").trim()
      const formatted = (place.formatted_address || "").trim()
      if (name && formatted && !formatted.toLowerCase().includes(name.toLowerCase())) {
        this.inputTarget.value = `${name}, ${formatted}`
      } else {
        this.inputTarget.value = formatted || name || place.url || this.inputTarget.value
      }
      this.refresh()
    })
  }

  teardownLegacy() {
    if (this.legacyAutocomplete && window.google?.maps?.event) {
      google.maps.event.clearInstanceListeners(this.legacyAutocomplete)
    }
    this.legacyAutocomplete = null
  }

  inputVisible() {
    return Boolean(this.hasInputTarget && this.inputTarget.offsetParent)
  }

  clearTimer() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  }
}
