# frozen_string_literal: true

class MentionParser
  # @LT-3 → task reference (uppercase PREFIX-NUMBER)
  TASK_MENTION_REGEX = /@([A-Z][A-Z0-9]*-\d+)/

  # @claude-code → agent mention (lowercase with hyphens/underscores)
  AGENT_MENTION_REGEX = /@([a-z][a-z0-9_-]*)/

  def self.parse(comment)
    new(comment).parse
  end

  def initialize(comment)
    @comment = comment
    @body = comment.body.to_s
  end

  def parse
    parse_task_mentions
    parse_agent_mentions
  end

  private

  def parse_task_mentions
    @body.scan(TASK_MENTION_REGEX).flatten.uniq.each do |display_id|
      prefix, number = display_id.split("-", 2)
      project = Project.find_by(prefix: prefix)
      next unless project

      task = project.tasks.find_by(task_number: number.to_i)
      next unless task

      @comment.mentions.create!(
        mention_type: "task",
        mention_text: "@#{display_id}",
        mentioned_task: task
      )

      ::NotificationService.task_cross_referenced(@comment, task)
    end
  end

  def parse_agent_mentions
    # Remove already-matched task mentions to avoid false positives
    remaining = @body.gsub(TASK_MENTION_REGEX, "")
    remaining.scan(AGENT_MENTION_REGEX).flatten.uniq.each do |agent_name|
      @comment.mentions.create!(
        mention_type: "agent",
        mention_text: "@#{agent_name}",
        agent_identifier: agent_name
      )

      ::NotificationService.agent_mentioned(@comment, agent_name)
    end
  end
end
