import { Controller } from "@hotwired/stimulus"

// Planner: open a modal to schedule/reschedule a job without leaving the page.
export default class extends Controller {
  static targets = [
    "dialog",
    "form",
    "title",
    "subtitle",
    "dateField",
    "periodAm",
    "periodPm",
    "fspSelect",
    "error",
    "errorText",
    "viewJob"
  ]

  connect() {
    this.close()
  }

  disconnect() {
    this.unlockScroll()
    document.removeEventListener("keydown", this._onKeydown)
  }

  open(event) {
    event.preventDefault()
    const { jobId, title, subtitle, date, period, fspId } = event.params
    if (!jobId) return

    this.formTarget.action = `/dashboard/jobs/${jobId}/schedule`
    this.titleTarget.textContent = title || "Schedule inspection"
    this.subtitleTarget.textContent = subtitle || ""

    if (this.hasViewJobTarget) {
      this.viewJobTarget.href = `/dashboard/jobs/${jobId}`
    }

    // Keep planner return context in sync with the current URL (week / FSP filter).
    const url = new URL(window.location.href)
    const weekInput = this.formTarget.querySelector('input[name="week"]')
    const fspFilterInput = this.formTarget.querySelector('input[name="fsp_filter"]')
    if (weekInput) weekInput.value = url.searchParams.get("week") || weekInput.value
    if (fspFilterInput) fspFilterInput.value = url.searchParams.get("fsp_id") || ""

    this.setDate(date || "")
    this.setPeriod(period || "")
    this.setFsp(fspId != null && fspId !== "" ? String(fspId) : "")
    this.setSessionWarningExclude(jobId)
    this.clearError()
    this.refreshSessionWarning()

    this.dialogTarget.hidden = false
    this.lockScroll()
    this._onKeydown = (e) => {
      if (e.key === "Escape") this.close(e)
    }
    document.addEventListener("keydown", this._onKeydown)

    // Ensure calendar stays closed when the modal opens (don't auto-focus the date field).
    requestAnimationFrame(() => {
      const picker = this.dateFieldTarget?._flatpickr
      if (picker) picker.close()
    })
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    this.unlockScroll()
    document.removeEventListener("keydown", this._onKeydown)
    this.clearError()
    this.hideSessionWarning()
  }

  hideSessionWarning() {
    const form = this.hasFormTarget ? this.formTarget : null
    if (!form) return
    const warning = this.application.getControllerForElementAndIdentifier(
      form,
      "fsp-session-warning"
    )
    if (warning && typeof warning.hide === "function") warning.hide()
  }

  // Click on backdrop only (not the dialog panel).
  backdropClose(event) {
    if (event.target === event.currentTarget) this.close(event)
  }

  setDate(isoDate) {
    if (!this.hasDateFieldTarget) return
    const el = this.dateFieldTarget
    if (el._flatpickr) {
      if (isoDate) {
        // false = don't open the calendar when setting a value
        el._flatpickr.setDate(isoDate, false)
      } else {
        el._flatpickr.clear()
      }
      el._flatpickr.close()
    } else {
      el.value = isoDate || ""
    }
  }

  setPeriod(period) {
    const value = (period || "").toUpperCase()
    if (this.hasPeriodAmTarget) this.periodAmTarget.checked = value === "AM"
    if (this.hasPeriodPmTarget) this.periodPmTarget.checked = value === "PM"
  }

  setFsp(fspId) {
    if (!this.hasFspSelectTarget) return
    this.fspSelectTarget.value = fspId || ""
  }

  setSessionWarningExclude(jobId) {
    const form = this.hasFormTarget ? this.formTarget : null
    if (!form) return
    form.dataset.fspSessionWarningExcludeJobIdValue = jobId ? String(jobId) : ""

    const warning = this.application.getControllerForElementAndIdentifier(
      form,
      "fsp-session-warning"
    )
    if (warning) {
      warning.excludeJobIdValue = jobId ? String(jobId) : ""
    }
  }

  refreshSessionWarning() {
    const form = this.hasFormTarget ? this.formTarget : null
    if (!form) return
    const warning = this.application.getControllerForElementAndIdentifier(
      form,
      "fsp-session-warning"
    )
    if (warning && typeof warning.check === "function") {
      // Defer so date/period/FSP fields are fully updated first.
      requestAnimationFrame(() => warning.check())
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = true
      this.errorTarget.classList.add("hidden")
    }
    if (this.hasErrorTextTarget) this.errorTextTarget.textContent = ""
  }

  // Lightweight client validation before submit.
  submit(event) {
    const date = (this.dateFieldTarget?.value || "").trim()
    const period = this.hasPeriodAmTarget && this.periodAmTarget.checked
      ? "AM"
      : this.hasPeriodPmTarget && this.periodPmTarget.checked
        ? "PM"
        : ""

    if (!date) {
      event.preventDefault()
      this.showError("Pick a schedule date.")
      return
    }
    if (!period) {
      event.preventDefault()
      this.showError("Select a time (AM or PM).")
      return
    }
    this.clearError()
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = false
      this.errorTarget.classList.remove("hidden")
    }
    if (this.hasErrorTextTarget) this.errorTextTarget.textContent = message
  }

  lockScroll() {
    document.documentElement.classList.add("planner-modal-open")
  }

  unlockScroll() {
    document.documentElement.classList.remove("planner-modal-open")
  }
}
