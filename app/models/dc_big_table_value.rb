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
# Collection name: dc_big_table_value : Big Table - values
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  value                String               Value
#  description          String               Short description of the value
#  active               Mongoid::Boolean     Active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_big_table_locales Embedded:DcBigTableLocale Locale translations for the value
#   
# Documents are embedded in DcBigTable document. Every value defined has its own description,
# which can further be translated in embedded DcBigTableLocale documents.
#####################################################################
class DcBigTableValue
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :value,           type: String
  field :description,     type: String
  
  field :active,        type: Boolean, default: true
  field :created_by,    type: BSON::ObjectId
  field :updated_by,    type: BSON::ObjectId
  
  embeds_many :dc_big_table_locales
  embedded_in :dc_big_table
  
  validates :value,   presence: true
end
