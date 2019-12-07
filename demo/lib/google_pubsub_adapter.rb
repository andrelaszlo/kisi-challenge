require "google/cloud/pubsub"

module ActiveJob::QueueAdapters
  class GooglePubsubAdapter

    def initialize(pubsub=Google::Cloud::PubSub.new)
      @pubsub = pubsub
    end

    def enqueue(job)
      serialized_job = JSON.dump job.serialize  # ActiveJob::Core serializer
      topic(job.queue_name).publish serialized_job
      puts "Enqueued #{job} to #{topic(job.queue_name)}"
    end

    def enqueue_at(*)
      # Scheduling could be implemented using retries, maybe in a
      # separate queue where a worker just keeps checking if the job
      # deadline has passed.
      raise NotImplementedError, "Scheduled jobs are not supported"
    end

    # Process jobs for a queue
    def process_jobs(name)
      subscriber = subscription(name).listen(threads: {callback: 1}) do |received_message|
        # TODO: Error handling
        job_data = JSON.load(received_message.data)
        ActiveJob::Base.execute job_data
        received_message.acknowledge!
      end
      # Start background threads that will call the block passed to listen.
      subscriber.start
      subscriber
    end

    private

    # Get or create the topic associated with a queue
    def topic(name)
      topic_name = "activejob-#{name}"
      begin
        # Potential race condition here: if two processes fails to get
        # the topic, then tries to create it at the same time it may
        # already exist for one of them - hence the error handling.
        @pubsub.topic(topic_name) || @pubsub.create_topic(topic_name)
      rescue Google::Cloud::AlreadyExistsError
        @pubsub.topic(topic_name)
      end
      # TODO: not receiving messages ok
    end

    # Get or create the subscription associated with a queue.
    # Since all workers share one subscription, this is an instance of
    # the "competing consumers" pattern.
    def subscription(name)
      sub_name = "activejob-subscription-#{name}"
      begin
        @pubsub.subscription(sub_name) || topic(name).subscribe(sub_name)
      rescue Google::Cloud::AlreadyExistsError
        @pubsub.subscription(sub_name)
      end
    end

  end
end
