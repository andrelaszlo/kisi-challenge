# frozen_string_literal: true

require 'google/cloud/pubsub'
require_relative 'pubsub_extension.rb'

module ActiveJob
  module PubSub
    class PubSubAdapter
      using PubsubExtension

      @@config = { # rubocop:disable ClassVars
        # How many times a job should be retried before it's sent to the
        # deadletter queue. The total number of attempts will be
        # max_retries + 1.
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
        # Delivery mode, valid options are :at_most_once or :at_least_once
        # At most once: Optimistically ack messages, risking lost jobs
        # (on a worker crash)
        # At least once: Don't ack until the job is successful, risking
        # duplicate jobs (for long-running-jobs)
        delivery_mode: :at_least_once,
      }

      def initialize(pubsub = Google::Cloud::PubSub.new)
        @pubsub = pubsub
        if @@config[:retention] > ((@@config[:max_retries]+1) * @@config[:retry_delay].to_i)
          Rails.logger.warn "The configure retention time #{@@config[:rentention]} "\
                            "is lower than the worst case retry time, jobs may be lost"
        end

        if @@config[:ack_deadline] < 30.seconds && @@config[delivery_mode] == :at_least_once
          Rails.logger.warn 'When "at-least-once" delivery (pessimistic acking) is '\
                            'set, make sure to have an ack deadline longer than '\
                            'the time it takes to run a job.'
        end
      end

      def enqueue(job)
        enqueue_at job, 0
      end

      def enqueue_at(job, timestamp)
        queue = job.queue_name

        if job.executions > @@config[:max_retries]
          queue = @@config[:dead_letter_queue]
          Rails.logger.warn "Job permanently failed and will be dead-lettered: "\
                            "#{job.job_id}"
        end

        serialized_job = JSON.dump job.serialize # ActiveJob::Core serializer

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
end

ActiveJob::QueueAdapters::PubSubAdapter = ActiveJob::PubSub::PubSubAdapter
