# Manage job statistics
module JobStats
  class << self
    attr_accessor :job_count, :job_time, :jobs_enqueued, :best_hash
  end

  ActiveSupport::Notifications.subscribe "perform.active_job" do |name, started, finished, unique_id, data|
    duration = finished - started
    job_performed duration
    Rails.logger.info "JobStats: perform.active_job ##{JobStats.job_count} took #{duration.round 2}s"
    Rails.logger.debug "Data:\n#{data}"
  end

  ActiveSupport::Notifications.subscribe(/enqueue(_at)?\.active_job/) do |name, started, finished, unique_id, data|
    self.job_enqueued
    Rails.logger.info "JobStats: Enqueued job #{name}"
  end

  ActiveSupport::Notifications.subscribe "demo.hash" do |name, started, finished, unique_id, data|
    Rails.logger.info "JobStats: Got new hash #{data}"
    self.with_stats(true) do |stats|
      count, str, hash = data
      if count > stats.best_hash_count
        Rails.logger.info "JobStats: New best #{count}"
        stats.best_hash_count = count
        stats.best_hash_str = str
        stats.best_hash_hash = hash.inspect  # To avoid encoding problems (sqlite is picky)
      end
    end
  end

  def self.stats
    self.with_stats(false) do |stats|
      stats
    end    
  end

  private

  def self.job_enqueued
    self.with_stats(true) do |stats|
      stats.jobs_enqueued += 1
    end
  end

  def self.job_performed(duration)
    self.with_stats(true) do |stats|
      stats.job_count += 1
      stats.job_time += duration
    end
  end

  def self.with_stats(save=false)
    ActiveRecord::Base.transaction do
      stats = JobStat.first
      if stats.nil?
        stats = JobStat.new
        stats.job_time = 0.0
        stats.job_count = 0
        stats.jobs_enqueued = 0
        stats.best_hash_count = 0
        stats.best_hash_str = ""
        stats.best_hash_hash = ""
      end
      result = yield stats
      stats.save if save
      result
    end
  end

end
