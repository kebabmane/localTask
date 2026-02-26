class TaskDependency < ApplicationRecord
  belongs_to :task
  belongs_to :dependency, class_name: "Task"

  enum :dependency_type, { blocks: 0, relates_to: 1 }

  validates :dependency_id, uniqueness: { scope: :task_id }
  validate :no_self_dependency
  validate :no_circular_dependency

  private

  def no_self_dependency
    errors.add(:dependency, "cannot depend on itself") if task_id == dependency_id
  end

  def no_circular_dependency
    return unless dependency
    if dependency.dependencies.include?(task)
      errors.add(:dependency, "would create a circular dependency")
    end
  end
end
