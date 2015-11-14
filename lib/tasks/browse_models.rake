
@logger = Logger.new(STDOUT)

#########################################################################
# Determine model class from filename.
#########################################################################
def determine_model_name(path)
  path =~ /(.*)\/(.*).rb/
  begin
    $2.camelize.constantize 
    $2
  rescue Exception # it happends
    nil
  end
end

#########################################################################
# Return array of all models found in application.
#########################################################################
def all_collections()
  collections = []
  DrgCms.paths(:forms).each do |path|
    models_dir = File.expand_path("../models", path)
    Dir["#{models_dir}/*.rb"].each do |model_file| 
      collection_name = determine_model_name(model_file)
      collections << collection_name if collection_name
    end
  end
  collections.sort
end

#########################################################################
# Return array of all models found in application.
#########################################################################
def local_collections()
  collections = []
  models_dir = File.expand_path("app/models")
  Dir["#{models_dir}/*.rb"].each do |model_file| 
    collection_name = determine_model_name(model_file)
    collections << collection_name if collection_name
  end
  collections.sort
end

######################################################################
# Create html list of all collections and fields
######################################################################
def collections(what)
  list = []
  collections = what == 'all' ? all_collections() : local_collections()
  collections.each do |collection|
    model = collection.classify.constantize rescue nil
    next if model.nil?
#    next unless model.respond_to?(:mongo_client)
    record = {'id' =>  collection, 'description' => I18n.t("helpers.label.#{collection}.tabletitle") } 
    list << [record, fields(collection)]
  end
  list
end

######################################################################
# List field definition for single model
######################################################################
def fields(collection)
  records = []
  model = collection.classify.constantize
  document = model.new
#  p document.methods
  document.attribute_names.each do |attribute_name|
    options = model.fields[attribute_name].options
    description = I18n.t("helpers.label.#{collection}.#{attribute_name}")
    description = attribute_name if description.match('helpers.label')

    records.push( {'collection' =>  collection, 
                 'field' => attribute_name, 
                 'type' => options[:type],
                 'description' => description, 
                 '_default' => options[:default]
                } )
  end
# embedded documents
  document.embedded_relations.each do |a_embedded|
    embedded = a_embedded.last
    description = I18n.t("helpers.label.#{collection}.#{embedded.key}")
    description = embedded.key if description.match('helpers.label')

    records.push( {'collection' =>  collection, 
                 'field' => embedded.key, 
                 'type' => 'Embedded:' + embedded.class_name,
                 'description' => description
                } )
  end
#p records
  records
end

#########################################################################
#
#########################################################################
def create_output(descriptions)
# render view which will create actual mail report
  body = DcApplicationController.new.render_to_string(
    :template => 'models/dump_models',
    :locals => { descriptions: descriptions },
    :layout => 'models' 
  ) 
  File.open(Rails.root.join('public','models_dump.html'),'w') {|f| f.write(body)}
end

#########################################################################
#
#########################################################################
namespace :drg_cms do
  desc "Dump all models descriptions into public/models.html"
  task :dump_all_models => :environment do
    descriptions = collections('all')
    create_output(descriptions)
  end

  desc "Dump models descriptions from current project public/models.html"
  task :dump_models => :environment do
    descriptions = collections('local')
    create_output(descriptions)
  end
  
end