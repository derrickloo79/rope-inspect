import { Controller } from "@hotwired/stimulus"

// Styled file dropzone: click label or drag-and-drop onto the zone.
// Shows selected files as chips so the user knows what will be uploaded on save.
export default class extends Controller {
  static targets = [ "input", "prompt", "pending", "list" ]

  dragover(event) {
    event.preventDefault()
    this.element.classList.add("is-dragover")
  }

  dragleave(event) {
    // Ignore leave events that stay inside the dropzone (e.g. over child nodes).
    if (event.relatedTarget && this.element.contains(event.relatedTarget)) return
    event.preventDefault()
    this.element.classList.remove("is-dragover")
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("is-dragover")

    const files = event.dataTransfer?.files
    if (!files?.length || !this.hasInputTarget) return

    const incoming = Array.from(files)
    if (this.inputTarget.multiple) {
      const existing = Array.from(this.inputTarget.files || [])
      this.assignFiles([...existing, ...incoming])
    } else {
      this.assignFiles(incoming)
    }
  }

  changed() {
    this.renderPending()
  }

  clear(event) {
    event.preventDefault()
    event.stopPropagation()

    const index = Number(event.params.index)
    if (!this.hasInputTarget) return

    const input = this.inputTarget
    const remaining = Array.from(input.files || []).filter((_, i) => i !== index)
    this.assignFiles(remaining)
  }

  clearAll(event) {
    event.preventDefault()
    event.stopPropagation()
    this.assignFiles([])
  }

  assignFiles(files) {
    const input = this.inputTarget
    const dt = new DataTransfer()
    const list = input.multiple ? files : files.slice(0, 1)

    list.forEach((file) => dt.items.add(file))
    input.files = dt.files
    input.dispatchEvent(new Event("change", { bubbles: true }))
    this.renderPending()
  }

  renderPending() {
    if (!this.hasInputTarget) return

    const files = Array.from(this.inputTarget.files || [])
    const hasFiles = files.length > 0

    this.element.classList.toggle("is-picked", hasFiles)

    if (this.hasPromptTarget) {
      // Single-file: hide the empty prompt once a file is chosen.
      // Multi-file: keep the dropzone so more can be added.
      if (!this.inputTarget.multiple) {
        this.promptTarget.hidden = hasFiles
      }
    }

    if (this.hasPendingTarget) {
      this.pendingTarget.hidden = !hasFiles
    }

    if (this.hasListTarget) {
      this.listTarget.innerHTML = ""
      files.forEach((file, index) => {
        this.listTarget.appendChild(this.buildChip(file, index))
      })
    }
  }

  buildChip(file, index) {
    const chip = document.createElement("div")
    chip.className = "file-chip file-chip--pending"
    chip.setAttribute("data-file-dropzone-target", "chip")

    const name = document.createElement("span")
    name.className = "file-chip__name"
    name.textContent = file.name
    name.title = file.name

    const size = document.createElement("span")
    size.className = "file-chip__size"
    size.textContent = `(${this.formatBytes(file.size)})`

    const status = document.createElement("span")
    status.className = "file-chip__status"
    status.textContent = "Ready to save"

    const remove = document.createElement("button")
    remove.type = "button"
    remove.className = "file-chip__remove"
    remove.setAttribute("aria-label", `Remove ${file.name}`)
    remove.setAttribute("data-action", "file-dropzone#clear")
    remove.setAttribute("data-file-dropzone-index-param", String(index))
    remove.innerHTML =
      '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>'

    chip.append(name, size, status, remove)
    return chip
  }

  formatBytes(bytes) {
    if (!Number.isFinite(bytes) || bytes < 0) return ""
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) {
      const kb = bytes / 1024
      return kb < 10 ? `${kb.toFixed(1)} KB` : `${Math.round(kb)} KB`
    }
    const mb = bytes / (1024 * 1024)
    return mb < 10 ? `${mb.toFixed(1)} MB` : `${Math.round(mb)} MB`
  }
}
