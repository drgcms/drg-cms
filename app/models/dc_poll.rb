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
# Mongoid::Document model for dc_poll documents.
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
end
