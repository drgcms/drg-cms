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
  p YAML.load(self.filter.to_s)
  self.dc_user_id = nil if self.public
end

######################################################################
# Will create model for filter 
######################################################################
def self.get_filter(filter)
  yaml = YAML.load(filter) rescue nil
  return yaml if yaml.nil?
#
  p yaml
  model = yaml['table'].classify.constantize
  field = yaml['field'] == 'id' ? '_id' : yaml['field'] # must be
# do regex if operation is like  
  value = yaml['operation'] == 'like' ? /#{yaml['value']}/i : yaml['value'] 
# when field type is ObjectId transform value    
  if model.fields[field] and model.fields[field].type == BSON::ObjectId
    value = BSON::ObjectId.from_string(value) rescue nil
  end
  @records =  if value.nil?
    model.where(non_existent: true)
  else
    model.where(field => value)
  end
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
# divide standard and custom filter options  
  html << '<hr>' if documents.size > 0
  html << '<li onclick="$(\'#drgcms_filter\').toggle(300);">' + 'Filter</li>'
=begin  
  mozni_koraki.each do |korak|
    parms = YAML.load(korak.parametri) rescue {}
    parms ||= {} # je lahko tudi false, če ni nič vpisano
    parms = parms['action'] || {}
#    
    parms['controller'] ||= 'cmsedit'
    parms['action']     ||= 'new'
    parms['table']      ||= "#{dokument.class};postopek" 
    parms['ids']          = parent.params['ids'] 
    parms['postopek']     = "#{postopek.id};#{korak.id}"
    parms['formname']     = parent.params['formname']
    html << if parms['type'] and parms['type'] == 'ajax' # ajax klic
      url = parent.url_for(parms)
      request = parms['request'] || 'get'
      %Q[<li class="dc-link-ajax dc-animate" id="dc-submit-ajax" data-url="#{url}" data-request="#{request}">#{korak.naziv}</td>]
    else
      '<li>' + parent.link_to(korak.naziv, parms, title: korak.opis) + '</li>'
    end
  end
=end
  html << '</ul>'
end

end
