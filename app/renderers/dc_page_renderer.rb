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
include CmsCommonHelper

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
# Render IFrame part if defined on page
# 
# Parameters forwarded to iframe are defined in if_params field as yaml as:
#   param_name:
#     object: internal object name (params, session, site, page)
#     method: method name (variable) holding the value of parameter
#     
#   example: Forward id parameter to iframe 
#   id:
#     object: params
#     method: id
#     
#   example: Forward user id and edit_mode to iframe
#   user_id:
#     object: session
#     method: user_id
#   edit:
#     object: session
#     method: edit_mode
#     
#########################################################################
def iframe
  return '' if @page.if_url.blank?
  html =  "\n<iframe"
  html << " id=\"#{@page.if_id}\"" unless @page.if_id.blank?
  html << " class=\"#{@page.if_class}\"" unless @page.if_class.blank?
  html << " border=\"#{@page.if_border}\""  
  html << " height=\"#{@page.if_height}\"" unless @page.if_height.blank?
  html << " width=\"#{@page.if_width}\"" unless @page.if_width.blank?
  html << " scrolling=\"#{@page.if_scroll}\""
# Parameters
  parameters = @page.if_url.match(/\?/) ? '' : '?' 
  params = YAML.load(@page.if_params) rescue {}
  params = {} unless params.class == Hash
  params.each do |key, value|
    val = @parent.dc_internal_var(value['object'], value['method'])
    parameters << "&#{key}=#{val}" if val # only when not nil
  end
  url = @page.if_url + (parameters.size > 1 ? parameters : '')
  html << "src=\"#{url}\" ></iframe>\n"
  html
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
  @parent.page_title = @page.title.blank? ? @page.subject : @page.title
  html << @page.body
# render poll if defined
  if @page.dc_poll_id
    @opts.merge!(:poll_id => @page.dc_poll_id, :return_to => @parent.request.url, method: nil)
    comment = DcPollRenderer.new(@parent, @opts)
    html << "<div class='wrap row'>#{comment.render_html}</div>"
    @css << "\n#{comment.render_css}"
  end
# also add iframe
  html << iframe()
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
