require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Demo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end

  # TODO: Store this somewhere else, just for testing
  @stats = ActiveSupport::Cache::MemoryStore.new({size: 1.megabytes})

  def self.stats
    @stats
  end

  class JobStats
    class << self
      attr_accessor :job_count, :job_time, :jobs_enqueued
    end
    @job_count = 0
    @job_time = 0.0
    @jobs_enqueued = 0
  end

  ActiveSupport::Notifications.subscribe "perform.active_job" do |name, started, finished, unique_id, data|
    duration = finished - started
    JobStats.job_count += 1
    JobStats.job_time += duration
    Rails.logger.info "perform.active_job ##{JobStats.job_count} took #{duration.round 2}s"
  end

  ActiveSupport::Notifications.subscribe(/enqueue(_at)?\.active_job/) do |name, started, finished, unique_id, data|
    JobStats.jobs_enqueued += 1
    Rails.logger.info "Enqueued job #{name}"
  end

end
