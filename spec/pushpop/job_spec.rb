require 'spec_helper'

describe Pushpop::Job do

  let (:empty_job) { Pushpop::Job.new('foo') do end }
  let (:empty_step) { Pushpop::Step.new('bar') do end }

  describe '#register_plugins' do
    it 'registers a plugin' do
      Pushpop::Job.register_plugin('blaz', Class)
      expect(Pushpop::Job.plugins['blaz']).to eq(Class)
    end
  end

  describe '#initialize' do
    it 'sets a name and evaluate a block' do
      block_ran = false
      job = Pushpop::Job.new('foo') do block_ran = true end
      expect(job.name).to eq('foo')
      expect(job.period).to be_nil
      expect(job.every_options).to eq({})
      expect(block_ran).to be_truthy
    end

    it 'auto-generates a name' do
      job = Pushpop::Job.new do end
      expect(job.name).not_to be_nil
    end
  end

  describe '#every' do
    it 'sets period and options' do
      job = empty_job
      job.every(10.seconds, at: '01:02')
      expect(job.period).to eq(10)
      expect(job.every_options).to eq({ at: '01:02' })
    end
  end

  describe '#webhook' do
    it 'sets the webhook url and proc' do
      job = empty_job
      empty_proc = Proc.new{}
      job.webhook('/test', &empty_proc)
      expect(job.webhook_url).to eq('/test')
      expect(job.webhook_proc.class).to be(Proc)
    end

    it 'raises an error if webhook is already set' do
      job = empty_job
      job.webhook('/test1')
      expect{ job.webhook('/test2') }.to raise_error(RuntimeError)
    end

    it 'raises an error if any steps have been created' do
      job = empty_job
      empty_proc = Proc.new{}
      job.step('test', &empty_proc)
      expect{job.webhook('/test')}.to raise_error(RuntimeError)
    end
  end

  describe '#step' do
    it 'adds the step to the internal list of steps' do
      empty_proc = Proc.new {}
      job = empty_job
      job.step('blah', &empty_proc)
      expect(job.steps.first.name).to eq('blah')
      expect(job.steps.first.block).to eq(empty_proc)
    end

    context 'plugin specified' do
      class FakeStep < Pushpop::Step
      end

      before do
        Pushpop::Job.register_plugin('blaz', FakeStep)
      end

      it 'uses the registered plugin to instantiate the class' do
        empty_proc = Proc.new {}
        job = empty_job
        job.step('blah', 'blaz', &empty_proc)
        expect(job.steps.first.name).to eq('blah')
        expect(job.steps.first.plugin).to eq('blaz')
        expect(job.steps.first.class).to eq(FakeStep)
        expect(job.steps.first.block).to eq(empty_proc)
      end

      it 'throws an exception for an unregistered plugin' do
        empty_proc = Proc.new {}
        job = empty_job
        expect {
          job.step('blah', 'blaze', &empty_proc)
        }.to raise_error /No plugin configured/
      end
    end
  end

  describe '#add_step' do
    let(:job) { empty_job }
    let(:empty_proc) { Proc.new {} }

    context 'no existing steps' do
      it 'adds a step' do
        step = Pushpop::Step.new('step1', 'blaz', &empty_proc)
        job.add_step(step)

        expect(job.steps.length).to eq(1)
        expect(job.steps.first.name).to eq(step.name)
      end
    end

    context 'with existing steps' do
      let(:step) { Pushpop::Step.new('step1', 'blaz', &empty_proc) }

      before(:each) do
        job.add_step(step)
      end

      it 'adds a step' do
        step_two = Pushpop::Step.new('step2', 'blaz', &empty_proc)
        job.add_step(step_two)

        expect(job.steps.length).to eq(2)
        expect(job.steps.first.name).to eq(step.name)
        expect(job.steps.last.name).to eq(step_two.name)
      end

      it 'raises for duplicate step names' do
        expect {
          job.add_step(step)
        }.to raise_error(Pushpop::DuplicateStepNameError)
      end
    end
  end

  describe '#run' do
    it 'calls each step with the response to the previous' do
      job = Pushpop::Job.new('foo') do
        step 'one' do
          10
        end

        step 'two' do |response|
          response + 20
        end
      end
      expect(job.run).to eq([30, { 'one' => 10, 'two' => 30 }])
    end
  end

  describe '#schedule' do
    it 'adds the job to clockwork' do
      period = 1.seconds
      simple_job = Pushpop::Job.new('foo') do
        every period
        step 'track_times_run' do
          @times_run ||= 0
          @times_run += 1
        end
      end

      simple_job.schedule

      Clockwork.manager.tick(Time.now)
      expect(simple_job.run.first).to eq(2)
      Clockwork.manager.tick(Time.now + period)
      expect(simple_job.run.first).to eq(4)
    end

     it 'fails if neither period nor webhook  was not specified' do
       simple_job = Pushpop::Job.new('foo') do end
       expect {
         simple_job.schedule
       }.to raise_error(RuntimeError)

       simple_job.period = 5.seconds

       expect {
         simple_job.schedule
       }.not_to raise_error

       simple_job.period = nil
       simple_job.webhook_url = '/test'

       expect {
         simple_job.schedule
       }.not_to raise_error
     end
  end

  describe '#method_missing' do
    class FakeStep < Pushpop::Step
    end

    before do
    end

    it 'assumes its a registered plugin name and try to create a step' do
      Pushpop::Job.register_plugin('blaz', FakeStep)
      simple_job = job do
        blaz 'hi' do end
      end
      expect(simple_job.steps.first.name).to eq('hi')
      expect(simple_job.steps.first.class).to eq(FakeStep)
    end

    it 'does not assume a name' do
      Pushpop::Job.register_plugin('blaz', FakeStep)
      simple_job = job do
        blaz do end
      end
      expect(simple_job.steps.first.name).not_to be_nil
      expect(simple_job.steps.first.plugin).to eq('blaz')
      expect(simple_job.steps.first.class).to eq(FakeStep)
    end

    it 'raises an exception if there is no registered plugin' do
      expect {
        job do
          blaze do end
        end
      }.to raise_error /undefined method/
    end
  end

end
