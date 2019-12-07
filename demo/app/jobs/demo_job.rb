require 'securerandom'
require 'digest'

class DemoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "In DemoJob perform"
    Rails.logger.info "Performing demo job"

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
