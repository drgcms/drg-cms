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
# Implementation of embedded DRG CMS form field.
#
# Creates html required to paint embedded object on form.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ embedded (required)
# * +form_name:+ name of form which will be used for editing
# * +load:+ when is embedded iframe loaded. default=on form load, delay=on tab select, always=every time tab is selected)
# * +html:+ html options (optional)
#   * +height:+ height of embedded object in pixels (1000)
#   * +width:+ width of embedded object in pixels (500)
# 
# Form example:
#    10:
#      name: dc_parts
#      type: embedded
#      form_name: dc_part
#      refresh: delay
#      html:
#        height: 1000
###########################################################################
class Embedded < DrgcmsField
###########################################################################
# Render embedded field html code
###########################################################################
def render
  # HTML defaults. Some must be set    
  @yaml['html'] ||= {}
  @yaml['html']['height'] ||= 300
  @yaml['html']['width']  ||= '99%'
  @yaml['action'] ||= 'index'
  # defaults both way 
  @yaml['table']     ||= @yaml['form_name'] if @yaml['form_name']
  @yaml['form_name'] ||= @yaml['table'] if @yaml['table']

  html = ''  
  @yaml['html'].each {|k,v| html << "#{k}=\"#{v}\" "}

  if @yaml['name'] == @yaml['table'] or @yaml['table'] == 'dc_memory'
    tables = @yaml['table']
    ids    = @record.id
  else
    tables = @parent.tables.inject('') { |r,v| r << "#{v[1]};" } + @yaml['table']
    ids    = @parent.ids.inject('') { |r,v| r << "#{v};" } + @record.id
  end
  opts = { controller: 'cmsedit', action: @yaml['action'], 
           ids: ids, table: tables, form_name: @yaml['form_name'], 
           field_name: @yaml['name'], iframe: "if_#{@yaml['name']}", readonly: @readonly }
  # additional parameters if specified
  @yaml['params'].each { |k,v| opts[k] = @parent.dc_value_for_parameter(v) } if @yaml['params']         
         
  @html << "<iframe class='iframe_embedded' id='if_#{@yaml['name']}' name='if_#{@yaml['name']}' #{html}></iframe>"
  unless @record.new_record?
    url  = @parent.url_for(opts)
    data = if @yaml['load'].nil? || @yaml['load'].match('default')
      "src"
    else
      "data-src-#{@yaml['load']}"
    end
    @js << %Q[
$(document).ready( function() {
  $('#if_#{@yaml['name']}').attr('#{data}', '#{url}');
});]
  end
  self
end

end

end
