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
  field :site_layout,         type: String, default: 'content'
  field :menu_class,          type: String, default: 'DcSimpleMenu'
  field :files_directory,     type: String
  field :logo,                type: String
  field :active,              type: Boolean, default: true
  field :created_by,          type: BSON::ObjectId
  field :updated_by,          type: BSON::ObjectId  
  field :menu_name,           type: String
  field :settings,            type: String
  field :alias_for,           type: String  
  field :rails_view,          type: String,  default: ''
  field :design,              type: String,  default: ''
  
  embeds_many :dc_policies
  embeds_many :dc_parts
  
  index( { name: 1 }, { unique: true } )
  
  validates :name, presence: true
  validates :name, uniqueness: true      
  
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
# == Schema information
#
# Collection name: dc_site : Sites
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Name of the site eg. www.mysite.com
#  description          String               Short description of site
#  homepage_link        String               Shortcut link when just site name is in the url
#  error_link           String               Link to error page
#  header               String               Additional data used in page html header
#  css                  String               Site wide CSS
#  route_name           String               Default route name for creating page link. ex. page. Leave blank if not used.
#  page_title           String               Default page title displayed in browser's top menu when title can not be extracted from document
#  document_extension   String               Default document extension eg. html
#  page_table           String               Name of table holding data for pages
#  page_class           String               Rails model class name which defines table holding pages data usually DcPage
#  site_layout          String               Rails layout used to draw response. This is by default content layout.
#  menu_class           String               Rails model class name which defines table holding menu data usually DcMenu
#  files_directory      String               Directory name where uploaded files are located
#  logo                 String               Logotype picture for the site
#  active               Mongoid::Boolean     Is the site active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  menu_name            String               Menu name for this site
#  settings             String               Various site settings
#  alias_for            String               Is alias name for entered site name
#  rails_view           String               Rails view filename used as standard design
#  design               String               Standard design can also be defined at the site level
#  dc_policies          Embedded:DcPolicy    Access policies defined for the site
#  dc_parts             Embedded:DcPart      Parts contained in site
# 
# dc_Since DRG CMS can handle multiple sites on single ROR instance, every document
# in dc_sites collection defines data which defines a site. 
# 
# Sites can be aliased which is very usefull in development and test environment. 
# If 'site.name' document is not found application will search for 'test' document and
# continue searching with value found in alias_for field. 
######################################################################
class DcSite
  include DcSiteConcern
end
