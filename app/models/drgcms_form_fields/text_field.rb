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
# Implementation of text_field DRG CMS form field.
# 
# ===Form options:
# * +type:+ text_field (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to text_field field (optional)
# 
# Form example:
#    10:
#      name: title
#      type: text_field
#      size: 30
#      html:
#        required: yes
###########################################################################
class TextField < DrgcmsField
  
###########################################################################
# Render text_field field html code
###########################################################################
def render
  return ro_standard if @readonly
  set_initial_value
#
  record = record_text_for(@yaml['name'])
  @html << @parent.text_field( record, @yaml['name'], @yaml['html']) 
  self
end

end
end
