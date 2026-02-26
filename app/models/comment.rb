class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :user, optional: true

  has_many_attached :attachments

  enum :comment_type, { comment: 0, status_change: 1, system: 2 }

  validates :body, presence: true

  broadcasts_to :task

  def author_name
    if user.present?
      user.name
    elsif agent_identifier.present?
      agent_identifier.titleize
    else
      "System"
    end
  end

  def from_agent?
    agent_identifier.present?
  end
end
