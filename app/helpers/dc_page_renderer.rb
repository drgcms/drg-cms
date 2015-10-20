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

########################################################################
# Page renderer renders data from dc_page collection documents. This renderer will
# almost certainly be replaced by your own renderer so example here shows just basic code 
# which just checks if user is allowed to view data and if so returns document body content
# otherwise returns error message defined in site policy.
# 
# Example:
#    <div id="page">
#      <%= dc_render(:dc_page) %>
#    </div>
#
########################################################################
class DcPageRenderer

include DcApplicationHelper

########################################################################
# Object initialization.
########################################################################
def initialize( parent, opts={} ) #:nodoc:
  @parent = parent
  @opts   = opts
  @page   = @parent.page
  @css    = ''
end

#########################################################################
# Default DcPage render method
#########################################################################
def default
  can_view, msg = dc_user_can_view(@parent, @page)
  return msg unless can_view
#  
  html = ''
  html << dc_page_edit_menu() if @opts[:edit_mode] > 1
  html << @page.body
end

#########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcPage: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @css
end

end
