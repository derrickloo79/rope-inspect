import { Controller } from "@hotwired/stimulus"

// Dynamic nested crane fields for the public inspection request form.
export default class extends Controller {
  static targets = ["container", "template", "item", "remove"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    this.updateRemoveButtons()
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']")
    if (!item) return

    const destroyInput = item.querySelector("input[name*='_destroy']")
    const idInput = item.querySelector("input[name*='[id]']")
    const persisted = idInput && idInput.value

    if (persisted && destroyInput) {
      destroyInput.value = "1"
      item.classList.add("hidden")
      item.querySelectorAll("[required]").forEach((el) => el.removeAttribute("required"))
      item.querySelectorAll("input, select, textarea").forEach((el) => {
        el.disabled = true
      })
      // Keep the destroy flag enabled so Rails receives it.
      destroyInput.disabled = false
    } else {
      item.remove()
    }

    this.updateRemoveButtons()
  }

  updateRemoveButtons() {
    const visible = this.itemTargets.filter((el) => !el.classList.contains("hidden"))
    const onlyOne = visible.length <= 1

    visible.forEach((el) => {
      const btn = el.querySelector("[data-nested-form-target='remove']")
      if (!btn) return

      btn.disabled = onlyOne
      btn.setAttribute("aria-disabled", onlyOne ? "true" : "false")
      btn.title = onlyOne ? "At least one crane is required" : "Remove crane"
      btn.setAttribute("aria-label", onlyOne ? "Remove crane (disabled — at least one required)" : "Remove crane")
    })
  }

  connect() {
    this.updateRemoveButtons()
  }
}
