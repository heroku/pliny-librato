require "librato/metrics"
require "concurrent"

module Pliny::Librato
  module Metrics
    class Backend
      include Concurrent::Async

      def report_counts(counts)
        self.async._report_counts(counts)
      end

      def report_measures(measures)
        self.async._report_measures(measures)
      end

      def _report_counts(counts)
        ::Librato::Metrics.submit(counters: expand_metrics(counts))
      end

      def _report_measures(measures)
        ::Librato::Metrics.submit(gauges: expand_metrics(measures))
      end

      private

      attr_reader :librato_client

      def expand_metrics(metrics)
        metrics.map do |k, v|
          { name: k, value: v }
        end
      end
    end
  end
end
