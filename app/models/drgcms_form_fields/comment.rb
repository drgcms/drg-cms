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
# Implementation of comment DRG CMS form field. Comments may also be written
# on the place of form field.
# 
# ===Form options:
# * +text:+ any text. Text will be translated if key is found in translations. (required)
# * +type:+ comment (required)
# * +caption:+ Caption text written in label place. If set to false comment 
# will occupy whole row. (required)
# 
# Form example:
#    30:
#      type: comment
#      text: myapp.comment_text
#      caption: false
###########################################################################
class Comment < DrgcmsField
  
###########################################################################
# Render comment field html code
###########################################################################
def render
  comment = @yaml['comment'] || @yaml['text']
  @html << "<div class=\"dc-comment\">#{t(comment, comment).gsub("\n",'<br>')}</div>"
  self
end
end

end
