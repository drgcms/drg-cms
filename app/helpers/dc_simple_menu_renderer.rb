#coding: utf-8
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
# Before dc_menu dc_simple_menu was the way to provide menu system. Renderer
# provides 3 different renderer methods: default, as_dropdown, as_table. 
# 
# Example (as used in design):
#    dc_render(:dc_simple_menu, name: 'my_menu', method: 'as_table')
#    
# If name parameter is omitted it must be provided in site document menu_name field.
########################################################################
class DcSimpleMenuRenderer

include DcApplicationHelper
########################################################################
# Object initialization.
########################################################################
def initialize( parent, opts )
  @parent = parent
  opts[:name] = parent.site.menu_name if opts[:name].nil? # default in site
  @menu = DcSimpleMenu.find_by(name: opts[:name].to_s)
  @opts = opts
  self
end

########################################################################
# Return selected top level menu document. Subroutine of menu renders. 
########################################################################
def find_selected #:nodoc:
  ret = @menu.dc_simple_menu_items.find( @parent.page.menu_id ) if @parent.page.menu_id
# return first if not found (something is wrong)
  ret ||= @menu.dc_simple_menu_items[0]
end

########################################################################
# Creates edit icon for menu if in edit mode.
########################################################################
def link_4edit()  #:nodoc:
  html = ''
  return html unless @opts[:edit_mode] > 1
#
  @opts[:editparams].merge!( { table: 'dc_simple_menu', controller: 'cmsedit', action: 'edit' } )
  if @menu # edit, when menu exists
    title = "#{t('drgcms.edit')}: "
    @opts[:editparams].merge!( { id: @menu.id, title: "#{title}#{@menu.name}" } ) 
    html << dc_link_for_edit( @opts[:editparams] )
  else # list available menus when menu does not yet exist
    title = "#{t('drgcms.new')}: "
    title << t('helpers.label.dc_simple_menu.tabletitle')
    @opts[:editparams].merge!( { action: 'index', title: title })
    html << dc_link_for_create( @opts[:editparams] )
  end
  html
end

########################################################################
# Returns html code required for creating one link in a menu.
# 
# Parameters:
# [item] SimpleMenuItem.
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
  caption = item.caption[0] == '-' ? '' : item.caption.to_s
  img_title = item.caption.to_s.sub('-','')
  (item.picture.blank? ? '' : @parent.link_to( @parent.image_tag(item.picture), link, {title: img_title, target: target} )) +
  ( caption.blank? ? '' : @parent.link_to(caption, link, {target: target}))
end

########################################################################
# Renders menu as table. This is single level menu only and uses table elements to 
# display menu options evenly justified. 
########################################################################
def as_table
  html = link_4edit
  return "#{html}#{@opts[:name]}<br>Menu not found!" if @menu.nil?
#  
  @selected = find_selected
# use div_name if specified otherwise menu.name  
  div_name  = (@menu.div_name.to_s.size > 2 ? @menu.div_name : @menu.name).downcase
  html << "<table class=\"#{div_name}\"><tr>"
#
  items = @menu.dc_simple_menu_items.where(active: true).order(order: 1)
  items.each do |item|
# menu can be hidden from user
    can_view, msg = dc_user_can_view(@parent, item)
    next unless can_view
    
    klas = item.id == @selected.id ? "#{div_name}-selected" : "#{div_name}-item"
    html << "<td class=\"td-#{klas}\">#{ link_4menu(item) }</td>" #
  end
  html << "</tr></table>"
end
########################################################################
# Renders menu as table. This is single level menu only and uses table elements to 
# display menu options evenly justified. 
########################################################################
def as_responsive
  html = link_4edit
  return "#{html}#{@opts[:name]}<br>Menu not found!" if @menu.nil?
#  
  @selected = find_selected
  klas = @opts[:classes] ? @opts[:classes] : 'small-2 middle-4 large-6 columns'
  klas << ' columns' unless klas.match('column')
  klas=''
#  
  items = @menu.dc_simple_menu_items.where(active: true).order(order: 1)
  items.each do |item|
# menu can be hidden from user
    can_view, msg = dc_user_can_view(@parent, item)
    p msg unless can_view
    next unless can_view
    html << "<li class=\"#{klas}#{(item.id == @selected.id) ? 'selected' : 'item'}\">#{ link_4menu(item) }</li>" #
  end
  html
end

########################################################################
# Creates menu with single level dropdown menu. This is older version of method which
# also provided select field for selecting menu if mobile device is beeing detected.
########################################################################
def as_dropdown_old
  html = link_4edit
  return "#{html}#{@opts[:name]}<br>Menu not found!" if @menu.nil?
  # 
  items = @menu.dc_simple_menu_items.sort {|a,b| a.order <=> b.order}
# CSS dropdown-s don't work very well on mobiles. Create simple select menu instead 
  if @parent.session[:is_mobile] == 1
    html << "<div class=\"#{@menu.name.downcase}-mobile\">\n"
    html << '<select onchange="window.location.href=this.options[this.selectedIndex].value">'
    html << "<option value=\"\">#{t('drgcms.simple_menu_mobile_menu_text',' M E N U ')}</option>"
#    
    items.each do |item|
      next unless item.active
      # menu can be hidden from user    
      can_view, msg = dc_user_can_view(@parent, item)
      next unless can_view
      html << "<option value=\"#{item.link}\">#{item.caption}</option>"
      y = YAML.load(item.submenu) || {}
      y.each { |k,v| html << "<option value=\"#{v['link']}\">--#{v['title']}</option>" }
    end    
    html << "</select>\n</div>\n"
  else  
    @selected = find_selected
    html << "<table class=\"#{@menu.name.downcase}\"><tr>"
    # sort items acording to :order  
    items.each do |item|
      next unless item.active
      # menu can be hidden from user    
      can_view, msg = dc_user_can_view(@parent, item)
      next unless can_view
      
      klas = item.id == @selected.id ? 'menu-selected' : 'menu-item'
#      caption = item.caption.match('pic:') ? @parent.image_tag(item.caption.sub('pic:','')) : item.caption
      html << "<td class=\"td-#{klas}\">#{ link_4menu(item) }"
      y = YAML.load(item.submenu) || {}
      if y.size > 0
        html << '<ul>'
        y.each do |k,v|
          html << "<li>#{@parent.link_to(v['title'], v['link'], {target: v['target']})}</li>"
        end
        html << '</ul>'
      end
      html << '</td>'
    end
    html << '</tr></table>'
  end
end

########################################################################
# Creates menu with single level dropdown menu.
########################################################################
def as_dropdown
  html = link_4edit
  return "#{html}#{@opts[:name]}<br>Menu not found!" if @menu.nil?
  # 
  items = @menu.dc_simple_menu_items.sort {|a,b| a.order <=> b.order}
  @selected = find_selected

  html << "<div id='#{@menu.div_name}'>" unless @menu.div_name.blank?
  html << '<table><tr>'
  # sort items acording to :order 
  items.each do |item|
    next unless item.active
    # menu can be hidden from user    
    can_view, msg = dc_user_can_view(@parent, item)
    next unless can_view
#
    selector = item.id == @selected.id ? 'th' : 'td'
    html << "<#{selector}>#{ link_4menu(item) }"
    y = YAML.load(item.submenu) || {}
    if y.size > 0
      html << '<ul>'
      y.each do |k,v|
        html << "<li>#{@parent.link_to(v['title'], v['link'], {target: v['target']})}</li>"
      end
      html << '</ul>'
    end
    html << "</#{selector}>"

  end
  html << '</tr></table>'
  html << '</div>' unless @menu.div_name.blank?
  html
end

########################################################################
# Default renderer provides top menu menu with submenu items displayed in a line (div) below.
# 
# Top menu and submenu items are styled separately. If div_name is specified in
# menu document it will be used in div, ul and li CSS names of generated HTML code. 
# If div_name is not defined then document name will be used.
########################################################################
def default
  html = link_4edit
  return "#{html}#{@opts[:name]}<br>Menu not found!" if @menu.nil?
#  
  @selected = find_selected
# use div_name if specified otherwise menu.name  
  div_name  = (@menu.div_name.to_s.size > 2 ? @menu.div_name : @menu.name).downcase
  html << "<div class=\"#{div_name}\">"
  html << "<ul class=\"ul-#{div_name}\">"
# sort items acording to :order  
  items = @menu.dc_simple_menu_items.sort {|a,b| a.order <=> b.order}
  items.each do |item|
    next unless item.active
# menu can be hidden from user 
    can_view, msg = dc_user_can_view(@parent, item)
    next unless can_view
    
    klas = item.id == @selected.id ? "#{div_name}-selected" : "#{div_name}-item"
    html << "<li class=\"li-#{klas}\">#{ link_4menu(item) }</li>"
  end
  html << "</ul></div>"
# submenu
  html << "<div class=\"sub-#{div_name}\">
        <ul class=\"ul-sub-#{div_name}\">"
  y = YAML.load(@selected.submenu) rescue []
  if y.class == Array
    y.each do |k,v|
      html << "<li class=\"li-sub-#{div_name}\">#{@parent.link_to(v['title'], v['link'])}</li>"
    end
  end
  html << '</ul></div>'
end


########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcSimpleMenu: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @menu ? "#{@menu.css}\n #{@selected ? @selected.css : ''}\n" : ''
end

end
