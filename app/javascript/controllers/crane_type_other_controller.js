import { Controller } from "@hotwired/stimulus"

// Shows a free-text crane type field when the visitor picks "Others".
export default class extends Controller {
  static targets = [ "select", "other" ]

  connect() {
    this.sync()
  }

  toggle() {
    this.sync()
  }

  sync() {
    const isOther = this.selectTarget.value === "others"
    this.otherTarget.hidden = !isOther

    const input = this.otherTarget.querySelector("input")
    if (!input) return

    input.required = isOther
    if (!isOther) input.value = ""
  }
}
