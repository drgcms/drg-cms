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
# Renderer methods which may be useful on any site.
########################################################################
class DcCommonRenderer < DcRenderer

include DcApplicationHelper

########################################################################
# Renderer for printer friendly layout. Will call another renderer which
# should provide html code for printer friendly output.
# 
# Parameters are passed through link. There are currently two parameters, 
# which define renderer and method to be used for creating output.
# 
# renderer::
#  Defines renderer's class 
# method::
#  Defines renderer's class method
########################################################################
def layout_4print
  return '' if @parent.params[:renderer].blank?
  opts = @opts.dup
  opts[:method] = @parent.params[:method]
  klass = (@parent.params[:renderer] + '_renderer').classify
  obj = Kernel.const_get(klass, Class.new).new(@parent, opts)
# 
  html = obj.render_html
  @css  << obj.render_css.to_s
  html
end

########################################################################
# Renderer for Google analytics code.
# 
# Parameters:
# Are passed through @opts hash and can therefore be set on site  
# or page document parameters field as ga_acc key. You may also disable sending 
# 
# 
# If eu_cookies_allowed function is defined in javascript libraries it will be
# called and if false is returned GA code will not be executed. This is in 
# order with European cookie law.
# 
# Example:
#    dc_render(:dc_common_renderer, method: 'google_analytics', code: 'UA-12345678-9')
########################################################################
def google_analytics
  html = ''
  ga_acc = @opts[:code] || @opts[:ga_acc]
  if ga_acc && ga_acc != '/'
    html << %(
  <!-- Google analytics. -->
<script type="text/javascript">
  (function(i,s,o,g,r,a,m){
  if (typeof(eu_cookies_allowed) === "function" && !eu_cookies_allowed() ) return;

  i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  if (typeof(ga) === "function") {
    ga('create', '#{ga_acc}', 'auto');
    ga('send', 'pageview')
  }
</script>
)
  end

  ga4_acc = @opts[:code4] || @opts[:ga4_acc]
  if ga4_acc && ga4_acc != '/'
    html << %(
  <!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=#{ga4_acc}"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', '#{ga4_acc}');
</script>)
  end

  html.html_safe
end

########################################################################
# Will return html code required for open edit form in iframe. If parameters 
# are found in url iframe will be initial loaded with url parameters thus
# enabling forms load on page display.
########################################################################
def _remove_iframe_edit()
  @parent.render(partial: 'dc_common/iframe_edit', formats: [:html])
end

########################################################################
# Return HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcCommonRenderer: Method #{method} doesn't exist!"
end

end
