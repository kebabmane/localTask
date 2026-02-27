# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_27_060516) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_notifications", force: :cascade do |t|
    t.string "agent_identifier", null: false
    t.integer "comment_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.text "message", null: false
    t.json "payload"
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_identifier", "read", "created_at"], name: "idx_agent_notifications_unread"
    t.index ["comment_id"], name: "index_agent_notifications_on_comment_id"
    t.index ["task_id"], name: "index_agent_notifications_on_task_id"
  end

  create_table "agent_webhooks", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "agent_identifier", null: false
    t.datetime "created_at", null: false
    t.json "event_types"
    t.integer "failures", default: 0, null: false
    t.datetime "last_delivered_at"
    t.datetime "last_failed_at"
    t.string "secret"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["agent_identifier", "active"], name: "idx_agent_webhooks_active_agent"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "prefix", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["prefix"], name: "index_api_tokens_on_prefix"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "agent_identifier"
    t.string "agent_session_id"
    t.text "body", null: false
    t.integer "comment_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["task_id", "created_at"], name: "index_comments_on_task_id_and_created_at"
    t.index ["task_id"], name: "index_comments_on_task_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "mentions", force: :cascade do |t|
    t.string "agent_identifier"
    t.integer "comment_id", null: false
    t.datetime "created_at", null: false
    t.string "mention_text", null: false
    t.string "mention_type", null: false
    t.integer "mentioned_task_id"
    t.datetime "updated_at", null: false
    t.index ["agent_identifier"], name: "index_mentions_on_agent_identifier"
    t.index ["comment_id"], name: "index_mentions_on_comment_id"
    t.index ["mentioned_task_id"], name: "index_mentions_on_mentioned_task_id"
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.string "color", default: "#6366f1", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon", default: "folder"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "prefix", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["position"], name: "index_projects_on_position"
    t.index ["prefix"], name: "index_projects_on_prefix", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "task_dependencies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dependency_id", null: false
    t.integer "dependency_type", default: 0, null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dependency_id"], name: "index_task_dependencies_on_dependency_id"
    t.index ["task_id", "dependency_id"], name: "index_task_dependencies_on_task_id_and_dependency_id", unique: true
    t.index ["task_id"], name: "index_task_dependencies_on_task_id"
  end

  create_table "task_statuses", force: :cascade do |t|
    t.string "color", default: "#94a3b8", null: false
    t.datetime "created_at", null: false
    t.boolean "is_closed", default: false, null: false
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "name"], name: "index_task_statuses_on_project_id_and_name", unique: true
    t.index ["project_id", "position"], name: "index_task_statuses_on_project_id_and_position"
    t.index ["project_id"], name: "index_task_statuses_on_project_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "agent_identifier"
    t.string "agent_session_id"
    t.integer "assignee_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "creator_id", null: false
    t.text "description"
    t.date "due_date"
    t.integer "position", default: 0, null: false
    t.integer "priority", default: 1, null: false
    t.integer "project_id", null: false
    t.integer "task_number", null: false
    t.integer "task_status_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_identifier"], name: "index_tasks_on_agent_identifier"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["creator_id"], name: "index_tasks_on_creator_id"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["priority"], name: "index_tasks_on_priority"
    t.index ["project_id", "task_number"], name: "index_tasks_on_project_id_and_task_number", unique: true
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["task_status_id", "position"], name: "index_tasks_on_task_status_id_and_position"
    t.index ["task_status_id"], name: "index_tasks_on_task_status_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_color", default: "#6366f1"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_notifications", "comments"
  add_foreign_key "agent_notifications", "tasks"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "comments", "tasks"
  add_foreign_key "comments", "users"
  add_foreign_key "mentions", "comments"
  add_foreign_key "mentions", "tasks", column: "mentioned_task_id"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "task_dependencies", "tasks"
  add_foreign_key "task_dependencies", "tasks", column: "dependency_id"
  add_foreign_key "task_statuses", "projects"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "task_statuses"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "tasks", "users", column: "creator_id"
end
