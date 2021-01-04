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
# Collection name: dc_policy : Access policy declarations
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Unique policy name
#  description          String               Description for this policy
#  is_default           Mongoid::Boolean     This is default policy for the site
#  active               Mongoid::Boolean     Policy is active
#  updated_by           BSON::ObjectId       updated_by
#  message              String               Error message when blocked by this policy
#  dc_policy_rules      Embedded:DcPolicyRule Policy rules
# 
# DcPolicy documents define policies for accessing data on web site. Policies define which 
# user roles (defined in dc_policy_roles collection) has no access, can view or edit data (sees CMS menu) on
# current active web page. Policies can then be applied to individual documents belonging to the web site.
# 
# Document defined as default, holds top level policy which is inherited by all
# other policies. Default policy is also used when document has no access policy assigned.
#########################################################################
class DcPolicy
include Mongoid::Document
include Mongoid::Timestamps

field :name,        type: String
field :description, type: String,  default: ''
field :is_default,  type: Boolean, default: false
field :active,      type: Boolean, default: true
field :updated_by,  type: BSON::ObjectId
field :message,     type: String,  default: ''

embeds_many :dc_policy_rules, as: :policy_rules
embedded_in :dc_site

validates :name, length: { minimum: 4 }
validates :message, length: { minimum: 5 }

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  DrgCms.cache_clear(:dc_permission)
  DrgCms.cache_clear(:dc_site)
end

=begin  
#########################################################################
# Returns values for permissions ready to be used in select field.
#########################################################################
def self.values_for_permissions 
  [['NO_ACCESS',0],['CAN_VIEW',1],['CAN_CREATE',2],['CAN_EDIT',4],['CAN_EDIT_ALL',8],['CAN_DELETE',16],['CAN_DELETE_ALL',32],['CAN_ADMIN',64],['SUPERADMIN',128]]
end

  
#########################################################################
# Returns all possible policy rules for use in select input field
#########################################################################
def self.choices4_policies()
  rez = []
  all.each do |policy|
    rez << [policy.name, nil]
    policy.dc_policy_rules.each do |rule|
      rez << ['-- ' + rule.name, rule._id]
    end
  end
  rez
end
  
#########################################################################
# Returns policy rules for the site. Since it is called from policy_role form
# which can be embedded in lots of tables (collections) table name of parent 
# is also send as parameter.
#########################################################################
def self.choices4_site_policy(table, id)
  unless table == 'dc_site'
    t  = table.classify.constantize
    id = t.find(id).dc_site_id
  end
  rez = []
  site = DcSite.find_by(id: id)
  site.dc_policy.dc_policy_rules.each { |rule| rez << [rule.name, rule._id] }
  rez
end

#########################################################################
# returns name for policy rule id
#########################################################################
def self.policy_rule_name_for(id)
  pol = find_by('dc_policy_rules._id' => BSON::ObjectId.from_string(id))
  return 'Invalid policy name!' if pol.nil?
  pol.dc_policy_rules.find(id).name
end
=end
  
end
