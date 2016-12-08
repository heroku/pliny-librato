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
        self.async.report(counts)
      end

      def report_measures(measures)
        self.async.report(measures)
      end

      def report(metrics)
        ::Librato::Metrics.submit(serialize(metrics))
      rescue => error
        Pliny::ErrorReporters.notify(error)
      end

      private

      attr_reader :librato_client, :source

      def serialize(metrics)
        metrics.reduce({}) do |mets, (k, v)|
          mets[k] = { type: :gauge, value: v, source: source }
          mets
        end
      end
    end
  end
end
