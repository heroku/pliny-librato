require "librato/metrics"
require "concurrent"
require "pliny/error_reporters"

module Pliny::Librato
  module Metrics
    class Backend
      include Concurrent::Async

      def initialize(source: nil)
        super()
        @source = source
      end

      def report_counts(counts)
        self.async._report_counts(counts)
      end

      def report_measures(measures)
        self.async._report_measures(measures)
      end

      def _report_counts(counts)
        ::Librato::Metrics.submit(expand(:counter, counts))
      rescue => error
        Pliny::ErrorReporters.notify(error)
      end

      def _report_measures(measures)
        ::Librato::Metrics.submit(expand(:gauge, measures))
      rescue => error
        Pliny::ErrorReporters.notify(error)
      end

      private

      attr_reader :librato_client, :source

      def expand(type, metrics)
        metrics.reduce({}) do |mets, (k, v)|
          mets[k] = { type: type, value: v, source: source }
          mets
        end
      end
    end
  end
end
