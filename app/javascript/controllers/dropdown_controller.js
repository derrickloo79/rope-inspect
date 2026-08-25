import { Controller } from "@hotwired/stimulus"

// Small anchored dropdown menu (e.g. the job details "..." actions button).
export default class extends Controller {
  static targets = ["button", "menu"]
  static classes = ["open"]

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.element.classList.add(this.openClass)
    this.menuTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.element.classList.remove(this.openClass)
    this.menuTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // Close on outside click.
  hide(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  // Close on Escape.
  keydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
      this.buttonTarget.focus()
    }
  }

  get isOpen() {
    return this.element.classList.contains(this.openClass)
  }
}
