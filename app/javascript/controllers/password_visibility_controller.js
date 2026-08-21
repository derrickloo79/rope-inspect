import { Controller } from "@hotwired/stimulus"

// Toggle a password field between masked and visible (eye / eye-slash).
export default class extends Controller {
  static targets = [ "input", "showIcon", "hideIcon", "button" ]

  connect() {
    this.sync()
  }

  toggle() {
    const reveal = this.inputTarget.type === "password"
    this.inputTarget.type = reveal ? "text" : "password"
    this.sync()
  }

  sync() {
    const visible = this.inputTarget.type === "text"
    if (this.hasShowIconTarget) this.showIconTarget.hidden = visible
    if (this.hasHideIconTarget) this.hideIconTarget.hidden = !visible
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-label", visible ? "Hide password" : "Show password")
      this.buttonTarget.setAttribute("title", visible ? "Hide password" : "Show password")
    }
  }
}
