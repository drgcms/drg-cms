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

######################################################################
# == Schema information
#
# Collection name: dc_visit : Visits
#
#  _id                  BSON::ObjectId       _id
#  page_id              BSON::ObjectId       page_id
#  user_id              BSON::ObjectId       user_id
#  site_id              BSON::ObjectId       site_id
#  session_id           String               session_id
#  ip                   String               ip
#  time                 DateTime             time
# 
# DcVisit documents are used to record visits to web site.
######################################################################
class DcVisit
  include Mongoid::Document
  
  field :page_id,     type: BSON::ObjectId
  field :user_id,     type: BSON::ObjectId
  field :site_id,     type: BSON::ObjectId
  field :session_id,  type: String
  field :ip,          type: String
  field :time,        type: DateTime
  
  index( { time: 1 } )  
end
