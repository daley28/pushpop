require 'thor'
require 'dotenv'
require 'pushpop'

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
      Pushpop.start_clock
      Pushpop.start_webserver
    end
  end
end


