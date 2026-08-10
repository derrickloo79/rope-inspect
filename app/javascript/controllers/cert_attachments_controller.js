import { Controller } from "@hotwired/stimulus"

// Marks existing certificate files for removal before form submit, and shows
// the Save button only when there are pending uploads or deletions.
export default class extends Controller {
  static targets = [
    "lmChip",
    "lmDropzone",
    "removeLmInput",
    "millChip",
    "removeMillInput",
    "save"
  ]

  connect() {
    this.refresh()
  }

  removeLm(event) {
    event.preventDefault()

    if (this.hasLmChipTarget) {
      this.lmChipTarget.hidden = true
    }
    if (this.hasRemoveLmInputTarget) {
      this.removeLmInputTarget.value = "1"
    }
    if (this.hasLmDropzoneTarget) {
      this.lmDropzoneTarget.classList.remove("hidden")
    }

    this.refresh()
  }

  removeMill(event) {
    event.preventDefault()

    const fileId = String(event.params.fileId || "")
    const chip = event.currentTarget.closest(".file-chip")
    if (chip) chip.hidden = true

    this.removeMillInputTargets.forEach((input) => {
      if (String(input.value) === fileId) {
        input.checked = true
      }
    })

    this.refresh()
  }

  // Called on bubbled change events (file inputs) and after remove actions.
  refresh() {
    if (!this.hasSaveTarget) return
    this.saveTarget.hidden = !this.isDirty()
  }

  isDirty() {
    const fileInputs = this.element.querySelectorAll('input[type="file"]')
    for (const input of fileInputs) {
      if (input.files && input.files.length > 0) return true
    }

    if (this.hasRemoveLmInputTarget && this.removeLmInputTarget.value === "1") {
      return true
    }

    return this.removeMillInputTargets.some((input) => input.checked)
  }
}
