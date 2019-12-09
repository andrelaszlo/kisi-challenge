class DemoController < ApplicationController
  def index()
    @stats = JobStats.stats
  end

  def start_job()
    num_jobs = params[:num_jobs].to_i
    Rails.logger.info "Starting #{num_jobs} new jobs"
    num_jobs.times do
      DemoJob.perform_later
    end
    redirect_back(fallback_location: '/')
  end

  def delayed_job()
    Rails.logger.info "Starting a job in five minutes"
    DemoJob.set(wait: 5.minutes).perform_later
    redirect_back(fallback_location: '/')
  end

  def fail_job()
    Rails.logger.info "Starting a failing job"
    DemoJob.perform_later fail:true
    redirect_back(fallback_location: '/')
  end
end
