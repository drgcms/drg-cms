#coding: utf-8
#--
# Copyright (c) 2013+ Damjan Rems
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
# dc_big_menu is experimental menu system which can be used as alternative
# to dc_menu when sub menu menu level is larger than two levels. Idea is to have top two levels 
# of menu displayed on standard top of page position with other sub levels displayed vertically 
# on left or right part of page. Renderer also provides path method, which can be used to show 
# menu path of currently displayed page. 
########################################################################
class DcBigMenuRenderer

include DcApplicationHelper
include CmsCommonHelper
########################################################################
# Object initialization.
########################################################################
def initialize( parent, opts ) #:nodoc:
  @parent = parent
  @site = parent.dc_get_site
  @opts = opts
  self
end

########################################################################
# Find out which top level menu currently displayed page belongs to. Subroutine of default method.
########################################################################
def find_selected #:nodoc:
  ret = DcBigMenu.find( @parent.page.menu_id ) if @parent.page.menu_id
  while ret and ret.parent != nil
    ret = DcBigMenu.find( ret.parent )
  end
# return first if not found (something is wrong)
#  p ret
  ret ||= DcBigMenu.where(dc_site_id: @site._id, parent: nil, active: true).limit(1).first
end

########################################################################
# Creates edit link if in edit mode.
########################################################################
def link_4edit #:nodoc:
  html = ''
  return html unless @opts[:edit_mode] > 1
  
  @opts[:editparams].merge!( { table: 'dc_big_menu', controller: 'cmsedit', action: 'edit' } )
  title = "#{t('drgcms.edit')}: "
  @opts[:editparams].merge!( { id: @menu.id, title: "#{title}#{@menu.name}" } ) if @menu
  title << t('helpers.label.dc_big_menu.tabletitle')
  @opts[:editparams].merge!( { action: 'index', title: title }) if @menu.nil?
  html << dc_link_for_edit( @opts[:editparams] )
end

########################################################################
# Returns html code for single link on a menu. 
########################################################################
def link_4menu(item) #:nodoc:
  html = ''
  link = item.link
  link = "/#{@site.route_name}/#{item.page_id}" #if link.blank?
#  
  html << @parent.link_to(item.picture, link) unless item.picture.blank?
  html << if !item.caption.blank?
    # TODO Translation
    @parent.link_to(item.caption, link)
  end
end

########################################################################
# Renderer for menu part displayed on left position of page.
########################################################################
def left_menu
  html = ''
  m = DcBigMenu.find( @parent.page.menu_id )
# Show menu on same level if selected has no children
  if DcBigMenu.where( parent: @parent.page.menu_id ).limit(1).to_a.size == 0
    m = DcBigMenu.find( m.parent )
  end    
#     
  html << "<div class='menu-left-item-top'>#{m.caption}</div>"
  DcBigMenu.where( parent: m._id ).sort(order: 1).each do |item|
    html << (item._id == @parent.page.menu_id ? '<div class="menu-left-item-selected">' : '<div class="menu-left-item">')
    html << link_4menu(item) 
    html << '</div>'
  end
#  
  html << "<div class='menu-left-item-bottom'>"
  if m.parent
    p = DcBigMenu.find( m.parent )
    html << "&#9650; #{link_4menu(p)}"
  end
  html << '&nbsp;</div>' 
end

########################################################################
# Renders menu path for currently selected page.
########################################################################
def path
  html = ''
  a = []
  m = DcBigMenu.find( @parent.page.menu_id )
  a << m
  while m.parent 
    m = DcBigMenu.find( m.parent )
    a << m
  end
#  
  (a.size - 1).downto(0) do |i| 
    html << "<span id=menu-path-#{a.size - 1 - i}>"
    html << link_4menu(a[i]) 
    html << (i > 0 ? ' &raquo; ' : '') #&rsaquo;&#10132;
    html << '</span>'
  end
# Save level to parents params object
  @parent.params[:menu_level] = a.size
  html
end

########################################################################
# Default methods renders top two levels of menu on top of page.
########################################################################
def default
  html = '<div class="menu0-div"><ul>'
  @selected = find_selected
  level_0 = DcBigMenu.where(dc_site_id: @site._id, parent: nil, active: true).sort(order: 1).to_a
  level_0.each do |item|
# menu can be hidden from user    
    can_view, msg = dc_user_can_view(@parent, item)
    next unless can_view
    klas = item.id == @selected.id ? "menu0-selected" : "menu0-item"
    html << "<li class='#{klas}'>#{ link_4menu(item) }</li>\n"
  end
  html << "</ul></div>"
# submenu
  level_1 = DcBigMenu.where(dc_site_id: @site._id, parent: @selected.id, active: true).sort(order: 1).to_a
  html << "<div class='menu1-div'><ul>\n"
  level_1.each do |item1|
# menu can be hidden from user    
    can_view, msg = dc_user_can_view(@parent, item1)
    next unless can_view
    html << "  <li class='menu1-item'>#{link_4menu(item1)}</li>\n"
  end
  html << '</ul></div>'
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcBigMenu: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @menu ? "#{@menu.css}\n #{@selected ? @selected.css : ''}\n" : ''
end

end
