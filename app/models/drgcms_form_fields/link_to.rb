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
# Implementation of link_to DRG CMS form field. link_to form field is mostly used by polls but can
# be also incorporated anywhere on the form.
# 
# ===Form options:
# * +type:+ link_to (required)
# * +caption:+ Link caption 
# * +icon:+ Link icon
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
class LinkTo < DrgcmsField
  
###########################################################################
# Render link_to field html code
###########################################################################
def render
  @yaml['html'] ||= {}
  @yaml['html']['class'] ||= 'dc-link'
  @yaml['html'].symbolize_keys!

  @yaml[:id] = record._id if @yaml[:id] == 'id'
  url = @yaml['url'] || "#{@yaml[:controller]}/#{@yaml[:action]}/#{@yaml[:id]}"
  url.gsub!('//','/')                             # no action and id
  url = '/' + @yaml['url'] unless url[0,1] == '/' # no leading /
  url.chop if url[0,-1] == '/'                    # remove trailing /

  caption = @yaml['caption'] || @yaml['text']
  @html << @parent.dc_link_to(caption, @yaml['icon'], url, @yaml['html'])
  self
end
end

end
