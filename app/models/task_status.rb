class TaskStatus < ApplicationRecord
  belongs_to :project
  has_many :tasks, dependent: :restrict_with_error

  acts_as_list scope: :project

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :color, presence: true

  scope :ordered, -> { order(position: :asc) }
  scope :default_status, -> { where(is_default: true) }
  scope :closed_statuses, -> { where(is_closed: true) }
end
