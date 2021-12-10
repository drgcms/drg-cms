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
#  page_class           String               Rails model class name which defines table holding pages data usually DcPage
#  site_layout          String               Rails layout used to draw response. This is by default content layout.
#  menu_class           String               Rails model class name which defines table holding menu data usually DcMenu
#  files_directory      String               Directory name where uploaded files are located
#  logo                 String               Logotype picture for the site
#  active               Mongoid::Boolean     Is the site active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  menu_name            String               Menu name for this site
#  menu_id              BSON::ObjectId       Menu id. Menu name will be deprecated.
#  settings             String               Various site settings
#  alias_for            String               Is alias name for entered site name
#  rails_view           String               Rails view filename used as standard design
#  design               String               Standard design can also be defined at the site level
#  inherit_policy       BSON::ObjectId       Use policy from other site
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
