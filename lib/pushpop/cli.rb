require 'thor'
require 'dotenv'
require 'pushpop'
require 'thwait'

module Pushpop
  class CLI < Thor

    def self.file_options
      option :file, :aliases => '-f'
    end

    desc 'version', 'Print the Pushpop version'
    map %w(-v --version) => :version

    def version
      "Pushpop version #{Pushpop::VERSION}".tap do |s|
        puts s
      end
    end

    desc 'jobs:describe', 'Describe jobs'
    map 'jobs:describe' => 'describe_jobs'
    file_options

    def describe_jobs
      Dotenv.load
      Pushpop.require_file(options[:file])
      Pushpop.jobs.tap do |jobs|
        jobs.each do |job|
          puts job.name
        end
      end
    end

    desc 'jobs:run_once', 'Run jobs once'
    map 'jobs:run_once' => 'run_jobs_once'
    file_options

    def run_jobs_once
      Dotenv.load
      Pushpop.require_file(options[:file])
      Pushpop.run
    end

    desc 'jobs:run', 'Run jobs ongoing'
    map 'jobs:run' => 'run_jobs'
    file_options

    def run_jobs
      Dotenv.load
      Pushpop.require_file(options[:file])
      Pushpop.schedule

      threads = []
      threads << Pushpop.start_clock

      Pushpop.web.app.traps = false
      web_thread = Pushpop.start_webserver
      threads << web_thread if web_thread

      # Listen to exit signals, so the CLI doesn't hang infinitely on clock
      [:INT, :TERM].each do |signal|
        trap(signal) do
          threads.each do |thread|
            thread.exit
          end
        end
      end

      # Wait for both the clock thread and the sinatra thread to close before exiting
      ThreadsWait.all_waits(threads) do
        threads.each do |thread|
          thread.exit
        end
      end
    end
  end
end


