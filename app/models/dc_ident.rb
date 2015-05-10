#--
# Copyright (c) 2015+ Damjan Rems
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
# Mongoid::Document model for dc_idents emdedded documents.
# 
# dc_idents are similar to mongoid hash structure and can be used for saveing 
# key/value object. Fact is that I have overlooked the existance of MongoDB Hash field type
# and this structure will be used until drg_forms_field which will use Hash field type is created.
#########################################################################
class DcIdent
  include Mongoid::Document
  include Mongoid::Timestamps

  field   :key,       type: String
  field   :value,     type: String

  embedded_in :idents, polymorphic: true 
  
  validates :key, presence: true
  validates :value, presence: true
end
