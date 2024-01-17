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
  @yaml['html']['width'] ||= '99%'
  # message when new record
  if @record.new_record?
    @yaml['html']['srcdoc'] = %(
<div style='font-family: helvetica; font-size: 1.7rem; font-weight: bold; color: #ddd; padding: 1rem'>
  #{I18n.t('drgcms.iframe_save_to_view')}
</div>)
  end
  html = @yaml['html'].inject('') { |r, val| r << "#{val.first}=\"#{val.last}\" " }

  @yaml['action'] ||= 'index'
  # defaults both way 
  @yaml['table']     ||= @yaml['form_name']
  @yaml['form_name'] ||= @yaml['table']

  if @yaml['name'] == @yaml['table'] || @yaml['table'] == 'dc_memory'
    tables = @yaml['table']
    ids    = @record.id
  else
    tables = (@parent.tables.map(&:first) + [@yaml['table']]).join(';')
    ids    = (@parent.ids + [@record.id]).join(';')
  end
  # edit enabled embedded form on a readonly form
  readonly = @yaml['readonly'].class == FalseClass ? nil : @readonly
  opts = { controller: 'cmsedit', action: @yaml['action'],
           ids: ids, table: tables, form_name: @yaml['form_name'], 
           field_name: @yaml['name'], iframe: "if_#{@yaml['name']}", readonly: readonly }
  # additional parameters if specified
  @yaml['params'].each { |k, v| opts[k] = @parent.dc_value_for_parameter(v) } if @yaml['params']

  @html << "<iframe class='iframe_embedded' id='if_#{@yaml['name']}' name='if_#{@yaml['name']}' #{html}></iframe>"
  if @record.new_record?
  else
    url = @parent.url_for(opts)
    attributes = case
                 when @yaml['load'].nil? || @yaml['load'].match('default')
                   "'src', '#{url}'"
                 when @yaml['load'].match('delay')
                   "'data-src-#{@yaml['load']}', '#{url}'"
                 when @yaml['load'].match('always')
                   "{'data-src-#{@yaml['load']}': '#{url}', src: '#{url}'}"
                 end
    @js << %(
$(document).ready( function() {
  $('#if_#{@yaml['name']}').attr(#{attributes});
});)
  end
  self
end

end

end
