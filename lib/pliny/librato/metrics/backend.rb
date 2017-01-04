require 'librato/metrics'
require 'pliny/error_reporters'

module Pliny
  module Librato
    module Metrics
      # Implements the Pliny::Metrics.backends API. Puts any metrics sent
      # from Pliny::Metrics onto a queue that gets submitted in batches.
      class Backend
        POISON_PILL = :'❨╯°□°❩╯︵┻━┻'

        def initialize(source: nil, interval: 10, count: 500)
          @source   = source
          @interval = interval
          @count    = count
        end

        def report_counts(counts)
          metrics_queue.push(counts)
        end

        def report_measures(measures)
          metrics_queue.push(measures)
        end

        def start
          start_thread
          self
        end

        def stop
          metrics_queue.push(POISON_PILL)
          thread.join
        end

        private

        attr_reader :source, :interval, :count, :thread

        def start_thread
          @thread = Thread.new do
            loop do
              msg = metrics_queue.pop
              break unless process(msg)
            end
          end
        end

        def process(msg)
          if msg == POISON_PILL
            flush_librato
            false
          else
            enqueue_librato(msg)
            true
          end
        end

        def enqueue_librato(msg)
          with_error_report { librato_queue.add(msg) }
        end

        def flush_librato
          with_error_report { librato_queue.submit }
        end

        def with_error_report
          yield
        rescue => error
          Pliny::ErrorReporters.notify(error)
        end

        def metrics_queue
          @metrics_queue ||= Queue.new
        end

        def librato_queue
          @librato_queue ||= ::Librato::Metrics::Queue.new(
            source:              source,
            autosubmit_interval: interval,
            autosubmit_count:    count
          )
        end
      end
    end
  end
end
