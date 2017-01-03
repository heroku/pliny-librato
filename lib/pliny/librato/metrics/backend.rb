require 'librato/metrics'
require 'pliny/error_reporters'

module Pliny
  module Librato
    module Metrics
      # Implements the Pliny::Metrics.backends API. Puts any metrics sent
      # from Pliny::Metrics onto a queue that gets submitted in batches.
      class Backend
        POISON_PILL = :'❨╯°□°❩╯︵┻━┻'

        def initialize(source: nil, interval: 10, count: 500, **opts)
          @metrics_queue = opts.fetch(:metrics_queue, Queue.new)
          @librato_queue = opts.fetch(:librato_queue,
                                      ::Librato::Metrics::Queue.new(
                                        source:              source,
                                        autosubmit_interval: interval,
                                        autosubmit_count:    count
                                      ))
        end

        def report_counts(counts)
          metrics_queue.push(counts)
        end

        def report_measures(measures)
          metrics_queue.push(measures)
        end

        def start
          start_thread
          Signal.trap('TERM') { stop }
          self
        end

        def stop
          metrics_queue.push(POISON_PILL)
          thread.join
        end

        private

        attr_reader :librato_queue, :metrics_queue, :thread

        def start_thread
          @thread = Thread.new 'pliny-librato-metrics-processor' do
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
          librato_queue.add(msg)
        rescue => error
          Pliny::ErrorReporters.notify(error)
        end

        def flush_librato
          librato_queue.submit
        rescue => error
          Pliny::ErrorReporters.notify(error)
        end
      end
    end
  end
end
