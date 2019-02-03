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
# Implementation of password DRG CMS form field.
# 
# ===Form options:
# * +type:+ password_field (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to password field (optional)
# 
# Form example:
#    20:
#      name: password
#      type: pasword_field
#      html:
#        size: 20
#        
#    30:
#      name: password_confirmation
#      type: pasword_field
#      html:
#        size: 20
#        
###########################################################################
class PasswordField < DrgcmsField
  
###########################################################################
# Render password field html code
# 
###########################################################################
def render
  return self if @readonly
  @yaml['html'] ||= {}
  record = record_text_for(@yaml['name'])  
  @html << @parent.password_field(record, @yaml['name'], @yaml['html'])
  self
end
end

end
