import { Controller } from "@hotwired/stimulus"

// Phone / contact fields: keep only 0–9. Blocks letters as they are typed or pasted.
export default class extends Controller {
  filter() {
    const input = this.element
    const cleaned = input.value.replace(/\D/g, "")
    if (input.value !== cleaned) input.value = cleaned
  }
}
