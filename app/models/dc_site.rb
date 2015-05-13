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
  field :page_table,          type: String
  field :page_class,          type: String, default: 'DcPage'
  field :site_layout,         type: String, default: 'application'
  field :menu_class,          type: String, default: 'DcSimpleMenu'
  field :files_directory,     type: String
  field :logo,                type: String
  field :guest_access,        type: Integer, default: 0
  field :active,              type: Boolean, default: true
  field :created_by,          type: BSON::ObjectId
  field :updated_by,          type: BSON::ObjectId  
  field :menu_name,           type: String
  field :settings,            type: String
  field :alias_for,           type: String  
  field :rails_view,          type: String,  default: ''
  field :design,              type: String,  default: ''
  
  embeds_many :dc_policies
  
  index( { name: 1 }, { unique: true } )
  
########################################################################
# Return choices for select for site_id
########################################################################
def self.choices4_site
  all.inject([]) { |r,site| r << [ (site.active ? '' : t('drgcms.disabled') ) + site.name, site._id] }
end

########################################################################
# Return choices for selecting policies for the site
########################################################################
def self.choices4_policies
  site = ApplicationController.dc_get_site_()
  #all.inject([]) { |r,site| r << [ (site.active ? '' : t('drgcms.disabled') ) + site.name, site._id] }
  [['a','b']]
end

########################################################################
# Returns value of site setting. If no value is send as parameter it returns 
# all settings hash object.
########################################################################
def params(what=nil)
  @params ||= self.settings.to_s.size > 5 ? YAML.load(self.settings) : {}
  what.nil? ? @params : @params[what.to_s]
end

end  
end


######################################################################
# Mongoid::Document model for dc_sites collection.
# 
# Since DRG CMS can handle multiple sites on single ROR instance, every document
# in dc_sites collection defines data which defines a site. 
# 
# Sites can be aliased which is very usefull in development and test environment. 
# If 'site.name' document is not found application will search for 'test' document and
# continue searching with value found in alias_for field. 
######################################################################
class DcSite
  include DcSiteConcern
end
