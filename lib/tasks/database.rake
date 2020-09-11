
@logger = Logger.new(STDOUT)

#########################################################################
# Determine model class from filename.
#########################################################################
def determine_model(path)
  path =~ /(.*)\/(.*).rb/
  $2.camelize.constantize rescue nil # nil happens
end

#########################################################################
# Return array of all models found in application.
#########################################################################
def all_models()
  models = []
  DrgCms.paths(:forms).each do |path|
    models_dir = File.expand_path("../models", path)
    Dir["#{models_dir}/*.rb"].each do |model_file| 
      model = determine_model(model_file)
      models << model if model and model.respond_to?(:index_specifications)
    end
  end
  models
end

#########################################################################
#
#########################################################################
namespace :drg_cms do
  desc "Create indexes for all mongoid models. Including those in gem plugins."
  task :create_indexes => :environment do
    @logger.info( "MONGOID: Checking indexes.")
    Mongoid::Tasks::Database.create_indexes(all_models)
  end

  desc "Remove undefined indexes for all mongoid models. Including those in gem plugins."
  task :remove_undefined_indexes => :environment do
    @logger.info( "MONGOID: Remove undefined indexes.")
    Mongoid::Tasks::Database.remove_undefined_indexes(all_models)
  end
  
end