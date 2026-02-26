import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    // Auto-dismiss after 5 seconds
    this.messageTargets.forEach(msg => {
      setTimeout(() => {
        msg.classList.add("transition-opacity", "duration-300", "opacity-0")
        setTimeout(() => msg.remove(), 300)
      }, 5000)
    })
  }

  dismiss(event) {
    const msg = event.currentTarget.closest("[data-flash-target='message']")
    msg.classList.add("transition-opacity", "duration-300", "opacity-0")
    setTimeout(() => msg.remove(), 300)
  }
}
