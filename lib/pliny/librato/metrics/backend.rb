require 'librato/metrics'
require 'pliny/error_reporters'

module Pliny
  module Librato
    module Metrics
      # Implements the Pliny::Metrics.backends API. Puts any metrics sent
      # from Pliny::Metrics onto a queue that gets submitted in batches.
      class Backend
        POISON_PILL = :'❨╯°□°❩╯︵┻━┻'.freeze

        def initialize(source: nil, interval: 10, count: 500)
          @source   = source
          @interval = interval
          @count    = count

          start_thread
        end

        def report_counts(counts)
          queue.push(counts)
        end

        def report_measures(measures)
          queue.push(measures)
        end

        def shutdown
          queue.push(POISON_PILL)
          thread
        end

        private

        attr_reader :source, :interval, :count, :thread

        def start_thread
          @thread = Thread.new do
            loop do
              begin
                msg = queue.pop

                if msg == POISON_PILL
                  librato_queue.submit
                  break
                end

                librato_queue.add(msg)
              rescue => error
                Pliny::ErrorReporters.notify(error)
              end
            end
          end
        end

        def librato_queue
          @librato_queue ||= ::Librato::Metrics::Queue.new(
            source:              source,
            autosubmit_interval: interval,
            autosubmit_count:    count
          )
        end

        def queue
          @queue ||= Queue.new
        end
      end
    end
  end
end
