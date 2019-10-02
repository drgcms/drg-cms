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
# Renders one or multiple parts grouped by div_id field.
# Parts are scoped from design, page and dc_pieces documents.
# 
# Example (as used in design):
#    <div id='div-main'>
#      <div id='div-left'> <%= dc_render(:dc_part, position: 'left') %></div>
#      <div id='page'> <%= dc_render(:dc_page) %></div>
#      <div id='div-right'>
#        <%= dc_render(:dc_part, method: 'in_page', name: 'welcome')
#        <%= dc_render(:dc_part, position: 'right')</div>
#      </div>
#    </div>
#    
# Main page division in example is divided into 3 divisions. div-left, page and div-right.
# div-left and div-right are populated with parts containing 'left' and 'right' div_id value. 
# In addition part with name 'welcome' is located above 'right' parts.
########################################################################
class DcPartRenderer

include DcApplicationHelper

########################################################################
# Object initialization.
########################################################################
def initialize( parent, opts={} ) #:nodoc:
  @parent   = parent
  @opts     = opts
  @part_css = ''
  self
end

########################################################################
# Method returns output from single part(icle). It checks if policy allows part to 
# be viewed on page and ads links for editing when in edit mode.
########################################################################
def render_particle(particle, opts)
  # Check if policy allows to view page
  can_view, msg = dc_user_can_view(@parent, particle)
  return msg unless can_view
  html = ''
  if @opts[:edit_mode] > 1
    opts[:editparams].merge!(title: "#{t('drgcms.edit')}: #{particle.name}", controller: :cmsedit)    
    html << dc_link_for_edit( opts[:editparams] )
  end
#
=begin
  if particle.piece_id
    opts[:id] = particle.piece_id
    piece = DcPieceRenderer.new(@parent, opts)
    html << piece.render_html
    @part_css << piece.render_css    
  else
    html << particle.body
    @part_css << particle.css.to_s
  end
=end
  @part_css << particle.css.to_s
  html << particle.body
end

########################################################################
# Load all parts defined in design, page or piece collection into memory. 
# Subroutine of default method.
########################################################################
def load_parts #:nodoc:
  @parent.parts = []
# Start with parts in design. Collect to array and add values needed for editing
  if @parent.design
    @parent.design.dc_parts.where(active: true).each do |part|
      type = decamelize_type(part._type) || 'dc_part'
      @parent.parts << [part, @parent.design.id, type, "dc_design;#{type}"]
    end
  end
# add parts in page
  @parent.page.dc_parts.where(active: true).each do |part|
    type = decamelize_type(part._type) || 'dc_part'
    @parent.parts << [part, @parent.page.id, type, "#{@parent.site.page_class.underscore};#{type}"]
  end
# add parts in site
  @parent.site.dc_parts.where(active: true).each do |part|
    type = decamelize_type(part._type) || 'dc_part'
    @parent.parts << [part, @parent.site.id, type, "dc_site;#{type}"]
  end
# add parts belonging to site, defined in dc_pieces
  DcPiece.where(site_id: @parent.site._id, active: true).each do |part|
    @parent.parts << [part, part._id, 'dc_piece', 'dc_piece']
  end
end  

########################################################################
# Default method collects all parts with the div_id field value defined by position option.
# If more then one parts have same div_id they will be sorted by order field. Method
# also loads all parts from design, page and pieces collections and cache them for 
# consecutive calls.
# 
# Options: 
# [position] String. Position (value of div_id) where parts will be rendered.
# 
# Example (as used in design):
#     <div id='div-right'>
#       <%= dc_render(:dc_part, position: 'right')
#     </div>
########################################################################
def default
  html = "<div class=\"#{@opts[:div_class]}\">"
# Load all parts only once per call  
  load_parts if @parent.parts.nil?
  dc_deprecate 'DcPart: Parameter location will be deprecated! Please use position keyword.' if @opts['location']
  
  @opts[:position] ||= @opts['position'] # symbols are not strings. Ensure that it works.
# Select parts
  parts = []
  @parent.parts.each { |v| parts << v if v[0].div_id == @opts[:position] }
# Edit link
  @opts[:editparams].merge!( { controller: 'cmsedit', action: 'edit' } )
  if parts.size > 0
    parts.sort! {|a,b| a[0].order <=> b[0].order }
  
    parts.each do |part| 
      @opts[:editparams].merge!( id: part[0], ids: "#{part[1]}", form_name: part[2], table: part[3] )
      html << render_particle(part[0], @opts) 
    end
  end
  html << "</div>"
end

########################################################################
# This method will search and render single part defined in pages file. Part may
# be defined in current page document or in any page document found in pages file. Parameters
# are send through options hash. 
# 
# Options: 
# [name] String. dc_parts name.
# [page_id] String. Page document _id where part document is saved. Defaults to current page.
# [page_link] String. Page may alternatively be found by subject_link field.
########################################################################
def in_page
# Part is in page with id  
  page = if @opts[:page_id]
    pageclass = @parent.site.page_klass
    pageclass.find(@opts[:page_id])
# Part is in page with subject link
  elsif @opts[:page_link]
    pageclass = @parent.site.page_klass
    @page = pageclass.find_by(dc_site_id: @parent.site._id, subject_link: @opts[:page_link])
# Part is in current page
  else
    @parent.page
  end
  return "Error DcPart: Page not found!" if page.nil?
#  
  if part = page.dc_parts.find_by(name: @opts[:name])
    @opts[:editparams].merge!(id: part, ids: page._id, form_name: 'dc_part', table: "#{@parent.site.page_class.underscore};dc_part" )
    render_particle(part, @opts) 
  else
    "Part with name #{@opts[:name]} not found in page!"
  end
end

########################################################################
# Renderer for single datapage kind of sites.
########################################################################
def single_sitedoc
# if div_id option specified search for part with this div_id. 
# This can be used to render footer or header of site.
  part = if @opts[:div_id]
    @parent.parts.find_by(div_id: @opts[:div_id])
  else
    @parent.part
  end
# part not found. Render error message.
  return "Part #{@opts[:div_id]} not found!" if part.nil?
# prepare edit parameters  
  @opts[:editparams].merge!(id: part, ids: @parent.site._id, form_name: 'dc_part', 
                            table: "dc_site;dc_part", record_div_id: 'document' )
  render_particle(part, @opts) 
end

########################################################################
# Render menu for single datapage kind of sites.
########################################################################
def single_sitedoc_menu
# prepare div markup
  menu_div = @opts[:menu_div] ? "id=#{@opts[:menu_div]}" : ''
  html = "<div #{menu_div}><ul>\n"
# collect all dc_part documents which make menu
  @parent.parts.where(div_id: 'document').order_by(order: 1).each do |part|
# mark selected item    
    selected = (part == @parent.part) ? 'class="menu-selected"' : ''
    html << "<li #{selected}>#{ @parent.link_to(part.name, part.link ) }</li>\n"
  end
  html << "</ul></div>\n"
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcPart: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @part_css
end

end
