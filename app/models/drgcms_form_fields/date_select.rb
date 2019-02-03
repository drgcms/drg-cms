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
# Implementation of date_select DRG CMS form field.
# 
# ===Form options:
# * +type:+ date_select (required)
# * +name:+ Field name (required) 
# * +options:+ options which apply to date_select field (optional)
# * +html:+ html options which apply to password field (optional)
# 
# Form example:
#    50:
#      name: valid_from
#      type: date_select
#      options:
#        include_blank: true
#      html:
#        class: my-date-class 
###########################################################################
class DateSelect < DrgcmsField
   
###########################################################################
# Render date_select field html code
###########################################################################
def render
  return ro_standard( @parent.dc_format_value(@record[@yaml['name']])) if @readonly
#
  @yaml['options'] ||= {}
  set_initial_value('options','default')
  @yaml['options'].symbolize_keys!
  @yaml['html'].symbolize_keys!
  record = record_text_for(@yaml['name'])
  @html << @parent.date_select(record, @yaml['name'], @yaml['options'], @yaml['html'])
  self
end

###########################################################################
# DatetimeSelect get_data method.
###########################################################################
def self.get_data(params, name)
  DatetimeSelect.get_data(params, name).to_date rescue nil
end

end
end
