# frozen_string_literal: true

##
# Add convenience methods for getting or creating topics and subscriptions.

module ActiveJob
  module PubSub
    module PubsubExtension
      refine Google::Cloud::Pubsub::Project do
        ##
        # Get or create the topic associated with a queue
        # @param [Symbol, String] queue Queue name
        def get_or_create_topic(queue)
          prefix = ActiveJob::PubSub::PubSubAdapter.config_item :queue_prefix
          topic_name = "#{prefix}#{queue}"
          begin
            # Potential race condition here: if two processes fails to get
            # the topic, then tries to create it at the same time it may
            # already exist for one of them - hence the error handling.
            topic(topic_name) || create_topic(topic_name)
          rescue Google::Cloud::AlreadyExistsError
            topic(topic_name)
          end
        end

        # Get or create the subscription associated with a queue.
        # Since all workers share one subscription, this is an instance of
        # the "competing consumers" pattern.
        # @param [Symbol, String] queue Queue name
        def get_or_create_subscription(queue)
          prefix = ActiveJob::PubSub::PubSubAdapter.config_item :subscription_prefix
          deadline = ActiveJob::PubSub::PubSubAdapter.config_item :ack_deadline
          retention = ActiveJob::PubSub::PubSubAdapter.config_item :retention
          sub_name = "#{prefix}#{queue}"
          begin
            subscription(sub_name) ||
              get_or_create_topic(queue).subscribe(sub_name, deadline: deadline, retention: retention)
          rescue Google::Cloud::AlreadyExistsError
            subscription(sub_name)
          end
        end
      end
    end
  end
end
