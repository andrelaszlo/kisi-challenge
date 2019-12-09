require 'google/cloud/pubsub'
require_relative 'pubsub_extension.rb'
require 'pry'

module ActiveJob::PubSub
  class PubSubAdapter
    using PubsubExtension

    @@config = {
      # How many times a job should be retried before it's sent to the deadletter queue
      # The total number of attempts will be max_retries + 1.
      max_retries: 2,
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
      # The maximum number of seconds after a job is started before
      # the worker should acknowledge the message. Integer representing seconds.
      ack_deadline: 1.minute.to_i,
      # How long to retain unacknowledged messages in the queue, from
      # the moment a message is published. (
      retention: 7.days.to_i,
      # How long to wait until trying to execute a job again
      retry_delay: 5.minutes.seconds,
    }

    def initialize(pubsub=Google::Cloud::PubSub.new)
      @pubsub = pubsub
      # TODO: sanity check config times
      if @@config[:retention] > ((@@config[:max_retries]+1) * @@config[:retry_delay].to_i)
        Rails.logger.warn "The configure retention time #{@@config[:rentention]} "\
                          "is lower than the worst case retry time, jobs may be lost"
      end
    end

    def enqueue(job)
      enqueue_at job, 0
    end

    def enqueue_at(job, timestamp)
      queue = job.queue_name

      if job.executions > @@config[:max_retries]
        queue = @@config[:dead_letter_queue]
        Rails.logger.warn "Job permanently failed and will be dead-lettered: #{job.job_id}"
      end

      Rails.logger.debug "Trying to serialize a #{job.class} using serialize method at #{job.method(:serialize).source_location}"
      serialized_job = JSON.dump job.serialize  # ActiveJob::Core serializer
      Rails.logger.debug "Serialized: #{serialized_job}"

      topic = @pubsub.get_or_create_topic(queue)
      topic.publish serialized_job, timestamp: timestamp
      Rails.logger.info "Enqueued #{job.job_id} to #{topic.name}"
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
