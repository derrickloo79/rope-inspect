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

    const persisted = Boolean(this.idInputFor(item)?.value)
    if (persisted && !window.confirm(this.confirmMessage(item))) return

    this.removeItem(item)
  }

  removeItem(item) {
    const destroyInput = item.querySelector("input[name*='_destroy']")
    const idInput = this.idInputFor(item)
    const persisted = idInput && idInput.value

    if (persisted && destroyInput) {
      destroyInput.value = "1"
      item.classList.add("hidden")
      item.querySelectorAll("[required]").forEach((el) => el.removeAttribute("required"))
      item.querySelectorAll("input, select, textarea").forEach((el) => {
        el.disabled = true
      })
      // Rails needs both id and _destroy to delete an existing nested record.
      destroyInput.disabled = false
      idInput.disabled = false
    } else {
      item.remove()
    }

    this.updateRemoveButtons()
  }

  confirmMessage(item) {
    const lm = (item.querySelector("[data-request-form-steps-target='craneLm']")?.value || "").trim()
    const typeSelect = item.querySelector("select")
    const type = typeSelect?.selectedOptions?.[0]?.text?.trim()
    const label = [ type && type !== "Select type" ? type : null, lm ? `LM ${lm}` : null ].filter(Boolean).join(" · ")
    const who = label ? `this crane (${label})` : "this crane"

    return `Are you sure you wish to remove ${who}?\n\n` +
      "Any LM or mill certificates already uploaded for it will be deleted when you save."
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

  // fields_for may emit id inside the row or as the next sibling.
  idInputFor(item) {
    return item.querySelector("input[name*='[id]']") ||
      (item.nextElementSibling?.matches?.("input[name*='[id]']") ? item.nextElementSibling : null)
  }
}
