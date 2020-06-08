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
# Implementation of action DRG CMS form field. Actions can also be inserted on
# the form like just like on action pane.
# 
# ===Form options:
# * +type:+ action (required)
# * +action_type:+ link, submit or ajax action (default link)
# * +caption:+ Caption for action
# * +icon:+ Action icon
# * +url:+ direct url link
# * +controller:+ controller name
# * +action:+ action name 
# * +html:+ html options which apply to link_to (optional)
#      
# Form example:
#    30:
#      type: link_to
#      caption: Some action
#      icon: cogs
#      controller: my_controller
#      action: my_action
#      id: id # will be replaced by record._id
###########################################################################
class Action < DrgcmsField
  
###########################################################################
# Render link_to field html code
###########################################################################
def render
  @yaml['type'] = @yaml['action_type'] || 'link'
  #
  @html << '<ul class="action">' + @parent.dc_link_ajax_window_submit_action(@yaml,@record) + '</ul>'
  self
end

end
end
