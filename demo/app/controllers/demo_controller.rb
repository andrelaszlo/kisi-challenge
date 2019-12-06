require 'pry'

class DemoController < ApplicationController
  def index
    # binding.pry
    @job_count = Demo::JobStats.job_count
    @job_time = Demo::JobStats.job_time
    @jobs_enqueued = Demo::JobStats.jobs_enqueued
    @jobs_in_queue = @jobs_enqueued - @job_count
  end

  def start_job()
    num_jobs = params[:num_jobs].to_i
    Rails.logger.info "Starting #{num_jobs} new jobs"
    num_jobs.times do
      DemoJob.perform_later
    end
    redirect_back(fallback_location: '/')
  end
end
