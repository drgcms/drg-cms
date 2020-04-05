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
# Collection name: dc_poll : Polls
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Unique poll name
#  title                String               Title for the poll
#  sub_text             String               Short description of the poll
#  pre_display          String               pre_display
#  operation            String               Operation performed on submit
#  parameters           String               Aditional parameters for operation
#  display              String               Select how fields are positioned on form
#  css                  String               CSS specific to this poll
#  form                 String               You can specified input items by providing form acording to rules of drgCMS form.
#  valid_from           DateTime             Pole is valid from
#  valid_to             DateTime             Pole is valid to
#  captcha_type         String               Catpcha type name if captcha is used
#  active               Mongoid::Boolean     active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_poll_items        Embedded:DcPollItem  Items for this poll
# 
# DcPoll documents are used for different questionaries and formulars which can
# be accessed independent or connected with DcPage documents. Entry fields can be defined
# as DcSimpleItem embedded structure or as DRG CMS form YAML style entered into form field.
########################################################################
class DcPoll
  
include Mongoid::Document
include Mongoid::Timestamps

field :name,          type: String, default: ''
field :title,         type: String, default: ''
field :sub_text,      type: String, default: ''
field :pre_display,   type: String
field :operation,     type: String
field :parameters,    type: String
field :display,       type: String, default: '1'
field :css,           type: String
field :form,          type: String
field :valid_from,    type: DateTime
field :valid_to,      type: DateTime
field :captcha_type,  type: String
field :active,        type: Boolean, default: true 
field :created_by,    type: BSON::ObjectId
field :updated_by,    type: BSON::ObjectId

index( { name: 1 }, { unique: true } )

embeds_many :dc_poll_items

########################################################################
# Save poll results to DcPollResults collection
# 
# Params:
# data : Hash : Records hash (params[:record])
########################################################################
def save_results(data)
  h = {}
  items = self.form.blank? ? self.dc_poll_items : YAML.load(self.form.gsub('&nbsp;',' '))
  items.each do |item|
    next if %w(hidden_field submit_tag link_to comment).include?(item.type)
    next if item.try(:options).match('hidden')
    h[ item['name'] ] = data[ item['name'] ]
  end
  DcPollResult.create(dc_poll_id: self.id, data: h.to_yaml)
end    
    
end
