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
# Default menu renderer for dc_menus collection. Renderer produces output for 
# rendering menu with (theoretically) infinite level of sub menus. In practice 
# reasonable maximum level of 4 is advised.
# 
# Example (as used in design):
#    dc_render(:dc_menu, name: 'my_menu')
#    # when :name option is ommited it will use site document's menu_name field
#    dc_render(:dc_menu)
########################################################################
class DcMenuRenderer

include DcApplicationHelper
########################################################################
# Object initialization. Will also prepare DcMenu document.
########################################################################
def initialize( parent, opts ) #:nodoc:
  @parent = parent
  @menu = opts[:name] ?
    DcMenu.find_by(name: opts[:name].to_s) :
    DcMenu.find(@parent.site.menu_id)
  @opts = opts
  self
end

########################################################################
# Return selected topmenu level.
########################################################################
def find_selected
  if @parent.page.menu_id
    top_menu_id = @parent.page.menu_id
    top_menu_id = @parent.page.menu_id.split(';')[1] if @parent.page.menu_id.match(';')
    ret = @menu.dc_menu_items.find(top_menu_id)
  end
# return first if not found (something is wrong)
  ret ||= @menu.dc_menu_items[0]
end

########################################################################
# Creates edit link if in edit mode.
########################################################################
def link_4edit(opts) #:nodoc:
  html = ''
#  return html unless @opts[:edit_mode] > 1

  opts.merge!( { controller: 'cmsedit', action: 'edit' } )
  title = "#{t('drgcms.edit')}: "
  opts[:title] = "#{title} #{opts[:title]}"
  
  html << '<li>'+dc_link_for_edit(opts)+'</li>'
end

########################################################################
# Returns html code required to create single link in a menu. Subroutine of do_menu_level.
########################################################################
def link_4menu(item)
# prepand to link  
  link = if !item.link_prepend.blank?
    item.link_prepend
  elsif !@menu.link_prepend.blank?
    @menu.link_prepend
  else
    ''
  end
  
  if item.link.match('http')
    link = item.link
  else
    link += (item.link[0] == '/' ? '' : '/') + item.link
    link  = '/' + link unless link[0] == '/'   # link should start with '/'
  end

  target = item.target.blank? ? nil : item.target
# - in first place won't write caption text
  caption   = item.caption[0] == '-' ? '' : item.caption.to_s
  img_title = item.caption.to_s.sub('-','')
# add picture if picture is not blank
  (item.picture.blank? ? '' : 
    @parent.link_to( @parent.image_tag(item.picture), link, {title: img_title, target: target} )) +
  (caption.blank? ? '' : 
    @parent.link_to(caption, link, {target: target}) )
end

########################################################################
# Creates HTML code required for submenu on single level. Subroutine of default.
########################################################################
def do_menu_level(menu, options={})
  html = "<ul id=\"#{menu.name}\">"
  if @opts[:edit_mode] > 1
    options[:title] = menu.respond_to?('name') ? menu.name : menu.caption # 1. level or submenus
    options[:id] = menu._id
    html << link_4edit(options)
  end
# sort items acording to :order  
  menu.dc_menu_items.order_by(order: 1).each do |item|
    next unless item.active
# menu can be hidden from user    
    can_view, msg = dc_user_can_view(@parent, item)
    next unless can_view
    
    html << if item.id == @selected.id 
      "<li class=\"menu-selected\">#{ link_4menu(item) }"
    else
      "<li>#{ link_4menu(item) }"
    end
# do submenu    
    if (sub = item.dc_menu_items).size > 0
      if @opts[:edit_mode] > 1
        opts = options.clone
        opts['ids']   = (opts['ids']   ? "#{opts['ids']};" : '')   + menu._id.to_s
        opts['table'] = (opts['table'] ? "#{opts['table']};" : '') + 'dc_menu_item'
        opts['form_name'] = nil # must be
      end
      html << do_menu_level(item, opts)
    end
    html << '</li>'
  end
  html << '</ul>'
end

########################################################################
# Creates default menu.
########################################################################
def default
  return "(#{@opts[:name]}) menu not found!" if @menu.nil?
#  
  @selected = find_selected
  html = ''
  html << "<div id='#{@menu.div_name}'>" unless @menu.div_name.blank?  
  html << do_menu_level(@menu, table: 'dc_menu')
  html << "</div>" unless @menu.div_name.blank? 
  html
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcMenu: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @menu.css if @menu
end

end
