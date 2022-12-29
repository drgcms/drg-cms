#--
# Copyright (c) 2014+ Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

######################################################################
# DRG Controls for editing settings in a document.
# 
# Parameters to settings call:
# :location - model_name where settings document is located. Typicaly dc_page or dc_site.
# :field_name - name of the field where settings are saved
# :element - element name as defined on design 
# :id - document id
######################################################################
module DesignElementSettingsControl

######################################################################
# Check if settings control document exists and return document and 
# settings values as yaml string.
# 
# Return:
#   [document, data] : Mongoid document, yaml as String
######################################################################
def get_settings
  # On save. Set required variables
  if params[:record]
    params[:location]   = params[:record][:dc_location]
    params[:field_name] = params[:record][:dc_field_name]
    params[:element]    = params[:record][:dc_element]
    params[:id]         = params[:record][:dc_document_id]    
  end

  # Check model
  begin
    model = params[:location].classify.constantize    
  rescue 
    flash[:error] = "Invalid or undefined model name! #{params[:location]}"
    return false    
  end

  # Check fild name
  begin
    document = model.find(params[:id])
    params[:field_name] ||= (params[:location] == 'dc_site' ? 'settings' : 'params')
    # field not defined on document
    raise unless document.respond_to?(params[:field_name])
    yaml = document[params[:field_name]] || ''
  rescue 
    flash[:error] = 'Invalid or undefined field name!'
    return false    
  end

  # Check data
  begin
    data = YAML.load(yaml) || {}
  rescue 
    flash[:error] = 'Invalid configuration data found!'
    return false    
  end
  [document, data] 
end

######################################################################
# Called before edit. 
# 
# Load fields on form with values from settings document.
######################################################################
def dc_new_record
  document, data = get_settings
  return false if document.class == FalseClass && data.nil?
  # fill values with settings values
  if data['settings'] && data['settings'][ params[:element] ]
    data['settings'][ params[:element] ].each { |key, value| @record.send("#{key}=", value) }
  end
  # add some fields required at post as hidden fields to form
  form = @form['form']['tabs'] ? @form['form']['tabs'].to_a.last : @form['form']['fields']
  form[9999] = {'type' => 'hidden_field', 'name' => 'dc_location', 'html' => {'value' => params[:location]}}
  form[9998] = {'type' => 'hidden_field', 'name' => 'dc_field_name'}
  @record[:dc_field_name] = params[:field_name]
  form[9997] = {'type' => 'hidden_field', 'name' => 'dc_element'}
  @record.dc_element = params[:element]
  form[9996] = {'type' => 'hidden_field', 'name' => 'dc_document_id', 'html' => {'value' => params[:id]}}
  true
end

######################################################################
# Called before save. 
# 
# Convert data from fields on form to yaml and save it to document settings field.
######################################################################
def dc_before_save
  document, data = get_settings
  return false if document.class == FalseClass && data.nil?

  fields_on_form.each do |field|
    session[:form_processing] =   field['name'] # for debuging
    next if field['type'].nil? or field['readonly'] # fields with readonly option don't return value and would be wiped

    # return value from form field definition
    value = DrgcmsFormFields.const_get(field['type'].camelize).get_data(params, field['name'])
    value = value.map(&:to_s) if value.class == Array
    # set to nil if blank
    value = nil if value.blank?
    data['settings'] ||= {}
    data['settings'][ params[:element] ] ||= {}
    data['settings'][ params[:element] ][ field['name'] ] = value
  end
  # remove nil elements
  data['settings'][ params[:element] ].compact!
  # save data to document field
  document.send("#{params[:field_name]}=", data.to_yaml)
  document.save
  # to re-set form again
  dc_new_record
  false # must be 
end


end 
