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

########################################################################
# == Schema information
#
# Collection name: dc_simple_menu_item : drgCMS Simple menu items
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  caption              String               Caption of menu
#  picture              String               Picture for the menu
#  link                 String               Link called when menu is chosen
#  link_prepend         String               Link field usually holds direct link to document. Prepand field holds data, that has to be prepanded to the link.
#  target               String               Target window for the link. Leave empty when same window.
#  order                Integer              Order on which menu item is shown. Lower number means prior position.
#  submenu              String               Submenu captions in form (caption\link).
#  policy_id            BSON::ObjectId       Menu item will be diplayed according to this policy
#  css                  String               CSS only for this menu item
#  active               Mongoid::Boolean     Is active
# 
# DcMenuItem documents are embedded in the DcSimpleMenu document and define top
# level item of menu system. Submenus are simply defined as YAML text in the submenu field.
# 
# Submenu example: 
#    1:
#      title: Zadnja številka
#      link: /zadnjastevilka
#    2:
#      title: Arhiv
#      link: /arhivrevij
#    3:
#      title: Naročam
#      link: /clanek/podjetnik-narocilnica
########################################################################
class DcSimpleMenuItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :caption,   type: String
  field :picture,   type: String
  field :link,      type: String
  field :link_prepend, type: String
  field :target,    type: String
  field :order,     type: Integer, default: 10
  field :submenu,   type: String
  field :policy_id, type: BSON::ObjectId
  field :css,       type: String

  field :active,    type: Boolean, default: true 

  embedded_in :dc_simple_menu
end
