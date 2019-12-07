require_relative 'boot'

require 'rails/all'

# This module needs to be loaded early since it subscribes to ActiveSupport notifications
require_relative '../lib/job_stats.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Demo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # TODO: Change to pubsub adapter
    Rails.application.config.active_job.queue_adapter = :delayed_job

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
