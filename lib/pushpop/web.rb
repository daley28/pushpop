require 'sinatra/base'

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
        job.run
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
