import { Controller } from "@hotwired/stimulus"

// Collapsible sticky schedule dock (mobile Variation B).
// Peek: summary + Mark scheduled. Expand: full form fields.
export default class extends Controller {
  static targets = ["panel", "summary", "summaryText", "chevron", "toggle"]
  static classes = ["expanded"]
  static values = {
    emptyLabel: { type: String, default: "Set schedule" }
  }

  connect() {
    // Open by default so staff can fill schedule immediately.
    this.expand()
    this.refreshSummary()
  }

  toggle(event) {
    event.preventDefault()
    if (this.isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.element.classList.add(this.expandedClass)
    if (this.hasPanelTarget) this.panelTarget.hidden = false
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "true")
    }
  }

  collapse() {
    // Desktop: keep expanded (CSS handles layout; still keep panel visible).
    if (this.isDesktop()) {
      this.element.classList.add(this.expandedClass)
      if (this.hasPanelTarget) this.panelTarget.hidden = false
      return
    }

    this.element.classList.remove(this.expandedClass)
    if (this.hasPanelTarget) this.panelTarget.hidden = true
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }

  // Called when validation fails so user can fix fields.
  openForEdit() {
    if (!this.isDesktop()) this.expand()
  }

  refreshSummary() {
    if (!this.hasSummaryTextTarget) return

    const dateInput = this.element.querySelector('[name="inspection_request[scheduled_on]"]')
    const dateValue = (dateInput?.value || "").trim()
    const timeInput = this.element.querySelector(
      'input[name="inspection_request[scheduled_time]"]:checked'
    )
    const timeValue = timeInput?.value || ""
    const inspector = (
      this.element.querySelector('[name="inspection_request[assigned_inspector]"]')?.value || ""
    ).trim()

    if (!dateValue && !timeValue && !inspector) {
      this.summaryTextTarget.textContent = this.emptyLabelValue
      return
    }

    const parts = []
    if (dateValue) {
      parts.push(this.formatDateLabel(dateValue))
    }
    if (timeValue) parts.push(timeValue)
    if (inspector) parts.push(inspector)

    this.summaryTextTarget.textContent = parts.join(" · ")
  }

  formatDateLabel(isoDate) {
    // isoDate is Y-m-d from the form / flatpickr → e.g. "25 Jul, 26"
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoDate)
    if (!match) return isoDate

    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    const year = match[1].slice(-2)
    const month = months[Number(match[2]) - 1]
    const day = String(Number(match[3]))
    if (!month) return isoDate

    return `${day} ${month}, ${year}`
  }

  isDesktop() {
    return window.matchMedia("(min-width: 1024px)").matches
  }

  get isExpanded() {
    return this.element.classList.contains(this.expandedClass)
  }
}
