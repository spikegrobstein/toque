# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "toque/version"

Gem::Specification.new do |s|
  s.name        = "toque"
  s.version     = Toque::VERSION
  s.authors     = ["Spike Grobstein"]
  s.email       = ["spikegrobstein@mac.com"]
  s.homepage    = ""
  s.summary     = %q{ Easily configure your servers using Capistrano-powered Chef }
  s.description = %q{ Easily configure your servers using Capistrano-powered Chef }

  s.rubyforge_project = "toque"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "json"
end
