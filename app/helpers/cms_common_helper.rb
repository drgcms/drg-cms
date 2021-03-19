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


####################################################################
# Common methods which may also come handy in controllers or models or any
# other module of program.
# 
# Usage: include CmsCommonHelper
####################################################################
module CmsCommonHelper
  
####################################################################
# Wrapper for i18 t method, with some spice added. If translation is not found English
# translation value will be returned. And if still not found default value will be returned if passed.
# 
# Parameters:
# [key] String. String to be translated into locale.
# [default] String. Value returned if translation is not found.
# 
# Example:
#    t('translate.this','Enter text for ....')
# 
# Returns: 
# String. Translated text. 
####################################################################
def self.t(key, default=nil)
  c = I18n.t(key)
  if c.class == Hash or c.match( 'translation missing' )
    c = I18n.t(key, locale: 'en') 
# Still not found. Return default if set
    if c.class == Hash or c.match( 'translation missing' )
      c = default.nil? ? key : default
    end
  end
  c
end

####################################################################
def t(key, default=nil) #:nodoc
  CmsCommonHelper.t(key, default)
end

####################################################################
# Returns table (collection) name translation for usage in dialog title. Tablename 
# title is provided by helpers.label.table_name.tabletitle locale.
# 
# Parameters:
# [tablename] String. Table (collection) name to be translated.
# [default] String. Value returned if translation is not found.
# 
# Returns: 
# String. Translated text. 
####################################################################
def t_tablename(tablename, default=nil)
  t('helpers.label.' + tablename + '.tabletitle', default || tablename)
end

############################################################################
# Returns label for field translated to current locale for usage on data entry form.
# Translation is provided by lang.helpers.label.table_name.field_name locale. If
# translation is not found method will capitalize field_name and replace '_' with ' '.
############################################################################
def t_name(field_name, default='')
  c = t("helpers.label.#{@form['table']}.#{field_name}", default)
  c = field_name.capitalize.gsub('_',' ') if c.match( 'translation missing' )
  c
end

###########################################################################
# When select field is used on form options for select can be provided by 
# helpers.label.table_name.choices4_name locale. This is how select
# field options are translated. Method returns selected choice translated
# to current locale. 
# 
# Parameters:
# [model] String. Table (collection) model name (lowercase).
# [field] String. Field name used.
# [value] String. Value of field which translation will be returned.
# 
# Example:
#    # usage in program. Choice values for state are 'Deactivated:0,Active:1,Waiting:2'
#    dc_name4_value('dc_user', 'state', @record.active )
#
#    # usage in form
#    columns:
#      2: 
#        name: state
#        eval: dc_name4_value dc_user, state
#        
# Returns: 
# String. Descriptive text (translated) for selected choice value.
############################################################################
def self.dc_name_for_value(model, field, value)
  return '' if value.nil?
  c = t('helpers.label.' + model + '.choices4_' + field )
  a = c.chomp.split(',').inject([]) {|r,v| r << v.split(':') }
  a.each {|e| return e.first if e.last.to_s == value.to_s }
  '???'
end

############################################################################
def dc_name_for_value(model, field, value)
  CmsCommonHelper.dc_name_for_value(model, field, value)
end

############################################################################
#
############################################################################
def dc_name4_value(model, field, value) #nodoc
  #dc_deprecate('dc_name4_value will be deprecated. Use dc_name_for_value instead.')
  CmsCommonHelper.dc_name_for_value(model, field, value)
end

############################################################################
# Return choices for field in model if choices are defined in localization text.
# 
# Parameters:
# [model] String. Table (collection) model name (lowercase).
# [field] String. Field name used.
# 
# Example:
#    dc_choices4_field('dc_user', 'state' )
#        
# Returns: 
# Array. Choices for select input field
############################################################################
def self.dc_choices_for_field(model, field)
  c = CmsCommonHelper.t('helpers.label.' + model + '.choices4_' + field )
  return ['error'] if c.match( 'translation missing' )
  c.chomp.split(',').inject([]) {|r,v| r << v.split(':') }
end

############################################################################
def dc_choices_for_field(model, field)
  CmsCommonHelper.dc_choices_for_field(model, field)
end

############################################################################
#
############################################################################
def dc_choices4_field(model, field) #nodoc
  #dc_deprecate('dc_choices4_field will be deprecated. Use dc_choices_for_field instead.')
  CmsCommonHelper.dc_choices_for_field(model, field)
end

############################################################################
# Will return descriptive text for id key when field in one table (collection) has belongs_to 
# relation to other table.
# 
# Parameters:
# [model] String. Table (collection) model name (lowercase).
# [field] String. Field name holding the value of descriptive text.
# [field_name] String. ID field name. This is by default id, but can be any other 
# (preferred unique) field.
# [value] Value of id_field. Usually a BSON Key but can be any other data type.
# 
# Example:
#    # usage in program.
#    dc_name4_id('dc_user', 'name', nil, dc_page.created_by)
#
#    # usage in form
#    columns:
#      2: 
#        name: site_id
#        eval: dc_name4_id,site,name
#    # username is saved to document instead of user.id field
#      5: 
#        name: user
#        eval: dc_name4_id,dc_user,name,username
# 
# Returns: 
# String. Name (descriptive value) for specified key in table.
############################################################################
def dc_name_for_id(model, field, field_name, id=nil)
  return '' if id.nil?

  field_name = (field_name || 'id').strip.to_sym
  field = field.strip.to_sym
  model = model.strip.classify.constantize if model.class == String
  doc = Mongoid::QueryCache.cache { model.find_by(field_name => id) }

  doc.nil? ? '' : (doc.send(field) rescue 'not defined')
end

############################################################################
#
############################################################################
def dc_name4_id(model, field, field_name, id=nil) #nodoc
  #dc_deprecate('dc_name4_id will be deprecated. Use dc_name_for_id instead.')
  dc_name_for_id(model, field, field_name, id) 
end

############################################################################
# Return html code for icon presenting boolean value. Icon is a picture of checked or unchecked box.
# 
# Parameters:
# [value] Boolean.  
# 
# Example:
#    # usage from program
#    dc_icon4_boolean(some_value)
#
#    # usage from form description
#    columns:
#      10: 
#        name: active
#        eval: dc_icon4_boolean
############################################################################
def dc_icon_for_boolean(value=false)
  dc_dont?(value, true) ? fa_icon('square-o lg') : fa_icon('check-square-o lg') 
end

############################################################################
#
############################################################################
def dc_icon4_boolean(value=false) #nodoc
  #dc_deprecate('dc_icon4_boolean will be deprecated. Use dc_icon_for_boolean instead.')
  dc_icon_for_boolean(value)
end

############################################################################
# Returns html code for displaying date/time formatted by strftime. Will return '' if value is nil.
# 
# Parameters:
# [value] Date/DateTime/Time.  
# [format] String. strftime format mask. Defaults to locale's default format.
############################################################################
def self.dc_format_date_time(value, format=nil)
  return '' if value.blank?

  format ||= value.class == Date ? t('date.formats.default') : t('time.formats.default')
  if format.size == 1
    format = format.match(/d/i) ? t('date.formats.default') : t('time.formats.default')
  end
  value.strftime(format)
end

############################################################################
# Returns html code for displaying date/time formatted by strftime. Will return '' if value is nil.
#
# Parameters:
# [value] Date/DateTime/Time.
# [format] String. strftime format mask. Defaults to locale's default format.
############################################################################
def dc_format_date_time(value, format=nil) #:nodoc:
  CmsCommonHelper.dc_format_date_time(value, format)
end

####################################################################
#
####################################################################
def dc_date_time(value, format) #:nodoc:
  dc_deprecate 'dc_date_time will be deprecated! Use dc_format_date_time instead.'
  dc_format_date_time(value, format)
end

############################################################################
# Returns html code for displaying formatted number.
# 
# Parameters:
# [value] Numeric number.  
# [decimals] Integer. Number of decimals
# [separator] String. Decimals separator
# [delimiter] String. Thousands delimiter.
# [currency] String. Currency symbol if applied to result string.
############################################################################
def self.dc_format_number(value=0, decimals=nil, separator=nil, delimiter=nil, currency=nil)
  decimals  ||=  I18n.t('number.currency.format.precision')
  separator ||= I18n.t('number.currency.format.separator')
  separator   = '' if decimals == 0
  delimiter ||= I18n.t('number.currency.format.delimiter')
  whole, dec = value.to_s.split('.')
  whole = '0' if whole.blank?
# remove and remember sign  
  sign = ''
  if whole[0] == '-'
    whole.delete_prefix!('-')
    sign  << '-'
  end
# format decimals
  dec ||= '0'
  dec = dec[0,decimals]
  while dec.size < decimals do dec += '0' end
# slice whole on chunks of 3
  ar = []
  while whole.size > 0 do 
    n = whole.size >=3 ? 3 : whole.size 
    ar << whole.slice!(n*-1,n)
  end
# put it all back and format
  "#{sign}#{ar.reverse.join(delimiter)}#{separator}#{dec}" 
end

############################################################################
# Returns html code for displaying formatted number.
#
# Parameters:
# [value] Numeric number.
# [decimals] Integer. Number of decimals
# [separator] String. Decimals separator
# [delimiter] String. Thousands delimiter.
# [currency] String. Currency symbol if applied to result string.
############################################################################
def dc_format_number(value=0, decimals=nil, separator=nil, delimiter=nil, currency=nil) #:nodoc:
  CmsCommonHelper.dc_format_number(value, decimals, separator, delimiter, currency)
end

############################################################################
# Create help text for fields on single tab
############################################################################
def dc_help_for_tab(tab)
  return '' if tab.nil?

  html = ''
  if tab.class == Array
    tab_name = tab.last['caption'] || tab.first
    tab_label, tab_help = dc_tab_label_help(tab_name)
    html << %(<div class="help-tab">#{tab_label}</div><div class="help-tab-help">#{tab_help}</div>)

    tab = tab.last
  end

  tab.each do |field|
    label, help = dc_label_help(field.last)
    next if help.blank?

    html << %(<div class="help-field"><div class="help-label">#{label}</div><div class="help-text">#{help}</div></div>)
  end
  html
end

############################################################################
# Will scoop fields and help text associated with them to create basic help text.
############################################################################
def dc_help_fields
  return '' if @form['form'].nil?

  html = '<div class="dc-handle" data-div="#the1"></div><div id="the1">'
  if @form['form']['tabs']
    @form['form']['tabs'].each { |tab| html << dc_help_for_tab(tab) }
  else
    html << dc_help_for_tab(@form['form']['fields'])
  end
  html << '</div>'
  html.html_safe
end

############################################################################
# Will return text from help files
############################################################################
def dc_help_body
  (params[:type] == 'index' ? @help['index'] : @help['form']).html_safe
end

end
