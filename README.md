<p align="center">
<img align="center" src="http://f.cl.ly/items/0z182V2i3X0Q0Y3I2A2G/pushpop-logo.png"> 
</p>

[![Build Status](https://travis-ci.org/pushpop-project/pushpop.svg)](https://travis-ci.org/pushpop-project/pushpop)

### A framework for scheduled integrations between popular services

<hr>
<img src="http://f.cl.ly/items/1I421w263a10340a0u2q/Screen%20Shot%202014-04-16%20at%204.35.47%20PM.png" width="45%" alt="Pingpong Daily Response Time Report">
&nbsp;&nbsp;&nbsp;
<img src="http://f.cl.ly/items/3F3X2s2d2A1I1o0V3p1n/image.png" width="45%" alt="There were 5402 Pageviews today!">
<hr>

## Overview

Use Pushpop to schedule and run ongoing integrations between your favorite services. With Pushpop you can easily say "send data from Service A to Service B every 5 minutes". The services and the interval are entirely configurable, and you can have as many steps as you like.

Pushpop began as a way to send notifications and reports based on events captured with [Keen IO](https://keen.io).
See plugins for more services on the [Pushpop organization](https://github.com/pushpop-project) home page.

Pushpop is packaged as a Ruby gem. It can be added to existing Ruby projects or used in new ones.

#### Ideas for using Pushpop

##### Alerts

+ Send an email when your site has been busier than usual in the last hour
+ Send an SMS if the performance of your signup funnel dramatically changes

##### Recurring reports

+ Send a sales report to your inbox every day at noon
+ Send analytics reports to your customers every week
 
##### Monitoring

+ Track the performance of web services and APIs
+ Read sensor values for analysis and alerting

#### Example Pushpop job

Pushpop organizes work into jobs. Here's a Pushpop job that uses the `keen` and `sendgrid` plugins to send a nightly email. The email contains the day's number of pageviews:

``` ruby
require 'pushpop-keen'
require 'pushpop-sendgrid'

job do

  every 24.hours, at: '00:00'

  keen do
    event_collection  'pageviews'
    analysis_type     'count'
    timeframe         'last_24_hours'
  end

  sendgrid do |response, _|
    to        'josh+pushpop@keen.io'
    from      'josh+pushpop@keen.io'
    subject   'Pushpop Daily Pageviews Report'
    body      "There were #{response} pageviews today!"
  end

end
```

Keen IO provides the analytics data behind the report. The email is sent by [Sendgrid](https://sendgrid.com) via the [sendgrid](https://github.com/pushpop-project/pushpop-sendgrid) Pushpop plugin.

Pushpop syntax is short and sweet, but because Pushpop is pure Ruby it's also quite powerful.

## Quickstart

Install Pushpop as a Ruby gem:

```
$ gem install pushpop
```

You should now have a `pushpop` command available in your shell. Try it out with no arguments to see a list of possible commands:

```
$ pushpop
Commands:
  pushpop help [COMMAND]  # Describe available commands or one specific command
  pushpop jobs:describe   # Describe jobs
  pushpop jobs:run        # Run jobs ongoing
  pushpop jobs:run_once   # Run jobs once
  pushpop version         # Print the Pushpop version
```

##### Create a simple job

Copy the code below into a file called `example_job.rb`. This job simply prints output to the console:

``` ruby
require 'pushpop'

job do

  every 1.seconds

  step do
    puts 'Hello World!'
  end

end
```

Run this job once via using the `jobs:run_once` command:

``` shell
$ pushpop jobs:run_once --file example_job.rb
```

You should see the following output:

``` html
Hello World!
```

That's all there is to it. To run the job repeatedly at the times specified by `every` just change `run_once` to `run`:

``` shell
$ pushpop jobs:run --file example_job.rb
```

Make sure to leave the process running in your terminal, or [send it to the background](http://stackoverflow.com/questions/625409/how-do-i-put-an-already-running-process-under-nohup), so that it keeps running.

##### Next steps

+ Write and test more jobs. See the [Pushpop API Documentation](#pushpop-api-documentation) below for more examples of what you can do.
+ See the [pushpop-project](https://github.com/pushpop-project) Github organization to find plugins and reusable code.

## Pushpop Commands

Pushpop comes with commands to describe and run jobs.

All `jobs:*` commands optionally take a filename or directory as a `--file` or `-f` parameter. The file/directory is meant to contain one or more Pushpop jobs.

Specifying a specific file looks like this:

``` shell
$ pushpop jobs:run --file jobs/just_this_job.rb
```

Here's a list of the available commands:

+ `jobs:describe` - Print out the names of jobs in the jobs folder.
+ `jobs:run_once` - Run each job once, right now.
+ `jobs:run` - Run jobs as scheduled in a long-running process. This is the command you should use for a deployed Pushpop.

All `jobs:*` tasks also use [dotenv](https://github.com/bkeepers/dotenv) to load environment variables, often contained in a `.env` file.

## Pushpop API Documentation

Steps and jobs are the heart of the Pushpop workflow. Job files are written in pure Ruby and contain one or more jobs. Each job consists of one or more steps.

#### Jobs

Jobs have the following attributes:

+ `name`: (optional) something that describe the job, useful in logs
+ `period`: how frequently to run the job; the first param to `every`
+ `every_options` (optional): options related to when the job runs; the second param to `every`
+ `steps`: an ordered list of steps to run

These attributes are easily specified using the DSL's block syntax. Here's an example:

``` ruby
job 'print job' do
  every 5.minutes
  step do
    puts "5 minutes later..."
  end
end
```

The name of this job is 'print job'. It runs every 5 minutes and it has 1 step.

Inside of a `job` configuration block, steps are added by using the `step` method. They can also be
added by using a method registered by a plugin, like `keen` or `twilio`. For more informatio on plugins see [Plugins](#plugins).

The period of the job's execution is set via the `every` method. This is a passthrough to the [Clockwork](https://github.com/tomykaira/clockwork) long-running process scheduler. Clockwork gives you a great deal of flexibility when it comes specifiying when jobs should run. Here are some examples:

``` ruby
every 5.seconds
every 24.hours, at: '12:00'
every 24.hours, at: ['00:00', '12:00']
every 24.hours, at: '**:05'
every 24.hours, at: '00:00', tz: 'UTC'
every 5.seconds, at: '10:**'
every 1.week, at: 'Monday 12:30'
```

See the full range of possibilities on the [Clockwork README](https://github.com/tomykaira/clockwork#event-parameters).

##### Job workflow

When a job kicks off, steps are run serially in the order they are specified. Each step is invoked with 2
arguments - the response of the step immediately preceding it, and a map of all responses so far.
The map is keyed by step name, which defaults to a plugin name if a plugin was used but a step name not specified.

Here's an example that shows how the response chain works:

``` ruby
require 'pushpop'

job do
  every 5.minutes
  step 'one' do
    1
  end
  step 'two' do |response|
    5 + response
  end
  step 'add previous steps' do |response, step_responses|
    puts response # prints 6
    puts step_responses['one'] + step_responses['two'] # prints 7
  end
end
```

If a `step` returns false, subsequent steps **are not run**. Here's a simple example that illustrates this:

``` ruby
require 'pushpop'

job 'lame job' do
  every 5.minutes
  step 'one' do
    false
  end
  step 'two' do
    # never called!
  end
end
```

This behavior is designed to make *conditional* alerting easy. Here's an example of a job that only sends an alert
for certain query responses:

``` ruby
require 'pushpop'

job do

  every 1.minute

  keen do
    event_collection 'errors'
    analysis_type 'count'
    timeframe 'last_1_minute'
  end

  step 'notify only if there are errors' do |response|
    response > 0
  end

  twilio do |step_responses|
    to '+18005555555'
    body "There were #{step_responses['keen']} errors in the last minute!"
  end
end
```

In this example, the `twilio` step will only be ran if the `keen` step returned a count greater than 0.

#### Steps

Steps have the following attributes:

+ `name`: (optional) something that describes the step. Useful in logs, and is the key in the `step_responses` hash. Defaults to plugin name if a plugin is used. If you use the same plugin more than twice, you'll need to give steps individual names.
+ `plugin`: (optional) if the step is backed by a plugin, it's the name of the plugin
+ `block`: A block that runs to configure the step (when a plugin is used) or run it

Steps can be pure Ruby code or use a DSL provided by a plugin. Plugins are just fancy abstractions for creating steps.

Steps have built-in support for ERB templating. This is useful for generating more complex emails and reports.

Here's an example that uses a template:

``` ruby
sendgrid do |response, step_responses|
  to            'josh+pushpop@keen.io'
  from          'pushpopapp+123@keen.io'
  subject       'Pingpong Daily Response Time Report'
  body template 'pingpong_report.html.erb', response, step_responses
end
```

`template` is a function that renders a template in context of the `response` and `step_responses` and returns a string.
The first argument is a template file name, located in the `templates` directory by default. The second and third arguments are the `response` and `step_responses` respectively. An optional fourth parameter can be used to change the path templates are looked up in.

Here's a very simple template that uses the `response` variable in context:

``` erb
<h1>Daily Report</h1>
<p>We got <%= response %> new users today!</p>
```

## Recipes

The community-driven [pushpop-recipes](https://github.com/pushpop-project/pushpop-recipes) repository contains jobs and templates
for doing common things with Pushpop. Check it out for some inspiration!

## Plugins

Plugins are packaged as gems. See the [pushpop-project](https://github.com/pushpop-project) github organization for a sampling of popular plugins.

### Creating plugins

Plugins are just subclasses of `Pushpop::Step`. Plugins should implement a `run` method and register themselves. Here's a simple plugin that stops job execution if the input into the step is 0:

``` ruby
require 'pushpop'

module Pushpop
  class StopIfZero < Step
    PLUGIN_NAME = 'stop_if_zero'
    def run(last_response=nil, step_responses=nil)
      last_response == 0
    end
  end

  Pushpop::Job.register_plugin(StopIfZero::PLUGIN_NAME, StopIfZero)
end

# now in your job you can use the stop_if_zero step

job do
  step do [0, 1].shuffle.first end
  stop_if_zero
  step do puts 'made it through!' end
end
```

See [pushpop-plugin](https://github.com/pushpop-project/pushpop-plugin) for a repository that you can clone to make creating and packaging plugins easier.

## Contributing

Issues and pull requests are very welcome. One of the goals of the pushpop-project is to get as many unique contributors as possible. Beginners welcome too!

##### Wishlist

+ Add plugins for more data collection and email/SMS/notification services
+ Add a web interface that shows job names, previous job results, and countdowns to the next run
+ Add a web interface for previewing emails in the browser
+ Add beautiful email templates with support for typical Keen IO query responses (groups, series, etc)

##### Testing

Please make sure the specs pass before you submit your pull request. Pushpop has a full set of specs (including plugins). Run them like this:

``` shell
$ bundle exec rake spec
```
