import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, copiedText: String, defaultText: String, errorText: String }
  static targets = ["button"]

  async copyToClipboard() {
    await navigator.clipboard.writeText(this.urlValue)
    .then(() => {
      this.changeButtonText(this.copiedTextValue)
    })
    .catch((error) => {
      this.changeButtonText(this.errorTextValue)
    })
  }

  changeButtonText(newText) {
    this.buttonTarget.textContent = newText
    this.timeoutId = setTimeout(() => {
      this.buttonTarget.textContent = this.urlValue
    }, 2000)
  }

  disconnect() {
    clearTimeout(this.timeoutId)
  }

}