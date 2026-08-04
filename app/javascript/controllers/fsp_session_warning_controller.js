import { Controller } from "@hotwired/stimulus"

// Soft warning when the selected FSP already has a job for the same date + AM/PM.
// Does not block submit — admin may still assign.
export default class extends Controller {
  static targets = [ "dateField", "fspSelect", "warning", "warningText" ]
  static values = {
    url: String,
    excludeJobId: { type: String, default: "" }
  }

  connect() {
    this._abort = null
    this.check()
  }

  disconnect() {
    if (this._abort) this._abort.abort()
  }

  check() {
    const date = this.dateValue()
    const period = this.periodValue()
    const fspId = this.fspValue()

    if (!date || !period || !fspId || !this.urlValue) {
      this.hide()
      return
    }

    if (this._abort) this._abort.abort()
    this._abort = new AbortController()

    const params = new URLSearchParams({
      scheduled_on: date,
      scheduled_time: period,
      fsp_id: fspId
    })
    if (this.excludeJobIdValue) {
      params.set("exclude_id", this.excludeJobIdValue)
    }

    fetch(`${this.urlValue}?${params.toString()}`, {
      headers: { Accept: "application/json" },
      credentials: "same-origin",
      signal: this._abort.signal
    })
      .then((response) => {
        if (!response.ok) throw new Error("check failed")
        return response.json()
      })
      .then((data) => {
        if (data?.conflict && data.message) {
          this.show(data.message)
        } else {
          this.hide()
        }
      })
      .catch((error) => {
        if (error.name === "AbortError") return
        this.hide()
      })
  }

  dateValue() {
    if (this.hasDateFieldTarget) {
      return (this.dateFieldTarget.value || "").trim()
    }
    const input = this.element.querySelector('[name="inspection_request[scheduled_on]"]')
    return (input?.value || "").trim()
  }

  periodValue() {
    const selected = this.element.querySelector(
      'input[name="inspection_request[scheduled_time]"]:checked'
    )
    return (selected?.value || "").toUpperCase()
  }

  fspValue() {
    if (this.hasFspSelectTarget) {
      return (this.fspSelectTarget.value || "").trim()
    }
    const select = this.element.querySelector('[name="inspection_request[fsp_id]"]')
    return (select?.value || "").trim()
  }

  show(message) {
    if (this.hasWarningTextTarget) this.warningTextTarget.textContent = message
    if (this.hasWarningTarget) {
      this.warningTarget.hidden = false
      this.warningTarget.classList.remove("hidden")
    }
  }

  hide() {
    if (this.hasWarningTextTarget) this.warningTextTarget.textContent = ""
    if (this.hasWarningTarget) {
      this.warningTarget.hidden = true
      this.warningTarget.classList.add("hidden")
    }
  }
}
