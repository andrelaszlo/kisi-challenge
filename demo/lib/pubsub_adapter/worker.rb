require 'pry'

module ActiveJob::PubSub
  class Worker
    using PubsubExtension

    ##
    # @param [Google::Cloud::PubSub] pubsub PubSub client. Optional.
    # @param [Symbol, String] queue Queue to read messages from. Default is `:default`
    def initialize(pubsub=Google::Cloud::PubSub.new, queue: :default)
      @pubsub = pubsub
      @threads = {
        callback: ActiveJob::PubSub::PubSubAdapter.config_item(:worker_threads),
        push: ActiveJob::PubSub::PubSubAdapter.config_item(:ack_threads)
      }
      @queue = queue
    end

    ##
    # Start processing jobs
    def process_jobs
      Rails.logger.info "Waiting for jobs in the '#{@queue}' queue"
      sub = @pubsub.get_or_create_subscription(@queue)
      subscriber = sub.listen(threads: @threads) do |received_message|
        job_data = JSON.load(received_message.data)
        Rails.logger.info "Processing job #{job_data}"

        begin
          ActiveJob::Base.execute job_data
        rescue Exception => err  # Catching all here, because a worker should be robust against any errors
          # The job failed, increment executions counter and re-enqueue it
          begin
            Rails.logger.warn "Job failed: #{err.inspect}"
            job = ActiveJob::Base.deserialize job_data
            job.executions += 1
            job.class.perform_later job
            Rails.logger.info "Re-enqueued failed job after #{job.executions} attempt(s)"
            # Only ack the failed job after successfully re-enqueueing it
            received_message.acknowledge!
          rescue Exception => error_handling_err
            Rails.warn "An error occured while handling a failed job, "\
                       "this job will not be acked and retried according to "\
                       "the pubsub subscription's parameters: #{error_handling_err}"
          end
        else
          received_message.acknowledge!
        end

      end
      subscriber.start
      sleep
    end
  end
end
