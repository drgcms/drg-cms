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

##########################################################################
# == Schema information
#
# Collection name: dc_big_menu : Big menus
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  caption              String               caption
#  picture              String               picture
#  parent               BSON::ObjectId       parent
#  link                 String               link
#  page_id              BSON::ObjectId       page_id
#  order                Integer              order
#  active               Mongoid::Boolean     active
#  policy_id            BSON::ObjectId       policy_id
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_site_id           Object               dc_site_id
#
# This menu system is still experimental. It can be used for sites with menu
# which has many sub menus each linked to its own document. Unlike other menu 
# models which provide menu in single document (with embedded documents as sub menus) this 
# menu system provides one document for every menu option.
##########################################################################
class DcBigMenu
  include Mongoid::Document
  include Mongoid::Timestamps

  field :caption,     type: String
  field :picture,     type: String
  field :parent,      type: BSON::ObjectId
  field :link,        type: String
  field :page_id,     type: BSON::ObjectId
  field :order,       type: Integer
  field :active,      type: Boolean, default: true 
  field :policy_id,   type: BSON::ObjectId  

  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId

  belongs_to  :dc_site, optional: true

  index( { dc_site_id: 1, parent: 1 } )
  index( { page_id: 1 } )
  
########################################################################### 
# Process submenu. Subroutine of choices4_menu.
########################################################################### 
def self.add_sub_menu(site, parent, rez, level)
#TODO Make this faster  
  only(:_id,:parent,:caption).where(dc_site_id: site._id, parent: parent).sort( order: 1).to_a.each do |m|
    rez << ['- '*(level+1) + ' ' + m.caption, m._id]
    self.add_sub_menu(site, m._id, rez, level+1)
  end
end

###########################################################################
# Returns available menu choices for selecting menu
###########################################################################
def self.choices4_menu(site)
  rez   = []
  self.add_sub_menu(site, nil, rez, -1)
  rez
end

=begin
###########################################################################  
def self.add_sub_menu(menu, parent, rez, start, level)
  found = false
  start.upto(menu.size - 1) do |i|
    if menu[i].parent == parent
      rez << ['- '*(level+1) + ' ' + menu[i].caption, menu[i]._id]
      self.add_sub_menu(menu, menu[i]._id, rez, i, level+1)
      found = true
    else
# already been trough tree
      break if found
    end
  end
end

###########################################################################  
def self.choices4_menu(site)
#TODO Make this faster  
  rez   = []
  only(:_id,:parent,:caption).where(dc_site_id: site._id, parent: nil).sort( order: 1).to_a.each do |m|
    rez << [m.caption, m._id]
    sub = only(:_id,:parent,:caption).where(dc_site_id: site._id, parent: m._id).sort( order: 1).to_a
    self.add_sub_menu(sub, m._id, rez, 0, 0)
  end
  rez
end
=end

end
