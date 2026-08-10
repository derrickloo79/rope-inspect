import { Controller } from "@hotwired/stimulus"

// Modal document viewer for certificate files (PDF / images).
// Open via: data-action="doc-viewer#open"
//   data-doc-viewer-url-param, data-doc-viewer-name-param,
//   data-doc-viewer-type-param, data-doc-viewer-download-url-param
export default class extends Controller {
  static targets = [ "dialog", "title", "body", "download", "close" ]

  connect() {
    this._onKeydown = this._onKeydown.bind(this)
  }

  disconnect() {
    this.unlockScroll()
    document.removeEventListener("keydown", this._onKeydown)
  }

  open(event) {
    event.preventDefault()

    const url = event.params.url
    const name = event.params.name || "Document"
    const type = event.params.type || ""
    const downloadUrl = event.params.downloadUrl || url

    if (!url) return

    this._downloadUrl = downloadUrl
    this._name = name

    if (this.hasTitleTarget) this.titleTarget.textContent = name
    if (this.hasDownloadTarget) {
      this.downloadTarget.href = downloadUrl
      this.downloadTarget.setAttribute("download", name)
    }

    this.renderBody(url, name, type, downloadUrl)

    this.dialogTarget.hidden = false
    this.lockScroll()
    document.addEventListener("keydown", this._onKeydown)

    if (this.hasCloseTarget) this.closeTarget.focus()
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    if (this.hasBodyTarget) this.bodyTarget.innerHTML = ""
    this.unlockScroll()
    document.removeEventListener("keydown", this._onKeydown)
  }

  backdropClose(event) {
    if (event.target === event.currentTarget) this.close(event)
  }

  renderBody(url, name, type, downloadUrl) {
    if (!this.hasBodyTarget) return
    this.bodyTarget.innerHTML = ""

    const isImage = type.startsWith("image/") || /\.(jpe?g|png|gif|webp)$/i.test(name)
    const isPdf = type === "application/pdf" || /\.pdf$/i.test(name)

    if (isImage) {
      const img = document.createElement("img")
      img.src = url
      img.alt = name
      img.className = "doc-viewer__image"
      this.bodyTarget.appendChild(img)
      return
    }

    if (isPdf) {
      const frame = document.createElement("iframe")
      frame.src = url
      frame.title = name
      frame.className = "doc-viewer__frame"
      this.bodyTarget.appendChild(frame)
      return
    }

    const fallback = document.createElement("div")
    fallback.className = "doc-viewer__fallback"

    const text = document.createElement("p")
    text.className = "doc-viewer__fallback-text"
    text.textContent = "Preview is not available for this file type."

    const link = document.createElement("a")
    link.className = "btn-secondary"
    link.href = downloadUrl
    link.setAttribute("download", name)
    link.textContent = "Download file"

    fallback.append(text, link)
    this.bodyTarget.appendChild(fallback)
  }

  lockScroll() {
    document.documentElement.classList.add("doc-viewer-open")
  }

  unlockScroll() {
    document.documentElement.classList.remove("doc-viewer-open")
  }

  _onKeydown(event) {
    if (event.key === "Escape") this.close(event)
  }
}
