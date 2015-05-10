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
# Mongoid::Document model for dc_folder_permissions collection. 
# 
# Similar to DcPermission DcFolderPermission model defines documents
# for accessing file system. Permissions defined on a parent folder automatically
# apply to all folders below unless folder on lower level has its own permission document.
# 
# At least one document must exist for file manager to work. Default document
# usually defines that admin role has ADMINISTRATOR rights on top level folder.
#########################################################################
class DcFolderPermission
include Mongoid::Document
include Mongoid::Timestamps

field   :folder_name, type: String
field   :inherited,   type: Boolean, default: true
#field   :is_default,  type: Boolean, default: false  
field   :active,      type: Boolean, default: true  

embeds_many :dc_policy_rules

index( { folder_name: 1 }, { unique: true } )    

validates :folder_name, presence: true
validates :folder_name, uniqueness: true  

end
