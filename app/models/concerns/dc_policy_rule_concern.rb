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
# ActiveSupport::Concern definition for DcPolicyRule class. 
#########################################################################
module DcPolicyRuleConcern
extend ActiveSupport::Concern
included do

include Mongoid::Document
include Mongoid::Timestamps

belongs_to :dc_policy_role

field      :permission,    type: Integer, default: 0

embedded_in :policy_rules, polymorphic: true

after_save :cache_clear
after_destroy :cache_clear

#########################################################################
# Returns values for permissions ready to be used in select field.
#
# Example (as used in DRG CMS form): 
#    20:
#      name: permission
#      type: select
#      eval: DcPolicyRule.values_for_permissions
#########################################################################
def self.values_for_permissions
  key = 'helpers.label.dc_policy_rule.choices4_permission'
  c = I18n.t(key)  
  c = I18n.t(key, locale: 'en') if c.class == Hash || c.match(/translation missing/i)
  c.split(',').inject([]) { |r,e| r << (ar = e.split(':'); [ar.first, ar.last.to_i]) }
end

#########################################################################
# Will return translated permission name for value.
# 
# Parameters:
# [value] Integer. Permission value
# 
# Example (as used in DRG CMS form):
#    result_set:
#      columns:
#        2: 
#          name: permission
#          eval: DcPolicyRule.permission_name_for_value
# 
# Returns:
# String. Name (description) for value
#########################################################################
def self.permission_name_for_value(value)
  values_for_permissions.each {|v| return v.first if v.last.to_i == value.to_i}
  'error'
end

private

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  _parent.send(:cache_clear) if _parent.respond_to?(:cache_clear)
end

end
end
