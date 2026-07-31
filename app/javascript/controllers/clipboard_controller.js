import { Controller } from "@hotwired/stimulus"

// Copies data-clipboard-text to the clipboard; briefly shows a "Copied" label.
export default class extends Controller {
  static targets = [ "label" ]
  static values = {
    text: String,
    idleLabel: { type: String, default: "Copy" },
    doneLabel: { type: String, default: "Copied" }
  }

  async copy(event) {
    event.preventDefault()
    const value = this.textValue
    if (!value) return

    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(value)
      } else {
        this.fallbackCopy(value)
      }
      this.flashDone()
    } catch (_err) {
      try {
        this.fallbackCopy(value)
        this.flashDone()
      } catch (_err2) {
        // ignore
      }
    }
  }

  fallbackCopy(value) {
    const input = document.createElement("textarea")
    input.value = value
    input.setAttribute("readonly", "")
    input.style.position = "fixed"
    input.style.opacity = "0"
    document.body.appendChild(input)
    input.select()
    document.execCommand("copy")
    document.body.removeChild(input)
  }

  flashDone() {
    if (!this.hasLabelTarget) return
    this.labelTarget.textContent = this.doneLabelValue
    clearTimeout(this._resetTimer)
    this._resetTimer = setTimeout(() => {
      this.labelTarget.textContent = this.idleLabelValue
    }, 1500)
  }
}
