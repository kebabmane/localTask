class Project < ApplicationRecord
  belongs_to :user
  has_many :task_statuses, -> { order(position: :asc) }, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :project_members, dependent: :destroy
  has_many :members, through: :project_members, source: :user

  acts_as_list

  validates :name, presence: true
  validates :prefix, presence: true, uniqueness: true, length: { maximum: 5 },
                     format: { with: /\A[A-Z][A-Z0-9]*\z/, message: "must be uppercase letters/numbers" }
  validates :color, presence: true

  after_create :create_default_statuses

  scope :active, -> { where(archived: false) }

  def next_task_number
    (tasks.maximum(:task_number) || 0) + 1
  end

  # Authorization helpers — project creator is always an implicit owner
  def can_view?(user)
    user_id == user.id || project_members.exists?(user_id: user.id)
  end

  def can_edit?(user)
    user_id == user.id || project_members.where(user_id: user.id, role: [:editor, :owner]).exists?
  end

  def can_manage?(user)
    user_id == user.id || project_members.where(user_id: user.id, role: :owner).exists?
  end

  private

  def create_default_statuses
    default_statuses = [
      { name: "Planning",    color: "#a78bfa", position: 1 },
      { name: "Backlog",     color: "#94a3b8", position: 2, is_default: true },
      { name: "In Progress", color: "#60a5fa", position: 3 },
      { name: "With Agent",  color: "#f59e0b", position: 4 },
      { name: "Tested",      color: "#34d399", position: 5 },
      { name: "Done",        color: "#22c55e", position: 6, is_closed: true }
    ]
    task_statuses.create!(default_statuses)
  end
end
