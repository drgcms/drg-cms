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
# Implementation of date_picker DRG CMS form field with help of jQuery DateTimePicker plugin.
# 
# Since javascript date(time) format differs from ruby date(time) format localization
# must be provided in order for date_picker object works as expected. For example:
# 
#   en:
#    datetimepicker: 
#     formats:
#     date: 'Y/m/d'
#     datetime: 'Y/m/d H:i'
#
#   sl:
#    datetimepicker: 
#     formats:
#      date: 'd.m.Y'
#      datetime: 'd.m.Y H:i'
#
# ===Form options:
# * +type:+ date_picker (required)
# * +name:+ Field name (required) 
# * +options:+ options which apply to date_picker field. All options can be found here http://xdsoft.net/jqplugins/datetimepicker/ .
# Options can be defined in single line like:
# * options: 'inline: true,lang: "sl"' or
# 
# * options: 
#   * inline: true
#   * lang: '"sl"'
#   
# * +html:+ html options which apply to date_picker field (optional)
# 
# Form example:
#    10:
#      name: created
#      type: date_picker
#      options: 'inline: true,lang: "sl"'
###########################################################################
class DatePicker < DrgcmsField
  
###########################################################################
# Render date_picker field html code
###########################################################################
def render
  value = (@record and @record[@yaml['name']]) ? I18n.localize(@record[@yaml['name']].to_date) : nil
  return ro_standard( @parent.dc_format_value(value)) if @readonly
#
  @yaml['options'] ||= {}
  set_initial_value
  @yaml['html']['size'] ||= 10
  @yaml['html']['value'] = value
#
  @yaml['options']['lang']   ||= "'#{I18n.locale}'"
  @yaml['options']['format'] ||= "'#{t('datetimepicker.formats.date')}'"
  @yaml['options']['timepicker'] = false
# 
  record = record_text_for(@yaml['name'])
  @html << @parent.text_field(record, @yaml['name'], @yaml['html'])
  @js << <<EOJS
$(document).ready(function() {
  $("##{record}_#{@yaml['name']}").datetimepicker( {
    #{hash_to_options(@yaml['options'])}
  });
});
EOJS
  
  self
end

###########################################################################
# DatePicker get_data method.
###########################################################################
def self.get_data(params, name)
  t = params['record'][name] ? params['record'][name].to_datetime : nil
  t ? Time.zone.local(t.year, t.month, t.day) : nil
end

end
end
