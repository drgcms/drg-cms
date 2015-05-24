class NewDrgFormGenerator < Rails::Generators::NamedBase
source_root File.expand_path('../templates', __FILE__)

###########################################################################
#
###########################################################################
def create_initializer_file
#  p Module.const_get(file_name.classify)
#:TODO: find out how to prevent error when model class is not defined
  @file_name = file_name
  @model = file_name.classify.constantize rescue nil
  return (p "Model #{file_name.classify} not found! Aborting.") if @model.nil?
  p 1,@model
#  
  yml = top_level_options + index_options + result_set_options + form_top_options + form_fields_options
  @model.attribute_names.each do |attr_name|
    next if attr_name == '_id' # no _id
# if duplicate string must be added. Useful for unique attributes
    p attr_name, I18n.t("helpers.label.#{file_name}.#{attr_name}")
    
  end
 
  create_file "app/forms/#{file_name}.yml", yml
end

private
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
  p 3,@model
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
  p 2,@model
  <<EOT 
result_set:
#  filter: controls_flter
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
# 
# Choose from
# #{@model.attribute_names.join(',')}
  columns:
    1:  
      name: #{@model.attribute_names[1]}
      style: 'align: left; width: 100px'
    2:  
      name: #{@model.attribute_names[2]}
    3: 
      name: created_at
      format: '%d.%m.%Y'
    4: 
      name: active
      eval: dc_icon4_boolean

EOT
end

###########################################################################
#
###########################################################################
def form_top_options
  <<EOT
form:
#  height: 600
#  title:
#    field: name
#    edit: Title for edit
#    show: Title for show

  actions: standard
#
#  actions: 
#    1: 
#      type: ajax
#      controller: ppk
#      action: prepare_document
#      method: (get),put,post
#      caption: Prepare document
#    2: 
#      type: script
#      caption: Cancle 
#      js: parent.reload();
#    3:
#      type: submit
#      caption: Send
#      params:
#        before-save: send_mail
#        after-save: return_to parent.reload

EOT
end

###########################################################################
#
###########################################################################
def form_field(field, index, offset)
  helper = I18n.t("helpers.label.#{@file_name}.choices4_#{field}")
  type   = 'text_field'
  if helper.class == Hash or helper.match( 'translation missing' )
    type = 'select'
  end
#
  yml = ' '*offset
  yml << "#{index}:\n"
  offset += 2
#
  yml << ' '*offset + "name: #{field}\n"
  yml << ' '*offset + "type: #{type}\n"
  if type == 'text_field'
    yml << ' '*offset + "yml:\n"
    offset += 2
    yml << ' '*offset + "size: 50\n"
  end 
  yml
end
###########################################################################
#
###########################################################################
def embedded_form_field(offset)
  yml = ''
  field_index = 10
  @model.embedded_relations.keys.each do |embedded_name|
    yml << ' '*offset + "#{field_index}:\n"
    yml << ' '*(offset+2) + "name: #{embedded_name}\n"
    yml << ' '*(offset+2) + "type: embedded\n"
    yml << ' '*(offset+2) + "formname: #{embedded_name[0,embedded_name.size - 2]}\n"
    yml << '#' + ' '*(offset+2) + "html:\n"
    yml << '#' + ' '*(offset+4) + "height: 500\n"
    field_index += 10      
  end
  yml
end

###########################################################################
#
###########################################################################
def form_fields_options
  tab_index = 1
  field_index = 0
  if @with_tabs
    yml = "  tabs:\n"
    @model.attribute_names.each do |attr_name|
      if field_index%10 == 0
        yml << "    tab#{tab_index}:"
        field_index = 0
        tab_index += 1
      end
      field_index += 10
      yml << form_field(attr_name, field_index, 6)
    end
    yml << "    tab#{tab_index}:"
    yml << embedded_form_field(6)
  else  
    yml = "  fields:\n"
    @model.attribute_names.each do |attr_name|
      field_index += 10      
      yml << form_field(attr_name, field_index, 4)
    end
    yml << embedded_form_field(4)
  end
  yml
end
    
end
