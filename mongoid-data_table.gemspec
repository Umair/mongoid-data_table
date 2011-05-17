$:.push File.expand_path("../lib", __FILE__)
require "mongoid/data_table/version"

Gem::Specification.new do |s|
  s.name        = "mongoid-data_table"
  s.version     = Mongoid::DataTable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason Dew", "Andrew Bennett"]
  s.email       = ["jason.dew@gmail.com", "potatosaladx@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/mongoid-data_table"
  s.summary     = %q{Simple data preparation from Mongoid to the jQuery DataTables plugin}
  s.description = %q{Simple data preparation from Mongoid to the jQuery DataTables plugin}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", "~>3.0.0"
  s.add_dependency "will_paginate", "~>3.0.pre2"

  s.add_development_dependency "bson_ext", "~>1.3.0"
  s.add_development_dependency "mongoid", "~>2.0.1"
  s.add_development_dependency "mocha", "~>0.9.12"
  s.add_development_dependency "rspec", "~>2.6.0"
  s.add_development_dependency "shoulda", "~>2.11.3"
  s.add_development_dependency "watchr", "~>0.7"
end
