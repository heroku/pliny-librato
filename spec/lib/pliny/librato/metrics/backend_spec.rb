require 'spec_helper'

RSpec.describe Pliny::Librato::Metrics::Backend do
  let(:source)        { 'myapp.production' }
  let(:interval)      { 1 }
  let(:count)         { 5 }
  let(:librato_queue) { instance_double(Librato::Metrics::Queue) }
  let(:metrics)       { { 'foo.bar' => 1, baz: 2 } }

  subject(:backend) do
    described_class.new(
      count:    count,
      interval: interval,
      source:   source
    )
  end


  describe '#initialize' do
    it 'creates a Librato::Metrics::Queue' do
      expect(Librato::Metrics::Queue).to receive(:new).with(
        autosubmit_count:    count,
        autosubmit_interval: interval,
        source:              source
      ).and_call_original

      expect(backend.send(:librato_queue))
        .to be_an_instance_of(Librato::Metrics::Queue)
    end

    it 'creates a new Queue' do
      expect(Queue).to receive(:new).and_call_original

      expect(backend.send(:metrics_queue)).to be_an_instance_of(Queue)
    end
  end

  shared_examples 'a metrics reporter' do
    before do
      allow(librato_queue).to receive(:submit)
      allow(librato_queue).to receive(:add)
      allow(backend).to receive(:librato_queue).and_return(librato_queue)
      backend.start
    end

    after do
      backend.stop
    end

    it 'adds the metrics the librato_queue' do
      expect(librato_queue).to receive(:add).with(metrics)
      backend.send(method, metrics)
    end
  end

  describe '#report_counts' do
    let(:method) { :report_counts }
    it_should_behave_like 'a metrics reporter'
  end

  describe '#report_measures' do
    let(:method) { :report_measures }
    it_should_behave_like 'a metrics reporter'
  end

  describe '#start' do
    after do
      backend.stop
    end

    it 'creates a new thread' do
      expect(Thread).to receive(:new).and_call_original
      backend.start
      expect(backend.send(:thread)).to be_a(Thread)
    end
  end

  describe '#stop' do
    before do
      allow(backend).to receive(:librato_queue).and_return(librato_queue)
      backend.start
    end

    it 'flushes the librato queue' do
      expect(librato_queue).to receive(:submit)
      backend.stop
    end
  end
end
