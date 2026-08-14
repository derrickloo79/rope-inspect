import { Controller } from "@hotwired/stimulus"

// Makes a table/list row navigate like a link, while leaving nested
// links, buttons, and forms (Edit / Delete) to handle their own clicks.
export default class extends Controller {
  static values = { url: String }

  go(event) {
    if (event.target.closest("a, button, input, select, textarea, form")) return

    if (event.metaKey || event.ctrlKey || event.shiftKey) {
      window.open(this.urlValue, "_blank")
      return
    }

    if (window.Turbo) {
      window.Turbo.visit(this.urlValue)
    } else {
      window.location.assign(this.urlValue)
    }
  }

  keydown(event) {
    if (event.target !== this.element) return
    if (event.key !== "Enter" && event.key !== " ") return

    event.preventDefault()
    this.go(event)
  }
}
