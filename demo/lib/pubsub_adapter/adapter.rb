require 'google/cloud/pubsub'
require_relative 'pubsub_extension.rb'
require 'pry'

module ActiveJob::PubSub
  class PubSubAdapter
    using PubsubExtension

    @@config = {
      # How many times a job should be retried before it's sent to the deadletter queue
      # The total number of attempts will be max_retries + 1.
      max_retries: 3,
      # Name of the deadletter/morgue queue
      dead_letter_queue: 'deadletter',
      # String prefix to add to topics (queues)
      queue_prefix: 'activejob-',
      # String prefix to add to subscription names
      subscription_prefix: 'activejob-subscription-',
      # The number of threads used to handle received messages
      worker_threads: 8,
      # The number of threads to handle acks and nacks
      ack_threads: 4,
    }

    def initialize(pubsub=Google::Cloud::PubSub.new)
      @pubsub = pubsub
    end

    def enqueue(job)
      puts "*** PubSub #{@pubsub} (#{@pubsub.class})"

      queue = job.queue_name
      if job.executions > @@config[:max_retries]
        queue = @@config[:dead_letter_queue]
        Rails.logger.warn "Job permanently failed and will be dead-lettered: #{job.job_id}"
      end

      serialized_job = JSON.dump job.serialize  # ActiveJob::Core serializer

      topic = @pubsub.get_or_create_topic(queue)
      topic.publish serialized_job
      Rails.logger.info "Enqueued #{job.job_id} to #{topic.name}"
    end

    def enqueue_at(*)
      # Scheduling could be implemented using retries, maybe in a
      # separate queue where a worker just keeps checking if the job
      # deadline has passed.
      raise NotImplementedError, "Scheduled jobs are not supported"
    end

    def self.configure
      yield @@config
    end

    def self.config_item(item)
      @@config[item]
    end
  end
end

ActiveJob::QueueAdapters::PubSubAdapter = ActiveJob::PubSub::PubSubAdapter
