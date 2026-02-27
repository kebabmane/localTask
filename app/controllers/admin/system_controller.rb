module Admin
  class SystemController < BaseController
    include ActionView::Helpers::NumberHelper

    def show
      @ruby_version = RUBY_VERSION
      @rails_version = Rails::VERSION::STRING
      @database = database_info
      @storage = storage_info
      @table_stats = table_stats
      @job_stats = job_stats
      @app_stats = app_stats
    end

    private

    def current_admin_section = :system

    def database_info
      db_path = ActiveRecord::Base.connection_db_config.database
      {
        adapter: "SQLite",
        version: ActiveRecord::Base.connection.select_value("SELECT sqlite_version()"),
        path: db_path,
        size: File.exist?(db_path) ? number_to_human_size(File.size(db_path)) : "N/A",
        journal_mode: ActiveRecord::Base.connection.select_value("PRAGMA journal_mode")
      }
    end

    def storage_info
      storage_dir = Rails.root.join("storage")
      files = Dir.glob(storage_dir.join("**/*")).select { |f| File.file?(f) }
      {
        path: storage_dir.to_s,
        total_files: files.count,
        total_size: number_to_human_size(files.sum { |f| File.size(f) })
      }
    end

    def table_stats
      tables = ActiveRecord::Base.connection.tables.reject { |t| t.start_with?("ar_", "schema_") }
      tables.map do |table|
        count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM \"#{table}\"")
        { name: table, count: count }
      end.sort_by { |t| -t[:count] }
    end

    def job_stats
      {
        ready: safe_count("solid_queue_ready_executions"),
        scheduled: safe_count("solid_queue_scheduled_executions"),
        claimed: safe_count("solid_queue_claimed_executions"),
        failed: safe_count("solid_queue_failed_executions"),
        total_jobs: safe_count("solid_queue_jobs")
      }
    end

    def app_stats
      {
        environment: Rails.env,
        time_zone: Time.zone.name,
        pid: Process.pid,
        memory_mb: `ps -o rss= -p #{Process.pid}`.strip.to_i / 1024
      }
    end

    def safe_count(table_name)
      if ActiveRecord::Base.connection.table_exists?(table_name)
        ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM \"#{table_name}\"")
      end
    end
  end
end
