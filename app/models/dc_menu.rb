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
# Collection name: dc_menu : Menus
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
#  dc_menu_items        Embedded:DcMenuItem  Menu items
# 
# Default menu system for DRG CMS. Model recursively embeds DcMenuItem documents
# which (theoretically) results in infinite level of sub menus. In practice 
# reasonable maximum level of 4 is advised.
#########################################################################
class DcMenu
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

  embeds_many :dc_menu_items
  
  validates :name, :length => { :minimum => 4 }
  validates :name, uniqueness: true  
  validates_length_of :description, minimum: 10
  
#######################################################################
# Will return all top level menu items of specified menu. Used in DcPage document for
# selecting top level selected menu, when document displayed in browser.
# 
# Called from DcApplicationHelper :dc_choices4_menu: method.
# 
# Parameters: 
# [Site] DcSite document. Site for which menu belongs to. If site is not specified 
# all current menus in dc_menus collection will be returned.
# 
# Returns:
# Array. Of choices prepared for select input field.
#######################################################################
  def self.choices4_menu(site)
  rez = []
  menus = (site.menu_name.blank? ? all : where(name: site.menu_name)).to_a
  menus.each do |menu|
    rez << [menu.name, nil]
    menu.dc_menu_items.where(active: true).order_by(order: 1).each do |menu_item|
      rez << ['-- ' + menu_item.caption, menu_item._id]
    end
  end
  rez
end

end
