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
# Mongoid::Document model for dc_journals collection. 
# 
# dc_journals collections saves all data that has been updated through cmsedit 
# controller. It saves old and new values of changed fields and can be used for
# instant restore of single document field or tracking who and when updated 
# particular document.
#########################################################################
class DcJournal
  include Mongoid::Document
  
  field :user_id,     type: BSON::ObjectId
  field :site_id,     type: BSON::ObjectId
  field :doc_id,      type: BSON::ObjectId
  field :operation,   type: String
  field :tables,      type: String
  field :ids,         type: String
  field :ip,          type: String
  field :time,        type: DateTime
  field :diff,        type: String
  
  index( { user_id: 1, time: -1 } )  
  index( { time: 1 } )  
end
