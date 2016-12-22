require 'librato/metrics'
require 'pliny/error_reporters'

module Pliny
  module Librato
    module Metrics
      # Implements the Pliny::Metrics.backends API. Puts any metrics sent
      # from Pliny::Metrics onto a queue that gets submitted in batches.
      class Backend
        TERMINATE = "TERMINATE".freeze

        def initialize(source: nil, interval: 60, count: 500)
          @source   = source
          @interval = interval
          @count    = count

          process_in_thread
          flush_on_shutdown
        end

        def report_counts(counts)
          report(counts)
        end

        def report_measures(measures)
          report(measures)
        end

        private

        attr_reader :source, :interval, :count, :thread

        def report(metrics)
          queue.push([metrics, false])
        end

        def process_in_thread
          @thread = Thread.new do
            librato_queue = initialize_librato_queue

            loop do
              begin
                metrics, terminate = queue.pop
                puts metrics, terminate

                librato_queue.add(metrics) if metrics

                if terminate
                  librato_queue.submit
                  thread.exit
                end
              rescue => error
                puts error
                Pliny::ErrorReporters.notify(error)
              end
            end

          end

          # TODO: this is not called when we're already inside a thread.
          # This is pretty problematic since Puma and Tonitrus both use
          # threads.
          Signal.trap('TERM') do
            # Send a signal to submit any pending metrics and then wait for it
            # to exit
            queue.push([nil, true])
            thread.join
            exit
          end
        end

        def initialize_librato_queue
          ::Librato::Metrics::Queue.new(
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
