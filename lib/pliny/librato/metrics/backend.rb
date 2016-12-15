require 'librato/metrics'
require 'pliny/error_reporters'

module Pliny::Librato
  module Metrics
    class Backend
      attr_reader :queue

      def initialize(source: nil, interval: 60, count: 1000, queue: nil)
        @queue = queue || Librato::Metrics::Queue.new(
          source:              source,
          autosubmit_interval: interval,
          autosubmit_count:    count
        )
        flush_on_shutdown
      end

      def report_counts(counts)
        report(counts)
      end

      def report_measures(measures)
        report(measures)
      end

      private

      def report(metrics)
        queue.add(metrics)
      rescue => error
        Pliny::ErrorReporters.notify(error)
      end

      def flush_on_shutdown
        Signal.trap('TERM') { queue.submit }
      end
    end
  end
end
