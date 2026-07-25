import { Controller } from "@hotwired/stimulus"

// Mobile header menu: opens nav links in a centered popup modal.
export default class extends Controller {
  static targets = ["panel", "button", "openIcon", "closeIcon"]
  static classes = ["open"]

  connect() {
    this.close()
  }

  disconnect() {
    this.unlockScroll()
  }

  toggle(event) {
    event.preventDefault()
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.element.classList.add(this.openClass)
    if (this.hasPanelTarget) this.panelTarget.hidden = false
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
      this.buttonTarget.setAttribute("aria-label", "Close menu")
    }
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove("hidden")
    this.lockScroll()
  }

  close(event) {
    if (event) event.preventDefault()
    this.element.classList.remove(this.openClass)
    if (this.hasPanelTarget) this.panelTarget.hidden = true
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
      this.buttonTarget.setAttribute("aria-label", "Open menu")
    }
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add("hidden")
    this.unlockScroll()
  }

  // Close when a nav link is clicked.
  navigate() {
    this.close()
  }

  // Close on Escape.
  keydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
      if (this.hasButtonTarget) this.buttonTarget.focus()
    }
  }

  lockScroll() {
    document.documentElement.style.overflow = "hidden"
  }

  unlockScroll() {
    document.documentElement.style.overflow = ""
  }

  get isOpen() {
    return this.element.classList.contains(this.openClass)
  }
}
