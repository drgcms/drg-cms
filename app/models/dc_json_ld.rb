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

  field :name,        type: String
  field :type,        type: String
  field :data,        type: String
  field :active,      type: Boolean,      default: true

  embeds_many :dc_json_lds, :cyclic => true

  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId
  
  validates :name, presence: true
  validates :type, presence: true
  
##########################################################################
# Returns JSON LD data as YAML
##########################################################################
def get_json_ld(parent_data)
  yaml = (YAML.load(self.data) rescue nil) || {}
  yaml['@type'] = self.type if yaml.size > 0
  if dc_json_lds.size > 0
    dc_json_lds.where(active: true).each do |element|
      yml = element.get_json_ld(parent_data)
      if yml.size > 0
        yaml[element.name] ||= []
        yaml[element.name] << yml 
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

########################################################################
# Find document by ids when document are embedded into main d even if embedded
# 
# @param [tables] Tables parameter as send in url. Tables are separated by ;
# @param [ids] ids as send in url. ids are separated by ;
# 
# @return [Document] 
########################################################################
def self.find_document_by_ids(tables, ids)
  collection = tables.split(';').first.classify.constantize
  ar_ids = ids.split(';')
# Find top document  
  document = collection.find(ar_ids.shift)
# Search for embedded document
  ar_ids.each {|id| document = document.dc_json_lds.find(id) }
  document
end

#########################################################################
# Returns possible options for type select field on form.
#########################################################################
def self.choices4_type()
  yaml = YAML.load_file( dc_find_form_file('json_ld_schema') )
  
  yaml.inject([]) {|result, schema_name| result << schema_name.first }
end

#########################################################################
# Create menu to add schema element. Called from DRGCMS Form action.
#########################################################################
def self.add_schema_menu(parent)
  yaml = YAML.load_file( dc_find_form_file('json_ld_schema') )
  if (level = parent.params['ids'].split(';').size) == 1
    # select only top level elements
    yaml.delete_if { |schema_name, schema_data| schema_data['level'].nil? }
  else
    # select only elemets which are subelements of type
    parent_type = self.find_document_by_ids(parent.params['table'],parent.params['ids']).type
    _yaml = []
    yaml[parent_type].each do |name, data|
      next unless data.class == Hash
      _yaml << [data['type'], yaml[data['type']] ] if data['type'] and yaml[data['type']]
    end
    yaml = _yaml
  end
# create menu code
  html = '<ul>'
  yaml.each do |schema_name, schema_data|
    next if level == 1 and schema_data['level'].nil?
    url = "/dc_common/add_json_ld_schema?table=#{parent.params['table']}&ids=#{parent.params['ids']}&schema=#{schema_name}&url=#{parent.request.url}"
    html << %Q[<li class="dc-link-ajax" data-url="#{url}">#{schema_name}</li>]
  end
  html << '</ul>' 
end
  
end