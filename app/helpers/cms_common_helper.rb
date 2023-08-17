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
def self.t(key, default = nil)
  c = I18n.t(key)
  if c.class == Hash || c.match( /translation missing/i )
    c = I18n.t(key, locale: 'en') 
    # Still not found, return default
    if c.class == Hash || c.match( /translation missing/i )
      c = default || key
    end
  end
  c
end

####################################################################
def t(key, default = nil) #:nodoc
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
def t_tablename(tablename, default = nil)
  t('helpers.label.' + tablename + '.tabletitle', default || tablename)
end

############################################################################
# Returns label for field translated to current locale for usage on data entry form.
# Translation is provided by lang.helpers.label.table_name.field_name locale. If
# translation is not found method will capitalize field_name and replace '_' with ' '.
############################################################################
def t_label_for_field(field_name, default = '')
  c = (@form['i18n_prefix'] || "helpers.label.#{@form['table']}") + ".#{field_name}"
  c = field_name if field_name.match(/helpers\./)

  label = t(c, default)
  label = field_name.capitalize.gsub('_', ' ') if c.match( /translation missing/i )
  label
end

############################################################################
# Returns label for field translated to current locale for usage in browser header.
# Translation is provided by lang.helpers.label.table_name.field_name locale. If
# not found method will look in standard drgcms translations.
############################################################################
def t_label_for_column(options)
  label = options['caption'] || options['label']
  if label.blank?
    label = if options['name']
              prefix = @form['i18n_prefix'] || "helpers.label.#{@form['table']}"
              "#{prefix}.#{options['name']}"
            end
    label = label.to_s
  end
  label = t(label) if label.match(/\./)
  label = t("drgcms.#{options['name']}") if label.match('helpers.') # standard field names like created_by, updated_at
  label
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
  return ['error'] if c.match( /translation missing/i )
  c.chomp.split(',').inject([]) { |r, v| r << v.split(':') }
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
  doc = Mongo::QueryCache.cache { model.find_by(field_name => id) }

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
# If second parameter (fiel_name) is ommited value is supplied as first parameter.
# 
# Parameters:
# [value] Boolean.  
# 
# Example:
#    # usage from program
#    dc_icon4_boolean(document, field_name)
#
#    # usage from form description
#    columns:
#      10: 
#        name: active
#        eval: dc_icon4_boolean
############################################################################
def dc_icon_for_boolean(document = false, field_name = nil)
  value = field_name.nil? ? document : document[field_name]
  dc_dont?(value, true) ? fa_icon('check_box_outline_blank md-18') : fa_icon('check_box-o md-18')
end

############################################################################
#
############################################################################
def dc_icon4_boolean(document = false, field_name = false) #nodoc
  #dc_deprecate('dc_icon4_boolean will be deprecated. Use dc_icon_for_boolean instead.')
  dc_icon_for_boolean(document, field_name)
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

    html << %(<div class="help-field"><div class="help-label">#{label}</div><div class="help-text">#{help.gsub("\n",'<br>')}</div></div>)
  end
  html
end

############################################################################
# Will scoop fields and help text associated with them to create basic help text.
############################################################################
def dc_help_fields
  return '' if @form['form'].nil?

  html = '<a id="fields"></a>'
  if @form['form']['tabs']
    @form['form']['tabs'].each { |tab| html << dc_help_for_tab(tab) }
  else
    html << dc_help_for_tab(@form['form']['fields'])
  end
  html.html_safe
end

############################################################################
# Will return text from help files
############################################################################
def dc_help_body
  (params[:type] == 'index' ? @help['index'] : @help['form']).html_safe
end

############################################################################
# Will return code for help button if there is any help text available for the form.
############################################################################
def dc_help_button(result_set)
  type = result_set.nil? ? 'form' : 'index'
  form_name = CmsHelper.form_param(params) || CmsHelper.table_param(params)
  url = url_for(controller: :dc_common, action: :help, type: type, f: form_name)
  html = %(<div class="dc-help-icon dc-link-ajax" data-url=#{url}>#{fa_icon('question-circle')}</div>)
  return html if type == 'form'

  # check if index has any help available
  help_file_name = @form['help'] || @form['extend'] || form_name
  help_file_name = DcApplicationController.find_help_file(help_file_name)
  if help_file_name
    help = YAML.load_file(help_file_name)
    return html if help['index']
  end
  ''
end

############################################################################
# Will return html code for steps menu when form with steps is processed.
############################################################################
def dc_steps_menu_get(parent)
  yaml = @form['form']['steps']
  return '' unless yaml

  html = %(<ul id="dc-steps-menu"><h2>#{t('drgcms.steps')}</h2>)
  control = @form['control'] ? @form['control'] : @form['table']
  parms = { controller: 'cmsedit', action: 'run', control: "#{control}.steps",
            table: CmsHelper.table_param(params),
            form_name: CmsHelper.form_param(params),
            id: @record.id }

  yaml.sort.each_with_index do |data, i|
    n = i + 1
    step = data.last # it's an array
    url = case params[:step].to_i
          when n + 1 then url_for(parms.merge({ step: n + 1, next_step: n}))
          when n then url_for(parms.merge({ step: n, next_step: n}))
          when n - 1 then url_for(parms.merge({ step: n - 1, next_step: n}))
          else
            ''
          end
    _class = url.present? ? 'dc-link-ajax' : ''
    _class << (params[:step].to_i == n ? ' active' : '')
    html << %(<li class="#{_class}" data-url="#{url}">#{step['title']}</li>)
  end
  html << '</ul>'
end

end
