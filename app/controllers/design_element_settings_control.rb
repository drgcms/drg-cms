#encoding: utf-8
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
# DrgcmsControls for DcDummy model for editing settings in a document.
######################################################################
module DcDummySettingsControl

######################################################################
# Called when new empty record is created
######################################################################
def _dc_new_record()
  @record.design_id = params[:design_id] if params[:design_id]
  return unless params[:page_id]
#
  if page = DcPage.find(params[:page_id])
    @record.design_id = page.design_id
    @record.menu      = page.menu
  end
end

######################################################################
# Called before edit. 
# 
# Loads fields on form with values from settings document.
######################################################################
def get_settings()
# Check model  
  begin
    model = params[:table].classify.constantize    
  rescue Exception => e 
    flash[:error] = 'Invalid or undefined model name!'
    return false    
  end
# Check fild name 
  begin
    doc = model.find(params[:id])
    yaml = doc.send(params[:field_name])
    yaml = '' if yaml.blank?
  rescue Exception => e 
    flash[:error] = 'Invalid or undefined field name!'
    return false    
  end
# Check data
  begin
    data = YAML.load(yaml)
  rescue Exception => e 
    flash[:error] = 'Invalid configuration data found!'
    return false    
  end
  [doc, data] 
end

######################################################################
# Called before edit. 
# 
# Loads fields on form with values from settings document.
######################################################################
def dc_before_edit()
  doc, data = get_settings
  return false if doc.class == FalseClass
#  
  data['settings'].each { |key, value| @record[key] = value }
  true
end

######################################################################
# Called before save. 
# 
# Convert data from fields on form to yaml and save it to document field.
######################################################################
def dc_before_save()
  doc, data = get_settings
  return false if doc.class == FalseClass
#
  fields_on_form.each do |v|
    session[:form_processing] = v['name'] # for debuging
    next if v['type'].nil? or
            v['type'].match('embedded') or # don't wipe embedded types
            v['readonly'] or # fields with readonly option don't return value and would be wiped
# return value from form field definition
    value = DrgcmsFormFields.const_get(v['type'].camelize).get_data(params, v['name'])
    data['settings'][v['name']] = value
  end
# save data to document field  
  doc.send(params[:field_name], data.to_yaml)
  doc.save
  false # must be set
end


end 
