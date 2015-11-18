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
# Collection name: dc_policy_role : User roles
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Role name
#  system_name          String               System role name if required by application
#  active               Mongoid::Boolean     Role is active
# 
# Documents in this model define all available user roles in the application. Roles 
# are defined by unique name which is valid for current application or as alternative name (system_name) 
# which can be persistent, when application is used as Rails plugin. 
#########################################################################
class DcPolicyRole
  include Mongoid::Document
  include Mongoid::Timestamps

  field   :name,        type: String
  field   :system_name, type: String
  field   :active,      type: Boolean, default: true  
  
  index( { name: 1 }, { unique: true } )
  index( system_name: 1 )
  
  validates :name, :length => { :minimum => 4 }  
  validates :name, uniqueness: true    

########################################################################
# Return all defined roles as choices for use in select field.
########################################################################
def self.choices4_roles
  where(active: true).order_by(name: 1).inject([]) { |r,role| r << [ role.name, role._id] }
end

end
