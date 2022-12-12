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
# DcGalleryRenderer renders data for displaying picture galary under the document.
# 
# Example:
#    <div id="page">
#      <%= dc_render(:dc_gallery) if document.gallery %>
#    </div>
#
########################################################################
class DcGalleryRenderer

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
# Default DcGallery render method. It will simply put thumbnail pictures side by side and
# open big picture when clicked on thumbnail.
#########################################################################
def default
  can_view, msg = dc_user_can_view(@parent, @page)
  return msg unless can_view

  html = '<div class="picture-gallery"><ul>'
  DcGallery.where(doc_id: @opts[:doc_id], active: true).order_by(order: 1).each do |picture|
    html << '<li>'
    if @opts[:edit_mode] > 1
      html << edit_menu(picture)
      html << %(
      <span class="dc-inline-link dc-link-ajax" data-url="/cmsedit/run?control=DcGalleryControl.picture_remove;id=#{picture.id};table=DcGallery"
        data-confirm="#{t('drgcms.confirm_delete')}" title="#{t('drgcms.delete')}">
        <i class="mi-o mi-delete"></i>
      </span>)
    end
    html << "#{@parent.link_to(i@parent.mage_tag(picture.thumbnail, title: picture.title), picture.picture)}<li>"
  end
  html << '</ul></div>'
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

private
########################################################################
# 
########################################################################
def edit_menu(picture)
  opts = { controller: 'cmsedit', action: 'edit' }
  opts[:title] = "#{t('drgcms.edit')}: #{picture.title}"
  opts[:id]    = picture.id
  opts[:table] = 'dc_gallery'
  
  '<li>' + dc_link_for_edit(opts) + '</li>'
end


end
