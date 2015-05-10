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

##########################################################################
# Mongoid::Document model for dc_ads collection. 
# 
# Ads can be defined as picture file, flash file or script. 
# 
# More than one ad can be shown on the same place of design. They are grouped by 
# position field, have priority, valid time period and can be limited by number of 
# clicks or displays. 
##########################################################################
class DcAd
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :position,    type: String,  default: ''
  field :description, type: String,  default: ''
  field :type,        type: Integer, default: 1 # 1:pic, 2:flash, 3:script
  field :file,        type: String,  default: ''
  field :script,      type: String,  default: ''
  field :link,        type: String,  default: ''
  field :link_target, type: String,  default: ''
  field :height,      type: Integer
  field :width,       type: Integer  
  field :valid_from,  type: DateTime
  field :valid_to,    type: DateTime
  field :displays,    type: Integer, default: 0
  field :clicks,      type: Integer, default: 0
  field :priority,    type: Integer, default: 5
  field :displayed,   type: Integer, default: 0
  field :clicked,     type: Integer, default: 0
  
  field :active,      type: Boolean, default: true 
  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId
  
  belongs_to  :dc_site
  
  index( { dc_site: 1, position: 1 } )
  
  validates :position, presence: true
  validates :description, presence: true  
end
