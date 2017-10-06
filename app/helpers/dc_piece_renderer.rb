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
# Piece renderer renders data from dc_piece collection documents. 
# 
# Example:
#    <div id="page">
#      <%= dc_render(:dc_piece, :name => 'some_piece') %>
#    </div>
#
########################################################################
class DcPieceRenderer

include DcApplicationHelper

########################################################################
# Object initialization. It also loads requested dc_piece document.
########################################################################
def initialize( parent, opts={} ) #:nodoc:
  @parent = parent
  @opts   = opts
  @piece  = DcPiece.find(opts[:id]) if opts[:id]
  if @piece.nil? # alternatively find by name
    name = opts[:name] || opts[:id]
    @piece = if @opts[:site] 
      DcPiece.find_by(name: name, site_id: dc_get_site._id) 
    else 
      DcPiece.find_by(name: name) 
    end
  end
end

#########################################################################
# Return link code for editing this piece.
########################################################################
def link_4edit()
  html = ''
  return html if @opts[:edit_mode] < 2
  @opts[:editparams].merge!( { table: 'dc_piece', 
                               formname: 'dc_piece', 
                               controller: 'cmsedit', 
                               action: 'edit', 
                               id: @piece.id,
                               title: "#{t('drgcms.edit')}: #{@piece.name}" } )
  html << dc_link_for_edit( @opts[:editparams] )
end

########################################################################
# Script renderer method expects rails erb code (view) in the script field.
# Used for designs with common code which can be shared and one part which is different.
# It's functionality can be replaced with dc_replace_in_design method with 'piece' option 
# specified.
# 
# Example: As used in design. Backslashing < and % is important \<\%
# <% part = "<div  class='some-class'>\<\%= dc_render(:my_renderer, method: 'render_method') \%\></div>" %>
# <%= dc_render(:dc_piece, id: 'common', method: 'script', replace: '[main]', with: part) %>
# 
# Want to replace more than one part. Use array.
# <%= dc_render(:dc_piece, id: 'common', method: 'script', replace: ['[part1]','[part2]'], with: [part1, part2]) %>
########################################################################
def script
  s = @piece.script
  if @opts[:replace]
# replace more than one part of code
    if @opts[:replace].class == Array
      0.upto(@opts[:replace].size - 1) {|i| s.sub!(@opts[:replace][i], @opts[:with][i])}
    else
      s.sub!(@opts[:replace], @opts[:with])
    end
  end
  @parent.render(inline: s, layout: @opts[:layout])
end

#########################################################################
# Default DcPiece render method. 
########################################################################
def default
  html = link_4edit()
  html << @piece.body
end

#########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  return "DcPiece #{@opts[:id]} #{@opts[:name]} not found!" unless @piece
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcPiece: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @piece ? "#{@piece.css}" : ''
end

end
