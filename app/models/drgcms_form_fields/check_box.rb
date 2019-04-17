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
# Implementation of check_box DRG CMS form field.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ check_box (required)
# * +choices:+ Values check_box separated by comma (1,0) (yes,no)
# * +checked_value:+ 1 or yes or approved
# * +label:+ displayed right to square field
# * +unchecked_value:+ 0 or no or not approved
# * +html:+ html options which apply to check_box field (optional)
#      
# Form example:
#    30:
#      name: active
#      type: check_box
#    40:
#      name: status
#      type: check_box
#      choices: yes,no
#      label: label
###########################################################################
class CheckBox < DrgcmsField
  
###########################################################################
# Render check_box field html code
###########################################################################
def render
  set_initial_value('html','default')
# checked flag must be set    
  @yaml['html']['checked'] = !@parent.dc_dont?(@yaml['html']['default']) if @yaml['html']['default']
# disable it if readonly  
  @yaml['html']['disabled'] = @readonly ? true : nil
# If choices are present split them to set checked and unchecked value     
  @yaml['checked_value'], @yaml['unchecked_value'] = @yaml['choices'].split(',') if @yaml['choices']
  @yaml['html'].symbolize_keys!
  record = record_text_for(@yaml['name'])
  @html << if @yaml['checked_value']
    @parent.check_box(record, @yaml['name'], @yaml['html'], @yaml['checked_value'], @yaml['unchecked_value'] || '0')
  else
    @parent.check_box(record, @yaml['name'], @yaml['html'])
  end
  @html << "<label for=\"record_#{@yaml['name']}\">#{@yaml['label']}</label>" if @yaml['label']
  self
end
end

end
