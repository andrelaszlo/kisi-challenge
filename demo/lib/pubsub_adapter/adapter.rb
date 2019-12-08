require "google/cloud/pubsub"
require_relative "pubsub_extension.rb"

module ActiveJob::PubSub
  class PubSubAdapter
    using PubsubExtension

    @@config = {
      # TODO: Use this
      max_retries: 2,
      threads: {},
    }

    def initialize(pubsub=Google::Cloud::PubSub.new)
      # TODO: How to configure easily? (And share config with worker?)
      @pubsub = pubsub
    end

    def enqueue(job)
      puts "*** PubSub #{@pubsub} (#{@pubsub.class})"
      serialized_job = JSON.dump job.serialize  # ActiveJob::Core serializer
      topic = @pubsub.get_or_create_topic(job.queue_name)
      topic.publish serialized_job
      Rails.logger.info "Enqueued #{job} to #{topic}"
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
  end
end

ActiveJob::QueueAdapters::PubSubAdapter = ActiveJob::PubSub::PubSubAdapter
