#--
# Copyright (c) 2012+ Damjan Rems
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

##########################################################################
# Model and collection for filtering and sorting data.
##########################################################################
class DcFilter
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :dc_user_id,  type: BSON::ObjectId
  field :table,       type: String
  field :description, type: String
  field :filter,      type: String,       default: ''
  field :public,      type: Boolean
  field :active,      type: Boolean,      default: true
  
  index( { collection: 1, dc_user_id: 1 } )
  
  validates :description, presence: true  
  
  before_save :do_before_save
  
######################################################################
# Implementation of before_save callback.
######################################################################
def do_before_save
  self.dc_user_id = nil if self.public
end

######################################################################
# Will return model with filter query set  
######################################################################
def self.get_filter(filter)
  yaml = YAML.load(filter) rescue nil
  return yaml if yaml.nil?
  return nil if yaml['table'].nil? # old data
#
  model = yaml['table'].classify.constantize
  field = yaml['field'] == 'id' ? '_id' : yaml['field'] # must be
# if value == NIL no filter is necessary
  return nil if yaml['value'].class == String and yaml['value'] == '#NIL'
  
# do regex if operation is like  
  value = yaml['operation'] == 'like' ? /#{yaml['value']}/i : yaml['value'] 
# when field type is ObjectId transform value    
  if model.fields[field] and model.fields[field].type == BSON::ObjectId
    value = BSON::ObjectId.from_string(value) rescue nil
  end
#
  if ['eq','like'].include?(yaml['operation'])
    model.where(field => value)
# TODO in operator    
  else
    model.where(field.to_sym.send(yaml['operation']) => value)
  end
end

############################################################################
# Will return field form definition if field is defined on form. Field definition
# will be used for input field on the form.
############################################################################
def self.get_field_form_definition(name, parent) #:nodoc:
  form = parent.form
  form['form']['tabs'].each do |tab|
# Array with 2 elements. First is tabname, second is data      
    fields = tab.last
    fields.each {|k,v| return v if (k.class == Fixnum and v['name'] == name) }
  end if form['form']['tabs'] #  I know. But nice. 
#
  form['form']['fields'].each do |field|
    next unless field.first.class == Fixnum # options
    return field.last if field.last['name'] == name
  end if form['form']['fields']
  nil
end

############################################################################
# Return filter input field for entering variable filter values on index form 
############################################################################
def self.get_filter_field(parent) 
  return '' if parent.session[ parent.form['table'] ].nil?
  filter = parent.session[ parent.form['table'] ][:filter]
  return '' if filter.nil?
#
  filter = YAML.load(filter) rescue nil 
  return '' if filter.nil?
#
  field = get_field_form_definition(filter['field'], parent)
  return '' if field.nil? and filter['input'].nil?
  field = {} if field.nil?
# If field has choices available in labels, use them. This is most likely select input field.
  if field['name']
    choices = parent.t('helpers.label.' + parent.form['table'] + '.choices4_' + field['name'] )
    unless choices.match( 'translation missing' ) or choices.match('helpers.label')
      field['choices'] = choices
    end
  end
# field redefined with input keyword. Name must start with _
  field['name'] = '_filter_field'
  field['type'] = filter['input'] if filter['input'].to_s.size > 5
  field['type'] ||= 'text_field'
  field['html'] ||= {} 
  field['html']['size']  = 20
# Start with last entered value
  field['html']['value'] = filter['value'] unless filter['value'] == '#NIL'
  field['html']['selected'] = field['html']['value'] # for select field
# url for filter ON action
  field['html']['data-url'] = parent.url_for(
    controller: 'cmsedit',action: :index, filter: 'on',
    table: parent.form['table'], formname: parent.form['formname'])
  url = field['html']['data-url']
# create input field object
  klas_string = field['type'].camelize
  klas = DrgcmsFormFields::const_get(klas_string) rescue nil
  return '' if klas.nil?
# return data from object and create html code to display field
  object = klas.new(parent, nil, field).render
  js     = object.js
  "<span class=\"filter_field\" data-url=\"#{url}\">#{object.html} " <<
    parent.fa_icon('filter lg dc-green', class: 'record_filter_field_icon dc-link dc-animate') <<
    (js.size > 2 ? parent.javascript_tag(js) : '') << '</span>'
end

######################################################################
# Create popup menu for filter options.
######################################################################
def self.menu_filter(parent)
  html = '<ul class="menu-filter">' 
  table = parent.form['table']
  documents = self.where(table: table, active: true).to_a
  documents.each do |document|
    html << "<li data-filter=\"\">#{document.description}</li>"
  end

# add filters defined in model
  model = table.classify.constantize
  filters = model.dc_filters rescue nil
  if filters
# only single defined. Convert to array.    
    filters = [filters] if filters.class == Hash
    filters.each do |filter| 
      url = parent.dc_link_to(filter['title'], nil,controller: :cmsedit, action: :index, table: table,
                           formname: parent.params[:formname], 
                           filter_field: filter['field'],
                           filter_oper: filter['operation'],
                           filter_value: filter['value'],
                           filter: 'on')
      html << "<li>#{url}</li>"
    end
  end
# divide standard and custom filter options  
  html << '<hr>' if html.size > 30 # 
#  html << '<li onclick="$(\'#drgcms_filter\').toggle(300);">' + I18n.t('drgcms.filter_set') + '</li>'
  html << '<li id="open_drgcms_filter">' + I18n.t('drgcms.filter_set') + '</li>'
  html << '</ul>'
end
end
