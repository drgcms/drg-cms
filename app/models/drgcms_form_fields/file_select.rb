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
# Implementation of file_select DRG CMS form field.
# 
# FileSelect like HtmlField implements redirection for calling document manager edit field code.
# This can be drg_default_html_editor's elfinder or any other code defined
# by dc_site.settings file_select setting.
# 
# Example of dc_site.setting used for drg_default_html_editor gem.
#    html_editor: ckeditor
#    ck_editor:
#      config_file: /files/ck_config.js  
#      css_file: /files/ck_css.css
#   file_select: elfinder
#   
# Form example:
#    60:
#      name: picture
#      type: file_select
#      html:
#        size: 50   
###########################################################################
class FileSelect < DrgcmsField

###########################################################################
# Render file_select field html code
###########################################################################
def render
  return ro_standard if @readonly  
  # retrieve file_select component from site settings
  selector_string = @parent.dc_get_site.params['file_select'] if @parent.dc_get_site 
  selector_string ||= 'elfinder' 

  klas_string = selector_string.camelize
  if DrgcmsFormFields.const_defined?(klas_string)
    klas = DrgcmsFormFields::const_get(klas_string)
    o = klas.new(@parent, @record, @yaml).render
    @js << o.js
    @html << o.html 
  else
    @html << "File select component not defined. Check site.settings or include drgcms_default_html_editor gem."
  end
  self
end

end
end
