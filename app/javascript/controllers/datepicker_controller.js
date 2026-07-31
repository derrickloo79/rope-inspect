import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// Date field with calendar popup. Default opens above (sticky bars).
// Set data-datepicker-position-value="below" to open under the field (e.g. modals).
export default class extends Controller {
  static values = {
    position: { type: String, default: "above" }
  }

  connect() {
    this.picker = flatpickr(this.element, {
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "field-input flatpickr-alt-input",
      allowInput: false,
      disableMobile: true,
      clickOpens: true,
      // Job detail sticky bars: above. Planner modal: below (position value).
      position: this.positionValue === "below" ? "below" : "above",
      appendTo: document.body,
      static: false,
      monthSelectorType: "static",
      onChange: () => {
        // Keep native change listeners (e.g. schedule-form validation) in sync.
        this.element.dispatchEvent(new Event("change", { bubbles: true }))
        this.element.dispatchEvent(new Event("input", { bubbles: true }))
      }
    })
  }

  disconnect() {
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }
  }
}
