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
# ActiveSupport::Concern definition for DcPiece class. 
#########################################################################
module DcPieceConcern
  extend ActiveSupport::Concern
  included do
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,          type: String,  default: ''
  field :description,   type: String,  default: ''
  field :picture,       type: String   
  field :thumbnail,     type: String   
  field :body,          type: String,  default: ''
  field :css,           type: String,  default: ''
  field :script,        type: String,  default: ''
  field :script_type,   type: String,  default: ''
  field :params,        type: String,  default: ''
  field :piece_id,      type: BSON::ObjectId
  field :div_id,        type: String
  field :site_id,       type: BSON::ObjectId
  field :order,         type: Integer, default: 0
  field :active,        type: Mongoid::Boolean, default: true
  field :valid_from,    type: DateTime
  field :valid_to,      type: DateTime
  
  field :created_by,    type: BSON::ObjectId
  field :updated_by,    type: BSON::ObjectId  
  
  validates :name, presence: true
  end
end
