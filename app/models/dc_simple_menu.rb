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
# Mongoid::Document model for dc_simple_menus collection. 
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

end
