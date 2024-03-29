class NewDrgFormGenerator < Rails::Generators::NamedBase
  
source_root File.expand_path('../templates', __FILE__)
#desc "This generator creates form for model at app/forms"
#argument :form_name, :type => :string, :default => ''
class_option :tabs, :type => :boolean, :default => false, :description => "Create form with tabulators" 

###########################################################################
# Will create output and save it to form filename.
###########################################################################
def create_form_file
#:TODO: find out how to prevent error when model class is not defined
  @file_name = file_name
  form_name = file_name #if formname.size == 0
  begin
    @model = file_name.classify.constantize
  rescue Exception => e
    msg = ([e.message]+e.backtrace).join($/)
    Rails.logger.error(msg)
    pp msg
    @model = nil
  end
  return (pp "Error loading #{file_name.classify} model! Aborting.") if @model.nil?
#  
  yml = top_level_options + index_options + result_set_options + form_top_options + form_fields_options + localize_options
  create_file "app/forms/#{form_name}.yml", yml
end

private
###########################################################################
#
###########################################################################
def top_level_options
  <<EOT 
# Form for #{file_name}
table: #{file_name}
#title: Alternative title
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
#      form_name: form_name

EOT
end

###########################################################################
#
###########################################################################
def result_set_options
  <<EOT 
result_set:
#  filter: controls_filter
#  actions_width: 100
#  per_page: 10
  
  actions: standard

#  actions: 
#    1:
#      type: link
#      controller: controller_name
#      action: action_name
#      table: table_name
#      form_name: form_name
#      target: target      
#      method: (get),put,post      
# 
# Choose from
# #{@model.attribute_names.join(',')}
  columns:
    10:  
      name: #{@model.attribute_names[1]}
      style: 'color: red'
      width: 10%
      align: right
    20:  
      name: #{@model.attribute_names[2]}
    30: 
      name: created_at
      format: '%d.%m.%Y'
    40: 
      name: created_by
      eval: dc_name4_id,dc_user,name
    50: 
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
def form_field(field_name, index, offset, field_type)
  helper = I18n.t("helpers.label.#{@file_name}.choices4_#{field_name}")
  type, eval = 'select',''
  if helper.class == Hash || helper.match( 'Translation missing' )
    if field_name[-3, 3] == '_id'
      eval = "eval: dc_choices4('#{field_name[0, field_name.size - 3]}', 'description_field_name', 'id')\n"
    elsif field_type.match('Boolean')
      type = 'check_box'
    else
      type = 'text_field'
    end
  end

  yml = ' '*offset
  yml << "#{index}:\n"
  offset += 2

  yml << ' '*offset + "name: #{field_name}\n"
  yml << ' '*offset + "type: #{type}\n"
  yml << ' '*offset + eval if eval.size > 0
  yml << ' '*offset + "size: 50\n" if type == 'text_field'
  if type == 'select'
    yml << ' '*offset + "html:\n"
    offset += 2
    yml << ' '*offset + "include_blank: true\n"
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
    yml << ' '*(offset+2) + "form_name: #{embedded_name[0,embedded_name.size - 1]}\n"
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
  forbidden = %w[_id created_by updated_by created_at updated_at]
  tab_index = 1
  field_index = 0
  if options.tabs? 
    yml = "  tabs:\n"
    @model.fields.each do |attr_name, field|
      next if forbidden.include?(attr_name)

      if field_index%100 == 0
        yml << "    tab#{tab_index}:\n"
        field_index = 0
        tab_index += 1
      end
      field_index += 10
      yml << form_field(attr_name, field_index, 6, field.options[:type].to_s)
    end
    yml << "    tab#{tab_index}:\n"
    yml << embedded_form_field(6)

  else  
    yml = "  fields:\n"
    @model.fields.each do |attr_name, field|
      next if forbidden.include?(attr_name)

      field_index += 10      
      yml << form_field(attr_name, field_index, 4, field.options[:type].to_s)
    end
    yml << embedded_form_field(4)
  end
  yml
end

###########################################################################
#
###########################################################################
def xform_fields_options
  forbidden = %w[_id created_by updated_by created_at updated_at]
  tab_index = 1
  field_index = 0
  @model.fields.each do |name, field|
    pp [name, field.options[:type].to_s]
    #pp [name, type]
  end
end

###########################################################################
#
###########################################################################
def localize_options
  forbidden = %w[_id created_by updated_by created_at updated_at]
  yml =<<EOT
  
#################################################################
# Localization
en:
  helpers:
    label:
      #{file_name}:
        tabletitle: 
        choices4_ : 

EOT
  @model.attribute_names.each do |attr_name|
    next if forbidden.include?(attr_name)
    yml << "        #{attr_name}: \n"
  end
  yml
end  
    
end
