##
# Add convenience methods for getting or creating topics and subscriptions.

module ActiveJob::PubSub
  module PubsubExtension
    refine Google::Cloud::Pubsub::Project do
      ##
      # Get or create the topic associated with a queue
      # @param [Symbol, String] queue Queue name
      def get_or_create_topic(queue)
        topic_name = "activejob-#{queue}"
        begin
          # Potential race condition here: if two processes fails to get
          # the topic, then tries to create it at the same time it may
          # already exist for one of them - hence the error handling.
          topic(topic_name) || create_topic(topic_name)
        rescue Google::Cloud::AlreadyExistsError
          topic(topic_name)
        end
        # TODO: not receiving messages ok
      end

      # Get or create the subscription associated with a queue.
      # Since all workers share one subscription, this is an instance of
      # the "competing consumers" pattern.
      # @param [Symbol, String] queue Queue name
      def get_or_create_subscription(queue)
        sub_name = "activejob-subscription-#{queue}"
        begin
          subscription(sub_name) || get_or_create_topic(queue).subscribe(sub_name)
        rescue Google::Cloud::AlreadyExistsError
          subscription(sub_name)
        end
      end
    end
  end
end
