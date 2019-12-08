module ActiveJob::PubSub
  class Worker
    using PubsubExtension

    ##
    # @param [Google::Cloud::PubSub] pubsub PubSub client. Optional.
    # @param [Hash] threads The number of threads to create to handle
    #   concurrent calls by each stream opened by the subscriber. Optional.
    #
    #   Hash keys and values may include the following:
    #
    #     * `:callback` (Integer) The number of threads used to handle the
    #       received messages. Default is 8.
    #     * `:push` (Integer) The number of threads to handle
    #       acknowledgement ({ReceivedMessage#ack!}) and modify ack deadline
    #       messages ({ReceivedMessage#nack!},
    #       {ReceivedMessage#modify_ack_deadline!}). Default is 4.
    # @param [Symbol, String] queue Queue to read messages from. Default is `:default`
    def initialize(pubsub=Google::Cloud::PubSub.new, threads={}, queue=:default)
      @pubsub = pubsub
      @threads = threads
      @queue = queue
    end

    ##
    # Start processing jobs
    def process_jobs
      Rails.logger.info "Waiting for jobs in the '#{@queue}' queue"
      sub = @pubsub.get_or_create_subscription(@queue)
      subscriber = sub.listen(threads: @threads) do |received_message|
        # TODO: Error handling
        job_data = JSON.load(received_message.data)
        Rails.logger.info "Processing job #{job_data}"
        ActiveJob::Base.execute job_data
        received_message.acknowledge!
      end
      subscriber.start
      sleep
    end
  end
end
