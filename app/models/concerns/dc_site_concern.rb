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

#########################################################################
# ActiveSupport::Concern definition for DcSite class. 
#########################################################################
module DcSiteConcern
extend ActiveSupport::Concern
included do

include Mongoid::Document
include Mongoid::Timestamps

field :name,                type: String
field :description,         type: String
field :homepage_link,       type: String
field :error_link,          type: String
field :header,              type: String, default: ''
field :css,                 type: String, default: ''
field :route_name,          type: String, default: ''
field :page_title,          type: String
field :document_extension,  type: String
field :page_class,          type: String, default: 'DcPage'
field :site_layout,         type: String, default: 'content'
field :menu_class,          type: String, default: 'DcSimpleMenu'
field :request_processor,   type: String
field :files_directory,     type: String
field :logo,                type: String
field :active,              type: Mongoid::Boolean, default: true
field :created_by,          type: BSON::ObjectId
field :updated_by,          type: BSON::ObjectId
field :menu_name,           type: String
field :menu_id,             type: BSON::ObjectId
field :settings,            type: String
field :alias_for,           type: String
field :rails_view,          type: String,  default: ''
field :design,              type: String,  default: ''
field :inherit_policy,      type: BSON::ObjectId

embeds_many :dc_policies
embeds_many :dc_parts

index( { name: 1 }, { unique: true } )
index( { alias_for: 1 } )

validates :name, presence: true
validates :name, uniqueness: true

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  DrgCms.cache_clear(:dc_site)
end

########################################################################
# Returns value of site setting. If no value is send as parameter it returns 
# all settings hash object.
########################################################################
def params(what=nil)
  @params ||= self.settings.to_s.size > 5 ? YAML.load(self.settings) : {}
  what.nil? ? @params : @params[what.to_s]
end

########################################################################
# Returns class object of collection name
########################################################################
def page_klass
  page_class.classify.constantize
end

########################################################################
# Returns class object of menu collection name
########################################################################
def menu_klass
  (menu_class.blank? ? 'DcMenu' : menu_class).classify.constantize
end

########################################################################
# Return choices for select for site_id
########################################################################
def self.choices4_site
  result = all.inject([]) { |r,site| r << [ (site.active ? '' : I18n.t('drgcms.disabled') ) + site.name, site._id] }
  result.sort {|a,b| a[0] <=> b[0]}
end

########################################################################
# Return choices for selecting policies for the site
# @deprecated
########################################################################
#def self.choices4_policies
#  site = ApplicationController.dc_get_site_()
  #all.inject([]) { |r,site| r << [ (site.active ? '' : t('drgcms.disabled') ) + site.name, site._id] }
#  [['a','b']]
#end

########################################################################
# Return choices for selecting policies for the site
########################################################################
def self.choices_for_menu(menu_class)
  return [] if menu_class.blank?
  menu = menu_class.classify.constantize
  menu.where(active: true).inject([]) do |r, a_menu|
    r << [a_menu.description, a_menu.id]
  end
end

end  
end
