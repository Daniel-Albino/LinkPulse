// =============================================================================
// app/javascript/controllers/flash_controller.js
// Stimulus controller to auto-dismiss flash messages.
// Usage: data-controller="flash" data-flash-timeout-value="5000"
// =============================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 5000 }
  }

  connect() {
    // Auto-dismiss after timeout
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-8px)"
    setTimeout(() => this.element.remove(), 300)
  }
}
