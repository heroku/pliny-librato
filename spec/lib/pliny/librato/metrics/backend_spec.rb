require 'spec_helper'

RSpec.describe Pliny::Librato::Metrics::Backend do
  let(:source)   { 'myapp.production' }
  let(:interval) { 1 }
  let(:count)    { 5 }
  let(:queue)    { double('queue') }
  let(:metrics)  { { 'foo.bar' => 1, baz: 2 } }

  subject(:backend) do
    described_class.new(
      count:    count,
      interval: interval,
      source:   source,
      queue:    queue
    )
  end

  describe '#initialize' do
    context 'without a provided queue' do
      let(:queue) { nil }

      it 'creates a Librato::Metrics::Queue' do
        expect(Librato::Metrics::Queue).to receive(:new).with(
          autosubmit_count:    count,
          autosubmit_interval: interval,
          source:              source
        ).and_call_original

        expect(backend.queue).to be_an_instance_of(Librato::Metrics::Queue)
      end
    end
  end

  shared_examples 'a metrics reporter' do
    it 'delegates to queue.add' do
      expect(queue).to receive(:add).with(metrics)
      backend.send(method, metrics)
    end

    it 'reports errors' do
      error = StandardError.new(message: 'Something went wrong')
      allow(queue).to receive(:add).and_raise(error)

      expect(Pliny::ErrorReporters).to receive(:notify).with(error)

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
end
