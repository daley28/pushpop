require 'sinatra/base'
require 'json'

module Pushpop
  class Web
    
    def initialize
      @app = Sinatra.new
    end

    def start
      @app.run! unless @app.running?
    end

    def add_route(url, job)
      runner = lambda do
        response = self.instance_eval(&job.webhook_proc)

        if response
          {
            status: 'success',
            job: job.name
          }.to_json
        else
          {
            status: 'failed',
            job: job.name,
            message: 'webhook step did not [ass'
          }.to_json
        end
      end

      if url[0] != '/'
        url = "/#{url}"
      end

      @app.get  url, &runner
      @app.post url, &runner
      @app.put  url, &runner
    
    end
  end
end
