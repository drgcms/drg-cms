class NewDrgFormGenerator < Rails::Generators::NamedBase
source_root File.expand_path('../templates', __FILE__)

###########################################################################
#
###########################################################################
def top_level_options
  <<EOT 
# Form for #{file_name}
table: #{file_name}
#title: Some title
#extend: extend
#controls: controls_file
#readonly: 1
#permissions:
#  can_view: role_name

EOT
end
  
###########################################################################
#
###########################################################################
def index_options
  <<EOT 
index:
  filter: id as text_field
  actions: standard
  
#  actions:
#    3: 
#      type: link
#      controller: controller_name
#      action: action_name
#      table: table_name
#      formname: form_name

EOT
end

###########################################################################
#
###########################################################################
def result_set_options
  <<EOT 
result_set:
#  filter: filter_vpis
#  actions_width: 100
#  per_page: 10
  
  actions: standard

#  actions: 
#    1:
#      type: link
#      controller: controller_name
#      action: action_name
#      table: table_name
#      formname: form_name
#      target: target      
#      method: (get),put,post      

#  columns:
#    1:  
#      name: name
#      style: 'align: left; width: 100px'
#    2:  
#      name: title
#    3: 
#      name: valid_from
#      format: '%d.%m.%Y'
#    4: 
#      name: active
#      eval: dc_icon4_boolean

EOT
end

###########################################################################
#
###########################################################################
def create_initializer_file
#  p Module.const_get(file_name.classify)
#:TODO: find out how to prevent error when model class is not defined
  model = file_name.classify.constantize rescue nil
  return (p "Model #{file_name.classify} not found! Aborting.") if model.nil?
#  
  yml = get_top_level
  p model.new.attributes
  model.attribute_names.each do |attr_name|
    next if attr_name == '_id' # noe _id
# if duplicate string must be added. Useful for unique attributes
    p attr_name, I18n.t("helpers.label.#{file_name}.#{attr_name}")
    
  end
 
  create_file "app/forms/#{file_name}.yml", "# Add initialization content here"
end
  
end
