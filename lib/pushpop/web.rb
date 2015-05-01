require 'sinatra/base'
require 'json'

module Pushpop
  class Web

    def app
      Sinatra::Application
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
            message: 'webhook step did not pass'
          }.to_json
        end
      end

      if url[0] != '/'
        url = "/#{url}"
      end
      
      puts "adding route #{url}"

      Sinatra::Application.get  url, &runner
      Sinatra::Application.post url, &runner
      Sinatra::Application.put  url, &runner
    
    end
  end
end
