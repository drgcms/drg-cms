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
# == Schema information
#
# Collection name: dc_simple_menu : Simple menus
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Menu name
#  description          String               Short description of menu
#  div_name             String               Div id name around menu area
#  link_prepend         String               Link field usually holds direct link to document. Prepand field holds data, that has to be prepanded to the link.
#  css                  String               CSS for this menu
#  active               Mongoid::Boolean     Active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_simple_menu_items Embedded:DcSimpleMenuItem Menu items
# 
# Simple menus were first menu system developed for DRG CMS. They can be only two menu 
# levels deep. Menus are described in dc_simple_menu_items embedded documents.
#########################################################################
class DcSimpleMenu
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,        type: String
  field :description, type: String
  field :div_name,    type: String
  field :link_prepend, type: String
  field :css,         type: String
  field :active,      type: Boolean, default: true 
  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId

  index( { name: 1 }, { unique: true } )

  embeds_many :dc_simple_menu_items
  belongs_to  :dc_site, optional: true
  
  validates_length_of :description, minimum: 10
  
#######################################################################
# Will return all top level menu items of specified menu. Used in DcPage document for
# selecting top level selected menu, when document displayed in browser.
# 
# Called from DcApplicationHelper :dc_choices4_menu: method.
# 
# Parameters: 
# [Site] DcSite document. Site for which menu belongs to. If site is not specified 
# all current menus in collection will be returned.
# 
# Returns:
# Array. Of choices prepared for select input field.
#######################################################################
  def self.choices4_menu(site)
  rez = []
  menus = (site.menu_name.blank? ? all : where(name: site.menu_name)).to_a
  menus.each do |menu|
    rez << [menu.name, nil]
    menu.dc_simple_menu_items.where(active: true).order_by(:order => 1).each do |menu_item|
      rez << ['-- ' + menu_item.caption, menu_item._id]
    end
  end
  rez
end

#######################################################################
# Will return menu structure for menus belonging to the site.
# 
# Parameters: 
# [Site] DcSite document. Site for which menu belongs to. If site is not specified 
# all current menus in collection will be returned.
# 
# Returns:
# Array. Of choices prepared for tree:select input field.
#######################################################################
  def self.choices4_menu_as_tree(site_id=nil)
  qry = where(active: true)
# 
  ar = [nil]
  ar << site_id.id if site_id
  qry = qry.in(dc_site_id: ar)
#
  result = []
  qry.each do |menu|
    result << [menu.name, menu.id, nil,0]
    menu.dc_simple_menu_items.order_by(order: 1).each do |item|
      result << [item.caption, item.id, menu.id, item.order]
    end
  end
  result
end

end
