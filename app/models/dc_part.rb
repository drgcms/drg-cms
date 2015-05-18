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
# Mongoid::Document model for dc_part embedded documents.
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
