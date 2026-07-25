import { Controller } from "@hotwired/stimulus"

// Validates schedule form when sticky "Mark scheduled" is pressed.
// Scrolls to the schedule section and shows an error if required details are missing.
export default class extends Controller {
  static targets = ["error", "errorText", "dateField", "section"]

  connect() {
    this.hideError()
  }

  submit(event) {
    const messages = this.validationMessages()
    if (messages.length === 0) {
      this.hideError()
      return
    }

    event.preventDefault()
    event.stopPropagation()
    this.showError(messages.join(" "))
    this.scrollToSection()
    this.focusFirstInvalid()
  }

  clearError() {
    this.hideError()
  }

  validationMessages() {
    const messages = []

    if (!this.dateValue()) {
      messages.push("Please choose a schedule date.")
    }

    if (!this.timeValue()) {
      messages.push("Please select a time (AM or PM).")
    }

    return messages
  }

  dateValue() {
    if (this.hasDateFieldTarget) {
      return (this.dateFieldTarget.value || "").trim()
    }
    const input = this.element.querySelector('[name="inspection_request[scheduled_on]"]')
    return (input?.value || "").trim()
  }

  timeValue() {
    const selected = this.element.querySelector(
      'input[name="inspection_request[scheduled_time]"]:checked'
    )
    return selected?.value || ""
  }

  showError(message) {
    if (this.hasErrorTextTarget) this.errorTextTarget.textContent = message
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = false
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTextTarget) this.errorTextTarget.textContent = ""
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = true
      this.errorTarget.classList.add("hidden")
    }
  }

  scrollToSection() {
    const section = this.hasSectionTarget ? this.sectionTarget : this.element.closest("#schedule-section")
    if (!section) return

    section.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  focusFirstInvalid() {
    if (!this.dateValue() && this.hasDateFieldTarget) {
      // Flatpickr hides the original input and shows an alt input.
      const alt = this.dateFieldTarget.nextElementSibling
      if (alt && alt.classList.contains("flatpickr-alt-input")) {
        alt.focus({ preventScroll: true })
        return
      }
      this.dateFieldTarget.focus({ preventScroll: true })
      return
    }

    if (!this.timeValue()) {
      const firstTime = this.element.querySelector(
        'input[name="inspection_request[scheduled_time]"]'
      )
      firstTime?.focus({ preventScroll: true })
    }
  }
}
