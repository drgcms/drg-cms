
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
    next unless model.respond_to?(:mongo_client)
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
    description = I18n.t("helpers.help.#{collection}.#{attribute_name}")
    description = I18n.t("helpers.label.#{collection}.#{attribute_name}") if description.match('missing:')
    description = attribute_name if description.match('missing:')

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
    description = I18n.t("helpers.help.#{collection}.#{embedded.key}")
    description = I18n.t("helpers.label.#{collection}.#{embedded.key}") if description.match('missing:')
    description = embedded.key if description.match('missing:')

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
# Create output to models_dump.html and documentation_dump.html. First file
# is prepared for browsing, second one is prepared for copy+paste for documentation.
#########################################################################
def create_output(descriptions)
# render view which will create actual mail report
  body = DcApplicationController.new.render_to_string(
    :template => 'models/dump_models',
    :locals => { descriptions: descriptions },
    :layout => 'models' 
  ) 
  File.open(Rails.root.join('public','models_dump.html'),'w') {|f| f.write(body)}
#
  body = ''
  descriptions.each do |description|
    collection = description.first
    fields = description.last 
    body << "#\n# == Schema information\n#\n"
    body << "# Collection name: #{collection['id']} : #{collection['description']}\n#\n"
    
    fields.each do |field|
      body << "#  #{field['field'].ljust(20)} #{field['type'].to_s.ljust(20)} #{field['description']}\n"
    end
    body << "\n\n"
  end 
  File.open(Rails.root.join('public','description_dump.html'),'w') {|f| f.write(body)}
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