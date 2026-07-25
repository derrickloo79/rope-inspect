import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// Date field that opens a calendar above the input (avoids overflow under sticky bars).
export default class extends Controller {
  connect() {
    this.picker = flatpickr(this.element, {
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "field-input flatpickr-alt-input",
      allowInput: false,
      disableMobile: true,
      // Prefer opening above so sticky bottom action bars do not clip the calendar.
      position: "above",
      appendTo: document.body,
      static: false,
      monthSelectorType: "static"
    })
  }

  disconnect() {
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }
  }
}
