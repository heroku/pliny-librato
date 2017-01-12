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
          start_counter
          start_timer
          self
        end

        def stop
          metrics_queue.push(POISON_PILL)
          timer.terminate
          counter.join
          flush_librato
        end

        private

        attr_reader :source, :interval, :count, :timer, :counter

        def start_timer
          @timer = Thread.new do
            loop do
              sleep interval
              flush_librato
            end
          end
        end

        def start_counter
          @counter = Thread.new do
            loop do
              msg = metrics_queue.pop
              msg == POISON_PILL ? break : enqueue_librato(msg)
            end
          end
        end

        def enqueue_librato(msg)
          sync { librato_queue.add(msg) }
        end

        def flush_librato
          sync { librato_queue.submit }
        end

        def sync(&block)
          mutex.synchronize(&block)
        rescue => error
          Pliny::ErrorReporters.notify(error)
        end

        def mutex
          @mutex ||= Mutex.new
        end

        def metrics_queue
          @metrics_queue ||= Queue.new
        end

        def librato_queue
          @librato_queue ||= ::Librato::Metrics::Queue.new(
            source:           source,
            autosubmit_count: count
          )
        end
      end
    end
  end
end
