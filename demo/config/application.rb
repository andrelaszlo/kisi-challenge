require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# This module needs to be loaded early since it subscribes to ActiveSupport notifications
require_relative '../lib/job_stats.rb'

require_relative '../lib/google_pubsub_adapter.rb'

module Demo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # TODO: Change to pubsub adapter
    Rails.application.config.active_job.queue_adapter = :google_pubsub

    #Google::Cloud::PubSub.configure do |config|
      #config.project_id  = "fake-project-id"
      #config.credentials = "path/to/keyfile.json"
    #end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
