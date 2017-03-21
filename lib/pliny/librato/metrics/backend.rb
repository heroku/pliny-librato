require 'librato/metrics'
require 'pliny/error_reporters'
require 'librato/collector'

module Pliny
  module Librato
    module Metrics
      # Implements the Pliny::Metrics.backends API. Puts any metrics sent
      # from Pliny::Metrics onto a queue that gets submitted in batches.
      class Backend
        def initialize(source: nil, interval: 60)
          @interval      = interval
          @mutex         = Mutex.new
          @counter_cache = ::Librato::Collector::CounterCache.new(default_tags: nil)
          @aggregator    = ::Librato::Metrics::Aggregator.new
          @librato_queue = ::Librato::Metrics::Queue.new(
            source: source,
            skip_measurement_times: true
          )
        end

        def report_counts(counts)
          sync do
            counts.each do |name, val|
              counter_cache.increment(name, val)
            end
          end
        end

        def report_measures(measures)
          sync do
            aggregator.add(measures)
          end
        end

        def start
          start_timer
          self
        end

        def stop
          # Ensure timer is not running when we terminate it
          sync { timer.terminate }
          flush_librato
        end

        private

        attr_reader :interval, :timer, :counter_cache, :aggregator, :librato_queue

        def start_timer
          @timer = Thread.new do
            loop do
              sleep interval
              flush_librato
            end
          end
        end

        def flush_librato
          sync do
            counter_cache.flush_to(librato_queue)
            librato_queue.merge!(aggregator)
            aggregator.clear
          end
          librato_queue.submit
        end

        def sync(&block)
          @mutex.synchronize(&block)
        rescue => error
          Pliny::ErrorReporters.notify(error)
        end
      end
    end
  end
end
