# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'pushpop/version'

Gem::Specification.new do |s|

  s.name        = "pushpop"
  s.version     = Pushpop::VERSION
  s.authors     = ["Josh Dzielak"]
  s.email       = "josh@keen.io"
  s.homepage    = "https://github.com/pushpop-project/pushpop"
  s.summary     = "A framework for scheduled integrations between popular services"
  s.description = "Pushpop is a powerful framework for taking actions and integrating services at regular intervals."

  s.add_dependency "clockwork"
  s.add_dependency "thor"
  s.add_dependency "sinatra"
  s.add_dependency "dotenv"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
