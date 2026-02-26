class Task < ApplicationRecord
  belongs_to :project
  belongs_to :task_status
  belongs_to :creator, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true

  has_many :comments, -> { order(created_at: :asc) }, dependent: :destroy
  has_many :task_dependencies, dependent: :destroy
  has_many :dependencies, through: :task_dependencies, source: :dependency
  has_many :inverse_task_dependencies, class_name: "TaskDependency", foreign_key: :dependency_id, dependent: :destroy
  has_many :dependents, through: :inverse_task_dependencies, source: :task

  has_many_attached :attachments

  acts_as_list scope: :task_status_id

  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }

  validates :title, presence: true
  validates :task_number, presence: true, uniqueness: { scope: :project_id }

  before_validation :set_task_number, on: :create
  after_save :record_status_change, if: :saved_change_to_task_status_id?
  after_save :set_completed_at

  broadcasts_to :project

  scope :ordered, -> { order(position: :asc) }
  scope :open, -> { joins(:task_status).where(task_statuses: { is_closed: false }) }
  scope :closed, -> { joins(:task_status).where(task_statuses: { is_closed: true }) }
  scope :by_agent, ->(identifier) { where(agent_identifier: identifier) }

  def display_id
    "#{project.prefix}-#{task_number}"
  end

  def blocked?
    dependencies.joins(:task_status).where(task_statuses: { is_closed: false }).exists?
  end

  private

  def set_task_number
    self.task_number ||= project&.next_task_number
  end

  def record_status_change
    old_status = TaskStatus.find_by(id: task_status_id_before_last_save)
    new_status = task_status
    return if old_status.nil?

    comments.create!(
      body: "Status changed from **#{old_status.name}** to **#{new_status.name}**",
      user: Current.user,
      comment_type: :status_change
    )
  end

  def set_completed_at
    if task_status.is_closed? && completed_at.nil?
      update_column(:completed_at, Time.current)
    elsif !task_status.is_closed? && completed_at.present?
      update_column(:completed_at, nil)
    end
  end
end
