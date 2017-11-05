# Copyright 2012-2016 Damjan Rems

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "drg_cms/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "drg_cms"
  s.version     = DrgCms::VERSION
  s.authors     = ["Damjan Rems"]
  s.email       = ["damjan.rems@gmail.com"]
  s.homepage    = "http://www.drgcms.org"
  s.summary     = "DRG CMS: Rapid web application development tool for Ruby, Rails and MongoDB"
  s.description = "DRG CMS can be used for rapid building of complex, data-entry intensive web sites as well as building your in-house private cloud applications."
  s.license     = "MIT"
  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md", "History.log", "drg_cms.gemspec"]
  s.test_files = Dir["test/**/*"]

  s.required_ruby_version = '>= 2.4'

  s.add_dependency 'rails', '>= 5'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'non-stupid-digest-assets'  

  s.add_dependency 'bcrypt' #, '~> 3.0.0'
  s.add_dependency 'mongoid'#, '~> 5'
#  s.add_dependency 'mongo_session_store-rails4'  
#  s.add_dependency 'kaminari'
  s.add_dependency 'kaminari-mongoid'
  s.add_dependency 'kaminari-actionview'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'sort_alphabetical'
end
