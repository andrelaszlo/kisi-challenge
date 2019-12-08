namespace :jobs do
  desc 'Start a Google PubSub ActiveJob worker.'
  task :work => :environment_options do
    Rails.logger.info "Starting worker"
    puts ActiveJob::PubSub::Worker.class
    ActiveJob::PubSub::Worker.new(**@options).process_jobs
  end

  task :environment_options => :environment do
    @options = {}
    @options[:queue] = ENV["WORKER_QUEUE"] if ENV["WORKER_QUEUE"]
  end

  desc 'Log to stdout'
  task :to_stdout => [:environment] do
    Rails.logger = Logger.new(STDOUT)
  end
end
