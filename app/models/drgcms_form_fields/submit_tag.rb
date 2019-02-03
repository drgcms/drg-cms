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
# Create submit_tag form field. submit_tag form field is mostly used by polls but can
# be also incorporated in the middle of form.
# 
# ===Form options:
# * +type:+ submit_tag (required)
# * +caption:+ Submit field caption 
# * +icon:+ Icon
# * +html:+ html options which apply to link_to (optional)
#      
# Form example:
#    40:
#      type: submit_tag
#      caption: translate.this
#      icon: check
###########################################################################
class SubmitTag < DrgcmsField
  
###########################################################################
# Render submit_tag field html code
###########################################################################
def render
  @yaml['html'] ||= {}
  @yaml['html']['class'] ||= 'dc-submit'
  @yaml['html'].symbolize_keys!
  text = @yaml['caption'] || @yaml['text']
  text = t(@yaml['text']) if text.match(/\./)
  
  @html << @parent.submit_tag(text, @yaml['html'])
  self
end
end

end
