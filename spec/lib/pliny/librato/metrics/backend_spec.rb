require "spec_helper"

RSpec.describe Pliny::Librato::Metrics::Backend do
  subject(:source)     { "myapp.production" }
  subject(:backend)    { described_class.new(source: source) }
  let(:async_reporter) { double("AsyncReporter", report: true) }


  describe "#report_counts" do
    it "delegates to async.report" do
      expect(backend).to receive(:async).and_return(async_reporter)
      expect(async_reporter).to receive(:report).once.with(
        'pliny.foo' => 1
      )

      backend.report_counts('pliny.foo' => 1)
    end
  end

  describe "#report_measures" do
    it "delegates to async.report" do
      expect(backend).to receive(:async).and_return(async_reporter)
      expect(async_reporter).to receive(:report).once.with(
        'pliny.foo' => 1.002
      )

      backend.report_measures('pliny.foo' => 1.002)
    end

  end

  describe "#report" do
    it "reports a single count to librato" do
      expect(Librato::Metrics).to receive(:submit).with(
        'pliny.foo' => { value: 1, type: :gauge, source: source }
      )

      backend.report('pliny.foo' => 1)
    end

    it "reports multiple counts to librato" do
      expect(Librato::Metrics).to receive(:submit).with(
        'pliny.foo' => { value: 1, type: :gauge, source: source },
        'pliny.bar' => { value: 2, type: :gauge, source: source }
      )

      backend.report('pliny.foo' => 1, 'pliny.bar' => 2)
    end

    it "reports errors via the error reporter" do
      error = StandardError.new(message: "Something went wrong")
      allow(Librato::Metrics).to receive(:submit).and_raise(error)
      expect(Pliny::ErrorReporters).to receive(:notify).with(error)

      backend.report("pliny.boom" => 1)
    end
  end
end
