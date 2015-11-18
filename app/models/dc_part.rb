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
require_dependency DrgCms.model 'dc_piece'

########################################################################
# == Schema information
#
# Collection name: dc_part : Parts of page
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 Last updated at
#  name                 String               Parts can be searched by name or by id
#  description          String               Short description of part
#  picture              String               Picture contents of part
#  thumbnail            String               Small version of picture if available
#  body                 String               Content of this part
#  css                  String               CSS
#  script               String               Script, if script is included in part
#  script_type          String               Script type
#  params               String               params
#  piece_id             BSON::ObjectId       Piece name if part is connected to piece
#  div_id               String               Div id (position name) where this part is displayed as defined on design
#  site_id              BSON::ObjectId       site_id
#  order                Integer              Order between parts
#  active               Mongoid::Boolean     Part is active
#  valid_from           DateTime             Part is valid from
#  valid_to             DateTime             Part is valid to
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       Last updated by
#  _type                String               _type
#  policy_id            BSON::ObjectId       Access policy for the part
#  link                 String               Link when part can be accessed with pretty link
# 
# DcPart model is used for embedding parts of final document into other models. It declares fields
# which may be used in various scenarios. For example:
# - part of page which is visible to all users and part only to registered users
# - list of pictures or attachments which belong to document 
# -
# 
# DcPart model inherits its definition from DcPiece model, but adds policy_id
# field to definition. Policy_id field may be used where site policy must be 
# taken into account when rendering part.
########################################################################
class DcPart 
  include DcPieceConcern
  
  field :_type,       type: String, default: 'DcPart' # needed when changed to Concern
  field :policy_id,   type: BSON::ObjectId
  field :link,        type: String
  
  embedded_in :dc_parts, polymorphic: true
  
  before_save :do_before_save
  
######################################################################
# Implementation of before_save callback.
######################################################################
def do_before_save
  if self.link.blank?
    self.link = self.name.strip.downcase.gsub(' ','-')
  end
end
  
end
