#coding: utf-8
#--
# Copyright (c) 2014+ Damjan Rems
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
#
########################################################################
class GalleryRenderer < DcRenderer

#######################################################################
# Will render picture gallery
#######################################################################
def gallery(page=nil)
  page ||= @parent.page
  return '' if page.gallery.blank?
#  
  html = '<div class="picture-gallery">'
  if @parent.dc_edit_mode?
    opts = { controller: 'cmsedit', action: 'create', formname: 'gallery', 
             table: "#{@parent.site.page_table};dc_part", ids: page._id, 
             'dc_part.div_id' => page.gallery, 'dc_part.name' => page.subject, 
             title: 'Add new picture to gallery.' }
    html << @parent.dc_link_for_create(opts)    
  end
  html << '<h2>Picture gallery:</h2>'
  page.dc_parts.where(:div_id => page.gallery).order(order: 1).each do |part|
    html << '<span class="gallery-pic">'
    if @parent.dc_edit_mode?
      opts.merge!({ action: 'edit', ids: page._id, id: part._id, title: 'Edit picture.' })
      html << @parent.dc_link_for_edit(opts)    
    end
# Display thumbnail if defined. Otherwise use picture. Picture height should be limited by CSS
    pic = part.thumbnail.blank? ? part.picture : part.thumbnail
# Use part.name as title. If not use page title (subject) field
    title = part.name.blank? ? page.subject : part.name
    html << @parent.link_to(@parent.image_tag(pic, title: title), part.picture)
# Description under picture
    html << "<h6>#{part.description}</h6>" unless part.description.blank?
    html << '</span>'
  end
# At the end we use baguetteBox javascript library to transparently display gallery on phone or pc
  html << @parent.javascript_tag( "baguetteBox.run('.picture-gallery', {});" )
  html << '</div>'
end

########################################################################
#
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "#{self.class}. Method #{method} not found!"
end

end
