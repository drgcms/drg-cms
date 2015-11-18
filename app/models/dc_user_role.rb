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
# Collection name: dc_user_role : User roles
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  dc_policy_role_id    Object               User role
#  valid_from           Date                 Role is valid from
#  valid_to             Date                 Role is valid to
#  active               Mongoid::Boolean     Role is active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       Role last updated 
# 
# DcUserRole documents are embedded in DcUser model and define user roles which
# belong to user.
########################################################################
class DcUserRole
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :dc_policy_role
  
  field   :valid_from,        type: Date
  field   :valid_to,          type: Date
  field   :active,            type: Boolean, default: true
  field   :created_by,        type: BSON::ObjectId
  field   :updated_by,        type: BSON::ObjectId

  embedded_in :dc_user
end
