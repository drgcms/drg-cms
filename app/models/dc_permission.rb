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
# Collection name: dc_permission : Collection permissions
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  table_name           String               Permission is valid for collection
#  is_default           Mongoid::Boolean     This is default permission for all collections in database
#  active               Mongoid::Boolean     Permission is active
#  dc_policy_rules      Embedded:DcPolicyRule Defined policy rules
# 
# dc_permissions collection is used for saving documents which define permissions 
# for accessing individual collections within DRG CMS system. Document which is marked 
# as default is the top level document and defines general permissions valid for
# all collections. Other documents define permissions for accessing single
# collections or even embedded documents within collections.
#########################################################################
class DcPermission
#- Available permissions settings

# User has no access 
NO_ACCESS     = 0 
# User can view documents
CAN_VIEW      = 1 
# User can create new documents  
CAN_CREATE    = 2 
# User can edit his own documents
CAN_EDIT      = 4 
# User can edit all documents in collection
CAN_EDIT_ALL  = 8 
# User can delete his own documents
CAN_DELETE    = 16 
# User can delete all documents in collection
CAN_DELETE_ALL = 32
# User can admin collection (same as can_delete_all, but can see documents which do not belong to current site)
CAN_ADMIN     = 64 
# User is superadmin. Basicly same as admin.
SUPERADMIN    = 128 

include Mongoid::Document
include Mongoid::Timestamps

field   :table_name,  type: String
field   :is_default,  type: Boolean, default: false  
field   :active,      type: Boolean, default: true  

#embeds_many :dc_policy_rules
embeds_many :dc_policy_rules, as: :policy_rules

index( { table_name: 1 }, { unique: true } )    

validates :table_name, presence: true
validates :table_name, uniqueness: true  

########################################################################
# Will return choices for permissions prepared for usega in select input field.
# This will return english only comments so it is not used.
########################################################################
def self.values_for_permissions #:nodoc:
  [['NO_ACCESS',0],['CAN_VIEW',1],['CAN_CREATE',2],['CAN_EDIT',4],['CAN_EDIT_ALL',8],['CAN_DELETE',16],['CAN_DELETE_ALL',32],['CAN_ADMIN',64],['SUPERADMIN',128]]
end

#############################################################################
# Will return permissions for collection
############################################################################
def self.permissions_for_table(collection_name)
  if collection_name.match(';')
    collection, embedded, rest = collection_name.split(';')
  else
    collection, embedded = collection_name, nil
  end
  result = permissions_for('*')
  result = permissions_for("#{collection[0,3]}*", result)
  result = permissions_for(collection, result)
  # include permissions for embedded documents
  result = permissions_for("#{collection};#{embedded}", result) if embedded
  result
end

#############################################################################
# 
############################################################################
def self.permissions_for(collection_name, result = {}) #:nodoc:
  permissions = if collection_name == '*'
    self.find_by(is_default: true)
  else
    self.find_by(table_name: collection_name, active: true)
  end
  permissions.dc_policy_rules.each {|perm| result[perm.dc_policy_role_id] = perm.permission } if permissions
  result
end

end
