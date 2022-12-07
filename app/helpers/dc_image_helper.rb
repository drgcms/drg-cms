#--
# Copyright (c) 2022+ Damjan Rems
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


####################################################################
# Helpers needed by some form fields
####################################################################
module DcImageHelper
  
############################################################################
# Will return code for previewing image on top of dc_image entry form
############################################################################
def dc_image_preview(document, *parms)
  src = "/#{dc_get_site.params.dig('dc_image', 'location')}/#{document.first_available_image}"
  %(<span class="dc-image-preview dc-image-preview-1"><img src="#{src}"></img></span>).html_safe
end

############################################################################
# Will return code for previewing resized images on dc_image entry form
############################################################################
def dc_image_preview_resized(document, yaml, ignore)
  size = yaml['name'].last
  return '' if document["size_#{size}"].blank?

  src = "/#{dc_get_site.params.dig('dc_image', 'location')}/#{document.id}-#{size}.#{document.img_type}?#{Time.now.to_i}"
  %(<span class="dc-image-preview"><img src="#{src}"></img></span><div id="dc-image-preview"></div>).html_safe
end

############################################################################
# Will return choices for preset image sizes
############################################################################
def dc_image_choices_for_image_size
  sizes = dc_get_site.params.dig('dc_image', 'sizes')
  return ['300x200'] if sizes.blank?

  sizes.split(",").map(&:strip)
end

############################################################################
# Will return code for invoking dc_image_search form to select image select on a DRG Form.
#
# @param [String] field_name : Field name to which selected image value will be saved.
###########################################################################
def dc_image_invoke(field_name)
  return '' unless dc_get_site.params.dig('dc_image', 'location')

  url = url_for(controller: :cmsedit, form_name: :dc_image_search, table: :dc_image, field_name: field_name)
  %(<span class="dc-window-open" data-url="#{url}" title="#{t('drgcms.dc_image.invoke')}">#{mi_icon('image-o')}</span>).html_safe
end

############################################################################
# Will return code for previewing image on top of dc_image entry form
############################################################################
def dc_image_first(document, *parms)
  src = "/#{dc_get_site.params.dig('dc_image', 'location')}/#{document.first_available_image}"
  %(<span class="dc-image-preview"><img src="#{src}"></img></span><span id="dc-image-preview">).html_safe
end

######################################################################
# Will format qry result as html code for selecting image
######################################################################
def dc_image_select_links(doc, *parms)
  %w[o s m l].inject('') { | r,size| r << dc_image_link_for_select(doc, size) }.html_safe
end

######################################################################
# Will return HTML code for selecting image
######################################################################
def dc_image_link_for_select(doc, what)
  field = "size_#{what}"
  value = doc.send(field)
  return '' if value.blank?

  value = value.split(/\+/).first
  src = "/#{dc_get_site.params.dig('dc_image', 'location')}/#{doc.id}-#{what}.#{doc.img_type}"
  %(
<div class="img-link"><div>
 #{value}<br>
  <i class="mi-o mi-preview" onclick="dc_image_preview('#{src}');" title="#{t('drgcms.dc_image.preview')}"></i>
  <i class="mi-o mi-check_circle" onclick="dc_image_select('#{src}');" title="#{t('drgcms.dc_image.select')}"></i>
</div></div>)
end

end
