# frozen_string_literal: true

class Mention < ApplicationRecord
  belongs_to :comment
  belongs_to :mentioned_task, class_name: "Task", optional: true

  validates :mention_type, presence: true, inclusion: { in: %w[agent task] }
  validates :mention_text, presence: true
  validates :agent_identifier, presence: true, if: -> { mention_type == "agent" }
  validates :mentioned_task, presence: true, if: -> { mention_type == "task" }
end
