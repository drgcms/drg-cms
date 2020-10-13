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
# Implementation of date_time_picker DRG CMS form field with help of jQuery DateTimePicker plugin
# 
# ===Form options:
# * +type:+ datetime_picker (required)
# * +name:+ Field name (required) 
# * +options:+ options which apply to date_picker field. All options can be found here http://xdsoft.net/jqplugins/datetimepicker/ .
# Options can be defined in single line like:
# * options: 'step: 15,inline: true,lang: "sl"' or
# 
# * options: 
#   * step: 15
#   * inline: true
#   * lang: '"sl"'
#   
# * +html:+ html options which apply to date_time_picker field (optional)
# 
# Form example:
#    10:
#      name: valid_to
#      type: datetime_picker
#      options: 'step: 60'
###########################################################################
class DatetimePicker < DrgcmsField
  
###########################################################################
# Render date_time_picker field html code
###########################################################################
def render
  value = @record.try(@yaml['name']) ? I18n.localize(@record[@yaml['name']].localtime) : nil
  #return ro_standard( @parent.dc_format_value(value)) if @readonly

  @yaml['options'] ||= {}
  set_initial_value
  @yaml['html']['size'] ||= @yaml['size'] || 14
  @yaml['html']['value'] ||= value if @record[@yaml['name']]
  @yaml['html']['autocomplete'] ||= 'off'
  @yaml['html']['class'] = @yaml['html']['class'].to_s + ' date-picker'

  @yaml['options']['lang']   ||= "'#{I18n.locale}'"
  @yaml['options']['format'] ||= "'#{t('datetimepicker.formats.datetime')}'"

  record = record_text_for(@yaml['name'])
  @html << @parent.text_field(record, @yaml['name'], @yaml['html'])
  @js << %Q[
$(document).ready(function() {
  $("##{record}_#{@yaml['name']}").datetimepicker( {
    #{hash_to_options(@yaml['options'])}
  });
}); 
] unless @readonly
  
  self
end

###########################################################################
# DateTimePicker get_data method.
###########################################################################
def self.get_data(params, name)
  t = params['record'][name] ? params['record'][name].to_datetime : nil
  t ? Time.zone.local(t.year, t.month, t.day, t.hour, t.min) : nil
end

end
end
