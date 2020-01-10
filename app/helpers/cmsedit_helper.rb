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

###########################################################################
# 
# CmseditHelper module defines common methods used for DRGCMS forms.
#
###########################################################################
module CmseditHelper
  # javascript part created by form helpers
  attr_reader :js 
  
############################################################################
# Creates code for script action type.
############################################################################
def dc_script_action(yaml)
  data = {'request' => 'script', 'script' => yaml['js']}
  %Q[<li class="dc-link-ajax dc-animate">#{ dc_link_to(yaml['caption'], yaml['icon'], '#', data: data ) }</li>]
end 
  
  
end
