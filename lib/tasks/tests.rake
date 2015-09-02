

#########################################################################
#
#########################################################################
namespace :drg_cms do

desc "Runs all tests in test folder"
task :test do
  require 'rake/testtask'
  require 'rails/test_unit/sub_test_task'
  
#  p 1, Rake.application.top_level_tasks 
#  p 2, Rails::TestTask.test_creator(Rake.application.top_level_tasks)
#  Rails::TestTask.test_creator(Rake.application.top_level_tasks).invoke_rake_task
  
  Rails::TestTask.new(functionals: "test:prepare") do |t|
    t.pattern = 'test/{controllers,mailers,functional}/**/*_test.rb'
  end    
end
  
end