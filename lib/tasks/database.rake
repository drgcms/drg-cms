
@logger = Logger.new(STDOUT)

#########################################################################
# Determine module class from filename.
#########################################################################
def determine_model(path)
  path =~ /(.*)\/(.*).rb/
  begin
    $2.camelize.constantize 
  rescue Exception # it happends
    nil
  end
end

#########################################################################
# Create index for single module
#########################################################################
def create_index(model)
  return if model.index_specifications.empty?
#
  if !model.embedded? || model.cyclic?
    @logger.info("DRGCMS: Creating indexes on #{model}:")
    model.create_indexes
    model.index_specifications.each do |spec|
      @logger.info("DRGCMS: Index: #{spec.key}, Options: #{spec.options}")
    end
    model
  else
    @logger.info("DRGCMS: Index ignored on: #{model}, please define in the root model.")
    nil
  end
end

#########################################################################
# Will remove all undefined indexes from collection.
#########################################################################
def remove_undefined_indexes(model)
  return if model.embedded?
#  
  begin
    undefined = []
    model.collection.indexes.each do |index|
      # ignore default index
      next if index['name'] == '_id_'
      
      key = index['key'].symbolize_keys
      spec = model.index_specification(key)
      undefined << index unless spec
    end
  rescue Mongo::Error::OperationFailure; end
#  
  undefined.each do |index|
    key = index['key'].symbolize_keys
    collection = model.collection
    collection.indexes.drop(key)
    @logger.info(
        "MONGOID: Removed index '#{index['name']}' on collection " +
        "'#{collection.name}' in database '#{collection.database.name}'."
    )
  end
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
      models << model if !model.nil? and model.respond_to?(:index_specifications)
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
    all_models.each {|model| create_index(model)}
  end

  desc "Remove undefined indexes for all mongoid models. Including those in gem plugins."
  task :remove_undefined_indexes => :environment do
    all_models.each {|model| remove_undefined_indexes(model)}
  end
  
end