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
# == Schema information
#
# Collection name: dc_ad : Ads
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  position             String               Position (div id) where this ad will be displayed
#  description          String               Short description
#  type                 Integer              Content type of add
#  file                 String               Picture or flash filename
#  script               String               JavaScript script, when script type
#  link                 String               Link to page (site, dokument) when ad is clicked
#  link_target          String               Define if link is open in new window or same
#  height               Integer              Height of ad
#  width                Integer              Width of ad
#  valid_from           DateTime             Ad is valid from
#  valid_to             DateTime             Ad is valid to
#  displays             Integer              Maximum number of time this add is displayed
#  clicks               Integer              Maximum number of clicks this ad will receive
#  priority             Integer              Priority. Higher priority means ad is shown more often. Priority is calculated only between candidats to be displayed.
#  displayed            Integer              No. of times this add has been displayed
#  clicked              Integer              No. of times this ad has been clicked
#  active               Mongoid::Boolean     Ad is active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       Record last updated by
#  dc_site_id           Object               Ad is valid for the site
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
