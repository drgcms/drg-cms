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
# Collection name: dc_link : Alternative links
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Link name ex. homepage
#  params               String               Aditional parameters passed to document renderer
#  active               Mongoid::Boolean     Link is active
#  page_id              BSON::ObjectId       Page redirected to by this shortcut link
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_site_id           Object               Link is valid for site
# 
# DcLink documents may be used for creating alternative url links. page_id field must 
# point to valid DcPage document which will be used for further processing. 
#########################################################################
class DcLink
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,        type: String
  field :params,      type: String
  field :active,      type: Boolean, default: true 
  field :page_id,     type: BSON::ObjectId
  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId

  belongs_to  :dc_site, optional: true
 
  index({ site_id: 1, name: 1 }, { unique: true })
  
  validates :name, presence: true
end 