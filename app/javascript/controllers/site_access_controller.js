import { Controller } from "@hotwired/stimulus"

// Toggle Site access card between view and edit modes.
export default class extends Controller {
  static targets = [ "view", "form" ]
  static values = {
    editing: { type: Boolean, default: false }
  }

  connect() {
    this.render()
  }

  edit(event) {
    event.preventDefault()
    this.editingValue = true
  }

  cancel(event) {
    event.preventDefault()
    this.editingValue = false
  }

  editingValueChanged() {
    this.render()
  }

  render() {
    this.viewTargets.forEach((el) => {
      el.hidden = this.editingValue
    })
    this.formTargets.forEach((el) => {
      el.hidden = !this.editingValue
    })
  }
}
