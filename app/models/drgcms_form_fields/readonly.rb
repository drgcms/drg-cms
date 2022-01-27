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
# Implementation of readonly DRG CMS form field. 
# 
# Readonly field value is just painted on form.
# 
# ===Form options:
# * +name:+ field name
# * +type:+ readonly
# * +eval:+ value will be provided by evaluating expression. Usually dc_name4_id helper
# can be used to get value. Example: dc_name4_id,model_name_in_lower_case,field_name 
# 
# * +readonly:+ yes (can be applied to any field type)
# 
# Form example:
#    10:
#      name: user
#      type: readonly
#      html:
#        size: 50
#    20:
#      name: created_by
#      type: readonly
#      eval: dc_name4_id,dc_user,name
###########################################################################
class Readonly < DrgcmsField
  
###########################################################################
# Render readonly field html code
###########################################################################
def render
  set_initial_value
  @record[@yaml['name']] = @yaml['html']['value'] if @yaml['html']['value']

  @html << @parent.hidden_field('record', @yaml['name']) # retain field as hidden field
  @html << '<div class="dc-readonly">'

  @html << if @yaml['eval']
             if @yaml['eval'].match(/dc_name4_id|dc_name_for_id/)
               parms = @parent.dc_eval_to_array(@yaml['eval'])
               parms << nil if parms.size == 3
               @parent.dc_name_for_id(parms[1], parms[2], parms[3], @record[@yaml['name']])
             else
               eval( "#{@yaml['eval']} '#{@record.send(@yaml['name'])}'")
             end
           else
             @parent.dc_format_value(@record.send(@yaml['name']), @yaml['format'])
           end
  @html << '</div>'
  self
end

end

end
