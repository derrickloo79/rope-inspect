import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// One field that picks a start and end date. Hidden inputs hold ISO dates for the form.
export default class extends Controller {
  static targets = [ "input", "start", "end" ]
  static values = { start: String, end: String }

  connect() {
    const defaults = [ this.parse(this.startValue), this.parse(this.endValue) ].filter(Boolean)

    this.picker = flatpickr(this.inputTarget, {
      mode: "range",
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "field-input flatpickr-alt-input",
      defaultDate: defaults,
      allowInput: false,
      disableMobile: true,
      clickOpens: true,
      position: "below",
      appendTo: document.body,
      conjunction: " to ",
      monthSelectorType: "static",
      onReady: (_dates, _str, instance) => {
        instance.calendarContainer.classList.add("job-csv-calendar")
        if (instance.altInput && this.inputTarget.id) {
          instance.altInput.id = this.inputTarget.id
          this.inputTarget.removeAttribute("id")
        }
        this.sync(instance.selectedDates)
      },
      onChange: (dates) => this.sync(dates)
    })
  }

  disconnect() {
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }
  }

  close() {
    if (this.picker) this.picker.close()
  }

  sync(dates) {
    if (!this.hasStartTarget || !this.hasEndTarget) return

    this.startTarget.value = dates[0] ? this.iso(dates[0]) : ""
    this.endTarget.value = dates[1] ? this.iso(dates[1]) : ""
    this.startTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  parse(iso) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso || "")
    if (!match) return null

    return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
  }

  iso(date) {
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    return `${date.getFullYear()}-${month}-${day}`
  }
}
