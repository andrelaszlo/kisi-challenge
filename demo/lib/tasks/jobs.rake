namespace :jobs do
  desc 'Start a Google PubSub ActiveJob worker.'
  task :work => :environment_options do
    Rails.logger.info "Starting worker"
    puts ActiveJob::PubSub::Worker.class
    # TODO: options
    ActiveJob::PubSub::Worker.new().process_jobs
  end

  task :environment_options => :environment do
    Rails.logger.info "Getting env options"
  end

  desc 'Log to stdout'
  task :to_stdout => [:environment] do
    Rails.logger = Logger.new(STDOUT)
  end

end
