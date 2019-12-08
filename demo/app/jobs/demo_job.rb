require 'securerandom'
require 'digest'

class DemoJob < ApplicationJob
  queue_as :default

  # Random errors
  @@job_errors = [
    LocalJumpError.new("'Aaaahh...', this job jumped too far."),
    SecurityError.new("I'm sorry, Dave. I'm afraid I can't do that."),
    NoMemoryError.new("This job... uh... sorry where am I?"),
    # https://www.youtube.com/watch?v=z5_1AO4zVBM
    ZeroDivisionError.new("12 plus 9 is 21, adding up numbers is very fun. "\
                         "7 plus 8 equal 15, adding up numbers is very uplifting. "\
                         "1 divided by 0 is...")
  ]

  def perform(*args, **kwargs)
    Rails.logger.info "Performing demo job"

    # This job can fail in strange ways, just pass fail:true
    if kwargs[:fail]
      raise @@job_errors.sample
    end

    best = 0, "", ""
    10000.times do
      zeroes, str, hash = mine
      if ([zeroes, str, hash] <=> best) > 0
        best = zeroes, str, hash
      end
    end
    ActiveSupport::Notifications.instrument "demo.hash", best

    Rails.logger.info "Job done, best hash found had #{best[0]} leading zeroes"
  end

  private

  # "Mine" kisicoins, ie find strings that have as many leading zeroes as possible.
  def mine()
    str = SecureRandom.alphanumeric 64
    hash = Digest::SHA256.digest str

    # Count leading zeroes
    zeroes = 0
    hash.bytes.each do |byte|
      mask = 0b10000000
      while mask != 0
        if byte & mask != 0
          return zeroes, str, hash
        end
        zeroes += 1
        mask >>= 1
      end
    end
  end
end
