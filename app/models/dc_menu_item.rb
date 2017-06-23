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
# Collection name: dc_menu_item : Menu items
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  caption              String               Caption of menu item
#  picture              String               Picture for the menu
#  link                 String               Link called when menu is chosen
#  link_prepend         String               Link field usually holds direct link to document. Prepand field holds data, that has to be prepanded to the link.
#  target               String               Target window for the link. Leave empty when same window.
#  page_id              BSON::ObjectId       Page link
#  order                Integer              Order on which menu item is shown. Lower number means prior position.
#  active               Mongoid::Boolean     Is active
#  policy_id            BSON::ObjectId       Menu item will be diplayed according to this policy
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_menu_items        Embedded:DcMenuItem  Submenu items
# 
# DcMenuItem documents are embedded in the DcMenu document and define one menu
# item of menu system. 
#########################################################################
class DcMenuItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :caption,     type: String
  field :picture,     type: String
  field :link,        type: String
  field :link_prepend, type: String
  field :target,      type: String  
  field :page_id,     type: BSON::ObjectId
  field :order,       type: Integer
  field :active,      type: Boolean, default: true 
  field :policy_id,   type: BSON::ObjectId  

  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId

  embeds_many :dc_menu_items, :cyclic => true
  
#######################################################################
# Will return menu path for the item as array of id-s. Method can be used
# to determine all parents of current item.
# 
# Returns:
# Array. Of parent items ids.
#######################################################################
def menu_path()
  path, parent = [], self
  while parent
    path << parent.id
    parent = parent._parent
  end 
  path.reverse
end
  
end
