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
module DrgcmsFormFields

###########################################################################
# Implementation of hidden DRG CMS form field.
# 
# Will create hidden_field on form.
# 
# ===Form options:
# * +name:+ field name
# * +type:+ hidden_field
# 
# Form example:
#    10:
#      name: im_hidden
#      type: hidden_field
###########################################################################
class HiddenField < DrgcmsField
###########################################################################
# Render hidden_field field html code
###########################################################################
def render 
  set_initial_value
  value = @yaml['html']['value'] ? @yaml['html']['value'] : @record[@yaml['name']]
  record = record_text_for(@yaml['name'])  
  @parent.hidden_field(record, @yaml['name'], value: value)
end
end


end
