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
# Implementation of number_field DRG CMS form field. Number fields can be 
# formated for display with thousands delimiters and decimal separators and 
# can have currency symbol.
# 
# ===Form options:
# * +type:+ number_field (required)
# * +name:+ Field name (required) 
# * +format:+ Format options
# *   +decimals:+ No of decimal places
# *   +separator:+ decimal separator (yes no , .) Default yes if decimals > 0
# *   +delimiter:+ Thousands delimiter (yes no , .) Default defind by locals
# *   +currency:+ Currency sign (yes no sign) Default no. If yes defined by locals
# * +html:+ html options which apply to text_field field (optional)
# 
# Form example:
#    10:
#      name: title
#      type: number_field
#      size: 10
#      format:
#        decimals: 2
#        delimiter: false
###########################################################################
class NumberField < DrgcmsField
  
###########################################################################
# Render text_field field html code
###########################################################################
def render
  return ro_standard if @readonly
  set_initial_value
#
  record = record_text_for(@yaml['name'])
  @yaml['html'] ||= {}
  @yaml['html']['class'] = 'dc-number'
  if @yaml['format'].class == String
    format = @yaml['format']
    @yaml['format'] = {}
    @yaml['format']['decimal'] = format[1].blank? ? 2 : format[1].to_i
    @yaml['format']['separator'] = format[2].blank? ? I18n.t('number.currency.format.separator') : format[2]
    @yaml['format']['delimiter'] = format[3].blank? ? I18n.t('number.currency.format.delimiter') : format[3]
  end
  @yaml['html']['data-decimal']   = @yaml.dig('format','decimal') || 2
  @yaml['html']['data-delimiter'] = @yaml.dig('format','delimiter') || I18n.t('number.currency.format.delimiter')
  @yaml['html']['data-separator'] = @yaml.dig('format','separator') || I18n.t('number.currency.format.separator')
 # @yaml['html']['data-currency']  = @yaml.dig('format','currency') == 'yes' ? I18n.t('number.currency.format.currency') : @yaml.dig('format','currency')
  value = @record[@yaml['name']] || 0 
    
  @html << @parent.hidden_field( record, @yaml['name'], value: value )
  
  @yaml['html']['value'] = @parent.dc_format_number(value, @yaml['html']['data-decimal'], @yaml['html']['data-separator'], @yaml['html']['data-delimiter'] )
  @html << @parent.text_field( nil,"record_#{@yaml['name']}1", @yaml['html']) 
  self
end

###########################################################################
# Return value. Return nil if input field is empty
###########################################################################
def self.get_data(params, name)
  return 0 if params['record'][name].blank?
  params['record'][name].match('.') ? BigDecimal.new(params['record'][name]) : Integer.new(params['record'][name])
end

end
end
