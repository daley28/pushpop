require 'spec_helper'

describe 'job' do
  it 'has a name' do
    job 'foo-main' do end
    expect(Pushpop.jobs.first.name).to eq('foo-main')
  end
end

describe Pushpop do
  before(:each) do
    Pushpop.web.instance_variable_set(:@routes, [])    
  end

  describe 'add_job' do
    it 'adds a job to the list' do
      empty_proc = Proc.new {}
      Pushpop.add_job('foo', &empty_proc)
      expect(Pushpop.jobs.first.name).to eq('foo')
    end
  end

  describe 'random_name' do
    it 'is 8 characters and alphanumeric' do
      expect(Pushpop.random_name).to match(/^\w{8}$/)
    end
  end

  describe 'clock' do
    it 'starts clock in a thread' do
      t = Pushpop.start_clock
      expect(t.class).to be(Thread)

      t.exit
    end
  end

  describe 'web' do
    it 'gets or creates an instance of Web' do
      expect(Pushpop.web.class).to be(Pushpop::Web)
    end

    it 'does not start the web app if no routes are defined' do
      expect(Pushpop.start_webserver).to be_falsey
    end

    it 'starts the web app in a thread' do
      Pushpop.web.add_route('/test', Proc.new{})
      t = Pushpop.start_webserver
      expect(t.class).to be(Thread)

      t.exit
    end
  end

end
