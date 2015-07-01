require 'logger'
require 'clockwork'
require 'pushpop/version'
require 'pushpop/job'
require 'pushpop/step'
require 'pushpop/cli'
require 'pushpop/web'

module Pushpop
  class << self

    @@jobs = []

    @@logger = lambda {
      logger = Logger.new($stdout)
      if ENV['DEBUG']
        logger.level = Logger::DEBUG
      elsif ENV['RACK_ENV'] == 'test'
        logger.level = Logger::FATAL
      else
        logger.level = Logger::INFO
      end
      logger
    }.call

    def logger
      @@logger
    end

    def jobs
      @@jobs
    end

    def web
      @web ||= Web.new
    end

    def start_webserver
      # If we start this thread with no routes, it will throw off the all_waits listener
      # and we don't want to start the web server willy nilly, because it looks weird
      # on the CLI interface
      if web.routes.length > 0
        Thread.new do
          if ENV['PORT']
            @web.app.run! :port => ENV['PORT']
          else
            @web.app.run!
          end
        end
      else
        false
      end
    end

    # for jobs and steps
    def random_name
      (0...8).map { (65 + rand(26)).chr }.join
    end

    def add_job(name=nil, &block)
      self.jobs.push(Job.new(name, &block))
      self.jobs.last
    end

    def run
      self.jobs.map &:run
    end

    def schedule
      self.jobs.map &:schedule
    end

    def start_clock
      Thread.new do
        Clockwork.manager.run
      end
    end

    def require_file(file = nil)
      if file
        if File.directory?(file)
          Dir.glob("#{file}/**/*.rb").each { |file|
            load "#{Dir.pwd}/#{file}"
          }
        else
          load file
        end
      else
        Dir.glob("#{Dir.pwd}/jobs/**/*.rb").each { |file|
          load file
        }
      end
    end
    alias :load_jobs :require_file 

    def load_plugin(name)
      load "#{File.expand_path("../plugins/#{name}", __FILE__)}.rb"
    end
  end
end

# add into main
def job(name=nil, &block)
  Pushpop.add_job(name, &block)
end
