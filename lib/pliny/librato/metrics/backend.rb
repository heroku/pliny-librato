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
          @source        = source
          @interval      = interval
          @mutex         = Mutex.new
          @counter_cache = ::Librato::Collector::CounterCache.new(default_tags: nil)
          @aggregator    = ::Librato::Metrics::Aggregator.new
        end

        def new_librato_queue
          ::Librato::Metrics::Queue.new(
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

        attr_reader :source, :interval, :timer, :counter_cache, :aggregator

        def start_timer
          @timer = Thread.new do
            loop do
              sleep interval
              flush_librato
            end
          end
        end

        def flush_librato
          queue = new_librato_queue

          sync do
            # Gather all counters / measures from the aggregator / counter_cache.
            counter_cache.flush_to(queue)
            queue.merge!(aggregator)
            aggregator.clear
          end

          # Submit explicitly, given the queue won't pass autosubmit_check
          # (because @autosubmit_count=nil @autosubmit_interval=nil)
          queue.submit
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
