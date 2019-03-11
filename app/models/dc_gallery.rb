#--
# Copyright (c) 2019+ Damjan Rems
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
# Collection name: dc_gallery : Pictures gallery
#
#  _id                  BSON::ObjectId       _id
#  doc_id               BSON::ObjectId       Document id of the gallery
#  title                String               Title name for picture
#  description          String               Short description
#  picture              String               Picture filename
#  thumbnail            String               Picture thumbnail
#  
#  active               Mongoid::Boolean     Picture is active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
# 
# Picture gallery collection holds data about picture galleries for 
# different types of documents.
#########################################################################
class DcGallery
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title,       type: String
  field :description, type: String
  field :picture,     type: String
  field :thumbnail,   type: String
  field :doc_id,      type: BSON::ObjectId
  field :order,       type: Integer
  
  field :active,      type: Boolean, default: true 
  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId
 
  index doc_id: 1
  
  validates :picture, presence: true
  validates :doc_id, presence: true
end 