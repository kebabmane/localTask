class Task < ApplicationRecord
  belongs_to :project
  belongs_to :task_status
  belongs_to :creator, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :deleted_by, class_name: "User", optional: true, foreign_key: :deleted_by_id

  has_many :comments, -> { order(created_at: :asc) }, dependent: :destroy
  has_many :agent_notifications, dependent: :destroy
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
  after_save :record_field_changes, unless: :new_record_previously?
  after_save :set_completed_at
  after_save :notify_agent_assigned, if: :agent_identifier_changed_to_present?

  broadcasts_to :project

  # Soft delete: exclude deleted tasks by default
  default_scope { where(deleted_at: nil) }

  scope :with_deleted, -> { unscope(where: :deleted_at) }
  scope :only_deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
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

  def deleted?
    deleted_at.present?
  end

  def soft_delete(user: nil, agent: nil)
    update_columns(
      deleted_at: Time.current,
      deleted_by_id: user&.id,
      deleted_by_agent: agent
    )
  end

  def restore!
    update_columns(deleted_at: nil, deleted_by_id: nil, deleted_by_agent: nil)
  end

  private

  # Track which fields were previously unchanged (for new records)
  def new_record_previously?
    saved_change_to_id?
  end

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

    ::NotificationService.status_changed(self, old_status.name, new_status.name)
  end

  AUDITED_FIELDS = %w[title description priority due_date assignee_id agent_identifier].freeze

  def record_field_changes
    changed_fields = saved_changes.slice(*AUDITED_FIELDS)
    return if changed_fields.empty?

    changed_fields.each do |field, (old_value, new_value)|
      message = audit_message_for(field, old_value, new_value)
      next unless message

      comments.create!(
        body: message,
        user: Current.user,
        comment_type: :system
      )
    end
  end

  def audit_message_for(field, old_value, new_value)
    case field
    when "title"
      "Title changed from \"#{old_value}\" to \"#{new_value}\""
    when "description"
      "Description updated"
    when "priority"
      old_name = self.class.priorities.key(old_value) || old_value
      new_name = self.class.priorities.key(new_value) || new_value
      "Priority changed from **#{old_name}** to **#{new_name}**"
    when "due_date"
      if new_value.present?
        "Due date set to **#{new_value}**"
      else
        "Due date removed"
      end
    when "assignee_id"
      if new_value.present?
        assignee_name = User.find_by(id: new_value)&.name || "Unknown"
        "Assigned to **#{assignee_name}**"
      else
        "Unassigned"
      end
    when "agent_identifier"
      # Skip if this is handled by notify_agent_assigned (first assignment)
      return nil if old_value.blank?
      "Agent changed from **#{old_value}** to **#{new_value.presence || 'none'}**"
    end
  end

  def agent_identifier_changed_to_present?
    saved_change_to_agent_identifier? && agent_identifier.present?
  end

  def notify_agent_assigned
    ::NotificationService.task_assigned(self)
  end

  def set_completed_at
    if task_status.is_closed? && completed_at.nil?
      update_column(:completed_at, Time.current)
    elsif !task_status.is_closed? && completed_at.present?
      update_column(:completed_at, nil)
    end
  end
end
