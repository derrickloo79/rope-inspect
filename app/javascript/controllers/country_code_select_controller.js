import { Controller } from "@hotwired/stimulus"

// Native <select>: show only "+65" when closed; full "Singapore (+65)" while open.
// Option nodes carry data-short / data-full from the server.
export default class extends Controller {
  static targets = [ "select" ]

  connect() {
    this.collapseSelected()
  }

  // Expand labels before the browser paints the open list.
  expand() {
    this.eachOption((opt) => {
      if (opt.dataset.full) opt.textContent = opt.dataset.full
    })
  }

  // After pick / blur: selected option shows short code only.
  collapseSelected() {
    this.eachOption((opt) => {
      if (!opt.dataset.short) return
      opt.textContent = opt.selected ? opt.dataset.short : (opt.dataset.full || opt.dataset.short)
    })
  }

  eachOption(fn) {
    Array.from(this.selectTarget.options).forEach(fn)
  }
}
