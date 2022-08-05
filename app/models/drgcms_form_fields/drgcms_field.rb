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

###########################################################################
# DrgcmsFormFields module contains definitions of classes used for 
# rendering data entry fields on DRG CMS forms. 
# 
# Every data entry field type written in lowercase in form must have its class 
# defined in CamelCase in DrgcmsFormFields module. 
# 
# Each class must have at least render method implemented. All classes can
# inherit from DrgcmsField class which acts as abstract template class and implements 
# most of surrounding code for creating custom DRG CMS form field.
# 
# Render method must create html and javascript code which must be
# saved to internal @html and @js variables. Field code is then retrived by accessing
# these two internal variables.
# 
# Example. How the field code is generated in form renderer:
#    klas_string = yaml['type'].camelize
#    if DrgcmsFormFields.const_defined?(klas_string) # check if field type class is defined
#      klas = DrgcmsFormFields.const_get(klas_string)
#      field = klas.new(self, @record, options).render
#      javascript << field.js
#      html << field.html 
#    end
# 
# Example. How to mix DRG CMS field code in Rails views:
#    <div>User:
#    <%= 
#      opts = {'name' => 'user', 'eval' => "dc_choices4('dc_user','name')", 
#              'html' => { 'include_blank' => true } }
#      dt = DrgcmsFormFields::Select.new(self, {}, opts).render
#      (dt.html + javascript_tag(dt.js)).html_safe
#     %></div> 
###########################################################################
module DrgcmsFormFields

###########################################################################
# Template method for DRG CMS form field definition. This is abstract class with
# most of the common code for custom form field already implemented.
###########################################################################
class DrgcmsField
attr_reader :js
attr_reader :css

####################################################################
# DrgcmsField initialization code.
# 
# Parameters:
# [parent] Controller object. Controller object from where object is created. Usually self is send. 
# [record] Document object. Document object which holds fields data.
# [yaml] Hash. Hash object holding field definition data.
# 
# Returns: 
# Self
####################################################################
def initialize( parent, record, yaml )
  @parent = parent
  @record = record
  @yaml   = yaml
  @form   = parent.form
  @yaml['html'] ||= {}
  # set readonly field
  @readonly = (@yaml and @yaml['readonly']) || (@form and @form['readonly'])
  @yaml['html']['readonly'] = true if @readonly
  # assign size to html element if not already there
  @yaml['html']['size'] ||= @yaml['size'] if @yaml['size'] 
    
  @html   = ''  
  @js     = ''
  @css    = set_css_code @yaml['css']
  self
end

####################################################################
# Returns html code together with CSS code.
####################################################################
def html
  @html
end

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
def t(key, default='')
  c = I18n.t(key)
  if c.match( 'translation missing' )
    c = I18n.t(key, locale: 'en') 
# Still not found. Return default if set
    c = default unless default.blank?
  end
  c
end

####################################################################
# Standard code for returning readonly field.
####################################################################
def ro_standard(value=nil)
  if value.nil?
    value = if @yaml['html']['value']
      @yaml['html']['value']
    else
      @record.respond_to?(@yaml['name']) ? @record.send(@yaml['name']) : nil
    end
  end
  #@html << (value.blank? ? '' : "<div class='dc-readonly'>#{value}</div>")
  @html << %(<div id="#{@yaml['name']}" class="dc-readonly">#{value}</div>)
  self
end

####################################################################
# Set initial value of the field when initial value is set in url parameters..
# 
# Example: Form has field named picture. Field can be initialized by 
# setting value of param p_picture.
#    params['p_picture'] = '/path/to_picture'
#    
# When multiple initial values are assigned it is more convinient to assign them 
# through flash object.
#    flash[:record] = {}
#    flash[:record]['picture'] = '/path/to_picture'
####################################################################
def set_initial_value(opt1 = 'html', opt2 = 'value')
  @yaml['html'] ||= {}
  value_send_as = 'p_' + @yaml['name']
  if @parent.params[value_send_as]
    @yaml[opt1][opt2] = @parent.params[value_send_as] 
  elsif @parent.flash[:record] and @parent.flash[:record][@yaml['name']]
    @yaml[opt1][opt2] = @parent.flash[:record][@yaml['name']]
  end
  set_default_value(opt1, opt2) if @yaml['default']
end

####################################################################
# Will set default value
####################################################################
def set_default_value(opt1, opt2)
  return if @yaml[opt1][opt2].present?
  return if @record && @record[@yaml['name']].present?

  @yaml[opt1][opt2] = if @yaml['default'].class == Hash
                        evaluate = @yaml['default']['eval']
                        return if evaluate.blank?
                        # add @parent if it's a method call and @parent is not present
                        if evaluate[0] != evaluate[0].upcase && !evaluate.match('@parent')
                          evaluate.prepend('@parent.')
                        end
                        eval(evaluate)
                      else
                        @yaml['default']
                      end
end

####################################################################
# Returns style html code for DRGForm object if style directive is present in field definition.
# Otherwise returns empty string.
# 
# Style may be defined like:
#    style:
#      height: 400px
#      width: 800px
#      padding: 10px 20px
#     
#    or 
#     
#    style: "height:400px; width:800px; padding: 10px 20px;"
#    
#  Style directive may also be defined under html directive.
#    html:
#      style:
#        height: 400px
#        width: 800px
#    
# 
####################################################################
def set_style()
  style = @yaml['html']['style'] || @yaml['style']
  case
    when style.nil? then ''
    when style.class == String then "style=\"#{style}\""
    when style.class == Hash then
      value = style.to_a.inject([]) {|r,v| r << "#{v[0]}: #{v[1]}" }.join(';')
      "style=\"#{value}\"" 
    else ''
  end 
end

####################################################################
# DEPRECATED!
#  
# Returns css code for the field if specified. It replaces all occurences of '# ' 
# with field name id, as defined on form.
####################################################################
def __css_code
  return '' if @css.blank?
  @css.gsub!('# ',"#td_record_#{@yaml['name']} ")
  "\n<style type=\"text/css\">#{@css}</style>"
end

####################################################################
# Sets css code for the field if specified. It replaces all occurences of '# ' 
# with field name id, as defined on form.
####################################################################
def set_css_code(css)
  return '' if css.blank?
  css.gsub!('# ',"#td_record_#{@yaml['name']} ") if css.match('# ')
  css
end

####################################################################
# Will return ruby hash formated as javascript string which can be used
# for passing parameters in javascript code.
# 
# Parameters:
# [Hash] Hash. Ruby hash parameters.
# 
# Form example: As used in forms
#    options:
#      height: 400
#      width: 800
#      toolbar: "'basic'"
#      
#  => "height:400, width:800, toolbar:'basic'"
# 
# Return: 
# String: Options formated as javascript options.
#      
####################################################################
def hash_to_options(hash)
  ActiveSupport::Deprecation.warn("hash_to_options(hash) will be deprecated. Use hash.to_json instead.")
  hash.to_a.inject([]) {|r,v| r << "#{v[0]}: #{v[1]}" }.join(',')
end

####################################################################
# Options may be defined on form as hash or as string. This method will
# ensure conversion of options into hash.
#
# Parameters:
# [String or Hash] : Form options
#
# Form example: As used in forms
#    options:
#      height: 400
#      width: 800
#      toolbar: "'basic'"
#  or
#
#  options: "height:400, width:800, toolbar:'basic'"
#
# Return:
# Hash: Options as Hash
####################################################################
def options_to_hash(options)
  return options unless options.class == String

  options.chomp.split(',').inject({}) do |r, e|
    key, value = e.chomp.split(':')
    value.strip!
    value = value[1..value.size - 2] if value[0] =~ /\'|\"/
    r[key.strip] = value
    r
  end
end

####################################################################
# Checks if field name exists in document and alters record parameters if necesary.
# Method was added after fields that do not belong to current edited document
# were added to forms. Valid nonexisting form field names must start with underscore (_) letter.
# 
# Return: 
# String: 'record' or '_record' when valid nonexisting field is used
####################################################################
def record_text_for(name)
  (!@record.respond_to?(name) and name[0,1] == '_') ? '_record' : 'record'
end


###########################################################################
# Default get_data method for retrieving data from parameters. Class method is called 
# for every entry field defined on form before field value is saved to database.
# 
# Parameters:
# [params] Controllers params object.
# [name] Field name
# 
# Most of classes will use this default method which returns params['record'][name]. 
# When field data is more complex class should implement its own get_data method. 
###########################################################################
def self.get_data(params, name)
  params['record'][name]
end

end
end
