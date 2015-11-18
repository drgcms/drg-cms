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

#####################################################################
# == Schema information
#
# Collection name: dc_category : Categories
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 Last update
#  name                 String               Category name
#  description          String               Additional description of category
#  ctype                Integer              Category type. Could be used for grouping categories.
#  parent               BSON::ObjectId       Parent category. Leave blank if this is top level category.
#  active               Mongoid::Boolean     Category is active.
#  order                Integer              Additional order, which can be used for sorting.
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#   
# Categories are used on DcPage documents for grouping documents. Categorization 
# is most useful for grouping news, blog entries ...
#####################################################################
class DcCategory
  include Mongoid::Document
  include Mongoid::Timestamps

  field   :name,        type: String
  field   :description, type: String
  field   :ctype,       type: Integer, default: 1 
  field   :parent,      type: BSON::ObjectId
  field   :active,      type: Boolean, default: true
  field   :order,       type: Integer, default: 0
  field   :created_by,  type: BSON::ObjectId
  field   :updated_by,  type: BSON::ObjectId

  validates :name, :presence => true
  
  index  name: 1
  index  ctype: 1
  
#########################################################################
# Returns all values where parent value is nil (top level parent).
#########################################################################
  def self.values_for_parent #:nodoc:
    where(parent: nil).sort(name: 1).inject([]) {|r,v| r << [v.name, v._id]} 
  end
end
