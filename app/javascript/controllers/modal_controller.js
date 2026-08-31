import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.beforeCache = this.closeIfOpen.bind(this) // Bind the method to the controller instance
    addEventListener("turbo:before-cache", this.beforeCache)
  }

  open() {
    this.modalTarget.showModal()
  }

  close() {
    this.modalTarget.close()
  }

  disconnect() {
    this.closeIfOpen()
    removeEventListener("turbo:before-cache", this.beforeCache)
  }

  // Close the modal if it's open when the page is cached (e.g., when navigating back)
  closeIfOpen() {
    if (this.hasModalTarget && this.modalTarget.open) {
      this.close()
    }
  }

  // Close the modal when clicking on the backdrop
  backdropClose(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}