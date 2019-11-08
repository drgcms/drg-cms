#--
# Copyright (c) 2019+ Damjan Rems
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

########################################################################
# == Schema information
#
# Collection name: dc_json_ld : JSON_LD data for site optimization
#
#  _id                  BSON::ObjectId       _id
#  type                 String               Type of structure
#  data                 String               Structure data in YAML
#  dc_json_lds          Object               Can embed substructure
#  created_at           Time                 created_at
#  updated_at           Time                 Last updated at
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       Last updated by
# 
########################################################################
class DcJsonLd 
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type,        type: String
  field :data,        type: String
  field :active,      type: Boolean,      default: true

  embeds_many :dc_json_lds, :cyclic => true

  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId

  
##########################################################################
# Returns JSON LD data as YAML
##########################################################################
def get_json_ld(parent_data)
  yaml = YAML.load(self.data) rescue {}
  yaml['@type'] = self.type if yaml.size > 0
  if dc_json_lds.size > 0
    dc_json_lds.each do |element|
      yml = element.get_json_ld(parent_data)
      if yml.size > 0
        yaml[element.type] ||= []
        yaml[element.type] << yml 
      end
    end
  end
  yaml
end

########################################################################
# Searches forms path for file_name and returns full file name or nil if not found.
# 
# @param [String] Form file name. File name can be passed as gem_name.filename. This can
# be useful when you are extending form but want to retain same name as original form
# For example. You are extending dc_user form from drg_cms gem and want to
# retain same dc_user name. This can be done by setting drg_cms.dc_user to extend option. 
# 
# @return [String] Form file name including path or nil if not found.
########################################################################
def self.dc_find_form_file(form_file)
  form_path=nil
  if form_file.match(/\.|\//)
    form_path,form_file=form_file.split(/\.|\//)
  end
  DrgCms.paths(:forms).reverse.each do |path|
    f = "#{path}/#{form_file}.yml"
    return f if File.exist?(f) and (form_path.nil? or path.to_s.match(/\/#{form_path}\//i))
  end
  p "Form file #{form_file} not found!"
  nil
end

#########################################################################
# Create menu to add schema element.
#########################################################################
def self.choices4_type()
  yaml = YAML.load_file( dc_find_form_file('json_ld_schema') )
  
  yaml.inject([]) {|result, schema_name| p '1', schema_name;  result << schema_name.first }
end

#########################################################################
# Create menu to add schema element.
#########################################################################
def self.add_schema_menu(parent)
  collection = parent.params['table'].split(';').first.classify.constantize
  pp parent.params
  document = collection.find(parent.params['ids'])
  
  yaml = YAML.load_file( dc_find_form_file('json_ld_schema') )
  pp yaml
  
  html = '<ul>'
  yaml.each do |schema_name, schema_data|
    html << "<li>#{schema_name}</li>"
  end
  html << '</ul>'
  
=begin
#  
  postopek = find_by(naziv: dokument.naziv_postopka)
  koraki = postopek.postopki_koraks.all.order_by('order asc').to_a
# ugotavljanje možnih korakov, ki izhajajo iz trenutnega stanja
  mozni_koraki = []
  koraki.each do |korak|
    (mozni_koraki << korak; next) if korak.stanje_postopka == '*'
    korak.stanje_postopka.split(',').each do |stanje|
      if dokument.stanje_postopka == stanje
        mozni_koraki << korak
        break
      end
    end
  end
  return '<ul><li>Ni več postopkov!</li></ul>' if mozni_koraki.size == 0
#
  html = '<ul class="menu-filter">'  
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
      %Q[<li class="dc-link-ajax dc-animate" id="dc-submit-ajax" data-url="#{url}" data-request="#{request}">#{korak.naziv}</li>]
    else
      '<li>' + parent.link_to(korak.naziv, parms, title: korak.opis) + '</li>'
    end
  end
  html << '</ul>'
=end
  
end
  
end