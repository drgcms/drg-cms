# Copyright 2012-2021 Damjan Rems

$:.push File.expand_path('../lib', __FILE__)

# Maintain gem's version:
require 'drg_cms/version'

# Describe gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'drg_cms'
  s.version     = DrgCms::VERSION
  s.authors     = ['Damjan Rems']
  s.email       = ['damjan.rems@gmail.com']
  s.homepage    = 'https://www.drgcms.org'
  s.summary     = 'DRG: Rapid web application development tool and CMS for Ruby, Rails and MongoDB'
  s.description = 'DRG, development tool for rapid building of in-house (Intranet, private cloud) applications as well as CMS for creating complex, data-entry intensive web sites.'
  s.license     = 'MIT'
  s.files       = Dir['{app,config,db,lib}/**/*'] + %w[MIT-LICENSE Rakefile README.md History.log drg_cms.gemspec]
  s.test_files  = Dir['test/**/*']

  s.required_ruby_version = '>= 2.7'

  s.add_dependency 'rails', '~> 6.1'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'non-stupid-digest-assets'  

  s.add_dependency 'bcrypt' #, '~> 3.0.0'
  s.add_dependency 'mongoid', '~> 7'

  s.add_dependency 'kaminari-mongoid'
  s.add_dependency 'kaminari-actionview'
#  s.add_dependency 'font-awesome-rails'
#  s.add_dependency 'drg_material_icons'
  s.add_dependency 'sort_alphabetical'
end
