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
# Mongoid::Document model for dc_poll_item embedded documents.
# 
# DcPollItems define entry fields on poll questionary and formulars.
########################################################################
class DcPollItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,        type: String,   default: ''
  field :text,        type: String,   default: ''
  field :type,        type: String,   default: ''
  field :size,        type: String,   default: '10'
  field :mandatory,   type: Boolean,  default: false
  field :separator,   type: String,   default: ''
  field :options,     type: String,   default: ''
  field :order,       type: Integer,  default: 0  
  field :active,      type: Boolean,  default: true 
  
  validates_length_of :name, minimum: 3

  embedded_in :dc_poll
end
