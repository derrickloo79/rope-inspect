import { Controller } from "@hotwired/stimulus"

// Public request form: step 1 (details + cranes) → step 2 (optional certificates).
export default class extends Controller {
  static targets = [
    "step1Panel",
    "stepper",
    "stepItem",
    "craneItem",
    "craneDetails",
    "craneDocs",
    "craneSummary",
    "craneType",
    "craneLm",
    "craneRemove",
    "craneSectionTitle",
    "craneSectionHint",
    "addCrane",
    "step1Actions",
    "step2Actions",
    "stepError"
  ]

  static values = {
    step: { type: Number, default: 1 }
  }

  connect() {
    this.render()
  }

  next(event) {
    event.preventDefault()
    if (!this.validateStep1()) return
    this.stepValue = 2
    this.refreshSummaries()
    this.render()
    this.scrollToTop()
  }

  back(event) {
    event.preventDefault()
    this.stepValue = 1
    this.render()
    this.scrollToTop()
  }

  filePicked(event) {
    // Soft feedback: list selected file names under the input when present.
    const input = event.target
    if (!(input instanceof HTMLInputElement) || input.type !== "file") return

    let list = input.parentElement?.querySelector("[data-file-names]")
    if (!list) {
      list = document.createElement("p")
      list.dataset.fileNames = "true"
      list.className = "field-hint mt-1"
      input.insertAdjacentElement("afterend", list)
    }

    const names = Array.from(input.files || []).map((f) => f.name)
    list.textContent = names.length ? `Selected: ${names.join(", ")}` : ""
  }

  stepValueChanged() {
    this.render()
  }

  render() {
    const onStep1 = this.stepValue === 1

    if (this.hasStep1PanelTarget) this.step1PanelTarget.hidden = !onStep1
    if (this.hasStep1ActionsTarget) this.step1ActionsTarget.hidden = !onStep1
    if (this.hasStep2ActionsTarget) this.step2ActionsTarget.hidden = onStep1
    if (this.hasAddCraneTarget) this.addCraneTarget.hidden = !onStep1

    this.craneDetailsTargets.forEach((el) => {
      el.hidden = !onStep1
    })
    this.craneDocsTargets.forEach((el) => {
      el.hidden = onStep1
    })
    this.craneRemoveTargets.forEach((el) => {
      el.hidden = !onStep1
    })

    if (this.hasCraneSectionTitleTarget) {
      this.craneSectionTitleTarget.textContent = onStep1
        ? "Cranes to inspect"
        : "Upload certificates by crane"
    }
    if (this.hasCraneSectionHintTarget) {
      this.craneSectionHintTarget.textContent = onStep1
        ? "Add rope diameter in this order: Single / Main / Boom."
        : "Please upload the LM certificate (1 file) and any Mill certificates (1 or more files) for each crane if you have them. These documents are optional — you can still submit your request and send them later."
    }

    this.updateStepper()

    // Required attributes only apply on step 1 (hidden fields must not block submit).
    this.element.querySelectorAll("[data-request-form-steps-target='craneDetails'] [required], [data-request-form-steps-target='step1Panel'] [required]").forEach((el) => {
      if (onStep1) {
        if (el.dataset.wasRequired === "true" || el.required) {
          el.required = true
          el.dataset.wasRequired = "true"
        }
      } else {
        if (el.required) el.dataset.wasRequired = "true"
        el.required = false
      }
    })

    this.clearStepError()
  }

  updateStepper() {
    const current = this.stepValue
    this.stepItemTargets.forEach((item) => {
      const n = Number(item.dataset.step)
      item.classList.toggle("is-active", n === current)
      item.classList.toggle("is-complete", n < current)
      item.setAttribute("aria-current", n === current ? "step" : "false")
    })
  }

  refreshSummaries() {
    this.craneItemTargets.forEach((item, index) => {
      if (item.classList.contains("hidden")) return

      const typeSelect = item.querySelector("[data-request-form-steps-target='craneType']")
      const lmInput = item.querySelector("[data-request-form-steps-target='craneLm']")
      const summary = item.querySelector("[data-request-form-steps-target='craneSummary']")
      if (!summary) return

      const typeLabel =
        typeSelect?.selectedOptions?.[0]?.text?.trim() ||
        typeSelect?.value ||
        "Crane"
      const lm = (lmInput?.value || "").trim() || "No LM number"
      summary.textContent = `Crane ${index + 1} · ${typeLabel} · ${lm}`
    })
  }

  validateStep1() {
    const required = this.element.querySelectorAll(
      "[data-request-form-steps-target='step1Panel'] [required], [data-request-form-steps-target='craneDetails'] [required]"
    )
    for (const el of required) {
      if (el.disabled) continue
      if (el.closest(".hidden")) continue
      if (!el.checkValidity()) {
        el.reportValidity()
        this.showStepError("Please complete the required fields before continuing.")
        return false
      }
    }

    const visibleCranes = this.craneItemTargets.filter((el) => !el.classList.contains("hidden"))
    if (visibleCranes.length === 0) {
      this.showStepError("Please add at least one crane.")
      return false
    }

    this.clearStepError()
    return true
  }

  showStepError(message) {
    if (!this.hasStepErrorTarget) return
    this.stepErrorTarget.hidden = false
    this.stepErrorTarget.classList.remove("hidden")
    this.stepErrorTarget.textContent = message
  }

  clearStepError() {
    if (!this.hasStepErrorTarget) return
    this.stepErrorTarget.hidden = true
    this.stepErrorTarget.classList.add("hidden")
    this.stepErrorTarget.textContent = ""
  }

  scrollToTop() {
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
