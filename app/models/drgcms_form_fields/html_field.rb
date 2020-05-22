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
# Implementation of html_field DRG CMS form field. 
# 
# HtmlField class only implements code for calling actual html edit field code.
# This is by default drg_default_html_editor gem which uses CK editor javascript plugin 
# or any other plugin. Which plugin will be used as html editor is defined by 
# dc_site.settings html_editor setting. 
# 
# Example of dc_site.setting used for drg_default_html_editor gem.
#    html_editor: ckeditor
#    ck_editor:
#      config_file: /files/ck_config.js  
#      css_file: /files/ck_css.css
#   file_select: elfinder
#   
# Form example:
#    10:
#      name: body
#      type: html_field
#      options: "height: 500, width: 550, toolbar: 'basic'" 
###########################################################################
class HtmlField < DrgcmsField

###########################################################################
# Render html_field field html code
###########################################################################
def render
  #return ro_standard if @readonly  
# retrieve html editor from page settings
  editor_string = @parent.dc_get_site.params['html_editor'] if @parent.dc_get_site
  editor_string ||= 'ckeditor'
# 
  klas_string = editor_string.camelize
  if DrgcmsFormFields.const_defined?(klas_string)
    klas = DrgcmsFormFields::const_get(klas_string)
    o = klas.new(@parent, @record, @yaml).render
    @js << o.js
    @html << o.html 
  else
    @html << "HTML editor not defined. Check site.settings or include drgcms_default_html_editor gem."
  end
  self
end

end
end
