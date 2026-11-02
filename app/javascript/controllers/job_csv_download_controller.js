import { Controller } from "@hotwired/stimulus"

// Jobs index: CSV download dialog, with a date range and a status multi-select.
export default class extends Controller {
  static targets = [
    "dialog",
    "panel",
    "error",
    "statuses",
    "statusButton",
    "statusMenu",
    "statusSummary",
    "start",
    "end"
  ]

  show(event) {
    if (event) event.preventDefault()
    if (!this.hasDialogTarget) return

    this.closeStatuses()
    this.errorTarget.hidden = true
    this.dialogTarget.hidden = false
    document.documentElement.classList.add("planner-modal-open")
    if (this.hasPanelTarget) this.panelTarget.focus()
  }

  hide(event) {
    if (event) event.preventDefault()
    this.closeStatuses()
    this.closeCalendar()
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    document.documentElement.classList.remove("planner-modal-open")
  }

  backdropClose(event) {
    if (event.target === event.currentTarget) this.hide(event)
  }

  toggleStatuses(event) {
    event.preventDefault()
    event.stopPropagation()
    const opening = this.statusMenuTarget.hidden
    this.statusMenuTarget.hidden = !opening
    this.statusButtonTarget.setAttribute("aria-expanded", opening ? "true" : "false")
  }

  closeStatuses() {
    if (!this.hasStatusMenuTarget) return

    this.statusMenuTarget.hidden = true
    if (this.hasStatusButtonTarget) this.statusButtonTarget.setAttribute("aria-expanded", "false")
  }

  clearError() {
    if (this.hasErrorTarget) this.errorTarget.hidden = true
  }

  statusChanged() {
    const labels = Array.from(this.statusMenuTarget.querySelectorAll("input:checked"))
      .map((input) => input.dataset.label)

    if (labels.length === 0) {
      this.statusSummaryTarget.textContent = "Select statuses"
      this.statusSummaryTarget.classList.add("is-empty")
    } else {
      this.statusSummaryTarget.textContent = labels.join(", ")
      this.statusSummaryTarget.classList.remove("is-empty")
    }
    this.statusButtonTarget.title = this.statusSummaryTarget.textContent
  }

  outside(event) {
    if (!this.hasStatusMenuTarget || this.statusMenuTarget.hidden) return
    if (this.statusesTarget.contains(event.target)) return

    this.closeStatuses()
  }

  keydown(event) {
    if (event.key !== "Escape") return
    if (!this.hasDialogTarget || this.dialogTarget.hidden) return

    if (!this.statusMenuTarget.hidden) {
      this.closeStatuses()
      this.statusButtonTarget.focus()
      return
    }

    this.hide(event)
  }

  submit(event) {
    const start = this.hasStartTarget ? this.startTarget.value : ""
    const end = this.hasEndTarget ? this.endTarget.value : ""
    const selected = this.statusMenuTarget.querySelectorAll("input:checked").length
    const rangeInvalid = !start || !end || start > end

    if (rangeInvalid || selected === 0) {
      event.preventDefault()
      const message = rangeInvalid && selected === 0
        ? "Choose a start date, an end date, and at least one status."
        : (rangeInvalid ? "Choose a start date and an end date." : "Choose at least one status.")
      this.errorTarget.querySelector("p").textContent = message
      this.errorTarget.hidden = false
      this.errorTarget.focus()
      return
    }

    this.errorTarget.hidden = true
    this.closeStatuses()
    this.closeCalendar()
  }

  closeCalendar() {
    const range = this.element.querySelector("[data-controller~='date-range-picker']")
    if (!range) return

    this.application.getControllerForElementAndIdentifier(range, "date-range-picker")?.close()
  }
}
