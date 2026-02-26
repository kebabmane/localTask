import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["column", "card"]
  static values = { projectId: Number }

  connect() {
    this.cardTargets.forEach(card => {
      card.addEventListener("dragstart", this.dragStart.bind(this))
      card.addEventListener("dragend", this.dragEnd.bind(this))
    })

    this.columnTargets.forEach(column => {
      column.addEventListener("dragover", this.dragOver.bind(this))
      column.addEventListener("dragleave", this.dragLeave.bind(this))
      column.addEventListener("drop", this.drop.bind(this))
    })
  }

  dragStart(event) {
    event.dataTransfer.setData("text/plain", event.target.dataset.taskId)
    event.dataTransfer.effectAllowed = "move"
    event.target.classList.add("opacity-50", "rotate-2")
  }

  dragEnd(event) {
    event.target.classList.remove("opacity-50", "rotate-2")
    this.columnTargets.forEach(col => col.classList.remove("bg-indigo-50", "ring-2", "ring-indigo-300"))
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.classList.add("bg-indigo-50", "ring-2", "ring-indigo-300")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("bg-indigo-50", "ring-2", "ring-indigo-300")
  }

  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("bg-indigo-50", "ring-2", "ring-indigo-300")

    const taskId = event.dataTransfer.getData("text/plain")
    const newStatusId = event.currentTarget.dataset.statusId
    const cards = [...event.currentTarget.querySelectorAll("[data-task-id]")]
    const position = this.calculatePosition(event, cards)

    const csrfToken = document.querySelector("[name='csrf-token']")?.content

    fetch(`/projects/${this.projectIdValue}/tasks/${taskId}/position`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({
        task_status_id: newStatusId,
        position: position
      })
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
      }
    })
  }

  calculatePosition(event, existingCards) {
    if (existingCards.length === 0) return 1

    const mouseY = event.clientY
    for (let i = 0; i < existingCards.length; i++) {
      const rect = existingCards[i].getBoundingClientRect()
      const midY = rect.top + rect.height / 2
      if (mouseY < midY) return i + 1
    }
    return existingCards.length + 1
  }
}
