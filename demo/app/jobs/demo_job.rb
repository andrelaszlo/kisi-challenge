class DemoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Performing demo job"
    work_time = Random.rand * 10
    sleep work_time
    Rails.logger.info "Job done in #{work_time.round 2} seconds"
  end
end
