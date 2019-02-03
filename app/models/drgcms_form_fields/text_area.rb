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
# Implementation of text_area DRG CMS form field.
# 
# ===Form options:
# * +type:+ text_area (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to text_area field (optional)
# 
# Form example:
#    10:
#      name: css
#      type: text_area
#      html:
#        size: 100x30
###########################################################################
class TextArea < DrgcmsField

###########################################################################
# Return value for readonly field
###########################################################################
def ro_standard
  value = @record[@yaml['name']]
  @html << "<div class='dc-readonly'>#{value.gsub("\n",'<br>')}</div>" unless value.blank?
  self
end

###########################################################################
# Render text_area field html code
###########################################################################
def render
  return ro_standard if @readonly
  set_initial_value
#
#  @yaml['html'] ||= {}
#  value_send_as = 'p_' + @yaml['name']
#  @yaml['html']['value'] = @parent.params[value_send_as] if @parent.params[value_send_as]

  record = record_text_for(@yaml['name'])
  @html << @parent.text_area(record, @yaml['name'], @yaml['html'])
  self
end

end
end
