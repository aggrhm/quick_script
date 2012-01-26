# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "quick_script/version"

Gem::Specification.new do |s|
  s.name        = "quick_script"
  s.version     = QuickScript::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alan Graham"]
  s.email       = ["alan.g.graham@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Web Application Framework}
  s.description = %q{Framework for single-page web applications}

  s.rubyforge_project = "quick_script"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

	s.add_dependency "compass"
end
