require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @task = tasks(:one)
    @comment = comments(:one)
    sign_in_as(@user)
  end

  # --- CREATE ---

  test "create comment as owner" do
    assert_difference "Comment.count", 1 do
      post project_task_comments_path(@project, @task), params: {
        comment: { body: "A new comment" }
      }
    end
    assert_redirected_to project_task_path(@project, @task)
  end

  test "create comment as editor" do
    sign_in_as(users(:two))
    assert_difference "Comment.count", 1 do
      post project_task_comments_path(@project, @task), params: {
        comment: { body: "Editor comment" }
      }
    end
    assert_redirected_to project_task_path(@project, @task)
  end

  test "create comment with blank body fails" do
    assert_no_difference "Comment.count" do
      post project_task_comments_path(@project, @task), params: {
        comment: { body: "" }
      }
    end
    assert_redirected_to project_task_path(@project, @task)
  end

  # --- DESTROY ---

  test "destroy comment" do
    assert_difference "Comment.count", -1 do
      delete project_task_comment_path(@project, @task, @comment)
    end
    assert_redirected_to project_task_path(@project, @task)
  end

  # --- AUTHORIZATION ---

  test "non-member cannot create comment" do
    other_project = projects(:two)
    post project_task_comments_path(other_project, @task), params: {
      comment: { body: "Unauthorized" }
    }
    assert_response :not_found
  end

  test "viewer cannot create comment" do
    project_two = projects(:two)
    project_two.project_members.create!(user: @user, role: :viewer)
    sign_in_as(@user)

    # Need a task that belongs to project_two
    two_backlog = task_statuses(:two_backlog)
    task_in_two = project_two.tasks.create!(
      title: "Test Task", priority: :medium,
      task_status: two_backlog, creator: users(:two)
    )

    assert_no_difference "Comment.count" do
      post project_task_comments_path(project_two, task_in_two), params: {
        comment: { body: "Viewer comment" }
      }
    end
    assert_response :redirect
  end
end
