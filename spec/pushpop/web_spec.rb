require 'spec_helper'

describe Pushpop::Web do
  web = nil

  before(:each) do
    web = Pushpop::Web.new
  end

  it 'returns a Sinatra Application' do
    expect(web.app).to equal(Sinatra::Application)
  end

  describe 'routes' do
    it 'is an array' do
      expect(web.routes.class).to equal(Array)
    end
    
    it 'is empty by default' do
      expect(web.routes.length).to equal(0)
    end

    it 'gets filled with new routes' do
      web.add_route('/test', Proc.new{})

      expect(web.routes.length).to equal(1)
      expect(web.routes[0]).to eq('/test')
    end
  end

  describe 'add_route' do

    before(:each) do
      Sinatra::Application.reset!
    end

    it 'raises an error for duplicate routes' do
      empty_proc = Proc.new{}

      web.add_route('/test', empty_proc)
      expect{web.add_route('/test', empty_proc)}.to raise_error(RuntimeError)
    end 

    it 'creates GET, POST, and PUT endpoints' do
      web.add_route('/test', Proc.new{})

      ['GET', 'POST', 'PUT'].each do |method|
        expect(web.app.routes.include?(method)).to be_truthy
        expect(web.app.routes[method].length).to equal(1)
        expect(web.app.routes[method][0][0].match('/test').length).to equal(1)
      end
    end
  end
end
