class CommentSerializer
  def initialize(comment)
    @comment = comment
  end

  def as_json(*)
    {
      id: @comment.id,
      body: @comment.body,
      author: @comment.author_name,
      comment_type: @comment.comment_type,
      agent_identifier: @comment.agent_identifier,
      created_at: @comment.created_at.iso8601
    }
  end
end
