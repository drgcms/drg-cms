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
attr_reader :html, :js

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
  @readonly = (@yaml and @yaml['readonly']) || (@form and @form['readonly'])
  @html   = ''  
  @js     = ''
  self
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
  value = @record[@yaml['name']] if value.nil? and @record.respond_to?(@yaml['name']) 
  @html << (value.to_s.size == 0 ? '' : "<table class='dc-readonly'><td>#{value}</td></table>")
  self
end

####################################################################
# Set initial value of the field when initial value is set in url parameters..
# 
# Example: Form has field named picture. Field can be initialized by 
# setting value of param p_picture.
####################################################################
def set_initial_value(opt1='html', opt2='value')
  @yaml['html'] ||= {}
  value_send_as = 'p_' + @yaml['name']
  @yaml[opt1][opt2] = @parent.params[value_send_as] if @parent.params[value_send_as]
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
  options = hash.to_a.inject('') do |r,v|
    r << "#{v[0]}: #{v[1]},"
  end
  options.chomp(',')
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

###########################################################################
# Implementation of readonly DRG CMS form field. 
# 
# Readonly field value is just painted on form.
# 
# ===Form options:
# * +name:+ field name
# * +type:+ readonly
# * +eval:+ value will be provided by evaluating expression. Usually dc_name4_id helper
# can be used to get value. Example: dc_name4_id,model_name_in_lower_case,field_name 
# 
# * +readonly:+ yes (can be applied to any field type)
# 
# Form example:
#    10:
#      name: user
#      type: readonly
#      html:
#        size: 50
#    20:
#      name: created_by
#      type: readonly
#      eval: dc_name4_id,dc_user,name
###########################################################################
class Readonly < DrgcmsField
###########################################################################
# Render readonly field html code
###########################################################################
def render 
  @html << @parent.hidden_field('record', @yaml['name']) # retain field as hidden field
  @html << '<table class="dc-readonly"><td>'
  
  @html << if @yaml['eval']
    if @yaml['eval'].match('dc_name4_id')
      a = @yaml['eval'].split(',')
      @parent.dc_name4_id(a[1], a[2], @record[ @yaml['name'] ])
    else
      eval( "#{@yaml['eval']} '#{@record[ @yaml['name'] ]}'") 
    end
  else
    @parent.dc_format_value(@record[@yaml['name']],@yaml['format'])    
  end  
  @html << '</td></table>'
  self
end
end

###########################################################################
# Implementation of hidden DRG CMS form field.
# 
# Will create hidden_field on form.
# 
# ===Form options:
# * +name:+ field name
# * +type:+ hidden_field
# 
# Form example:
#    10:
#      name: im_hidden
#      type: hidden_field
###########################################################################
class HiddenField < DrgcmsField
###########################################################################
# Render hidden_field field html code
###########################################################################
def render 
  set_initial_value
  value = @yaml['html']['value'] ? @yaml['html']['value'] : @record[@yaml['name']]
  record = record_text_for(@yaml['name'])  
  @parent.hidden_field(record, @yaml['name'], value: value)
end
end

###########################################################################
# Implementation of embedded DRG CMS form field.
#
# Creates html required to paint embedded object on form.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ embedded (required)
# * +formname:+ name of form which will be used for editing
# * +html:+ html options (optional)
#   * +height:+ height of embedded object in pixels (1000)
#   * +width:+ width of embedded object in pixels (500)
# 
# Form example:
#    10:
#      name: dc_parts
#      type: embedded
#      formname: dc_part
#      html:
#        height: 1000
###########################################################################
class Embedded < DrgcmsField
###########################################################################
# Render embedded field html code
###########################################################################
def render 
  return self if @record.new_record?  # would be in error otherwise
# HTML defaults. Some must be set    
  @yaml['html'] ||= {}
  @yaml['html']['height'] ||= 300
  @yaml['html']['width']  ||= '99%'
# defaults both way 
  @yaml['table']    ||= @yaml['formname'] if @yaml['formname']
  @yaml['formname'] ||= @yaml['table'] if @yaml['table']
# 
  html = ''  
  @yaml['html'].each {|k,v| html << "#{k}=\"#{v}\" "}
#  
  tables      = @parent.tables.inject('') { |r,v| r << "#{v[1]};" } + @yaml['table']
  ids         = @parent.ids.inject('') { |r,v| r << "#{v};" } + @record._id
  opts = { controller: 'cmsedit', action: 'index', ids: ids, table: tables, formname: @yaml['formname'], 
           field_name: @yaml['name'], iframe: "if_#{@yaml['name']}", readonly: @readonly }
  @html << "<iframe class='iframe_embedded' id='if_#{@yaml['name']}' name='if_#{@yaml['name']}' #{html}></iframe>"
  @js = <<EOJS
$(document).ready( function() {
  $('#if_#{@yaml['name']}').attr('src', '#{@parent.url_for(opts)}');
});
EOJS
  self
end

end

###########################################################################
# Implementation of journal_diff DRG CMS form field. journal_diff field is used to 
# show differences between two fields in DcJournal collection.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ journal_diff (required)
# 
# Form example:
#    10:
#      name: diff
#      type: journal_diff
#      html:
#        size: 100x25
###########################################################################
class JournalDiff < DrgcmsField
###########################################################################
# Render journal_diff field html code
###########################################################################
def render 
  @yaml['name'] = 'old' if @record[@yaml['name']].nil?
  @html << '<table width="99%">'
  JSON.parse(@record[@yaml['name']]).each do |k,v|
    @html << "<tr><td style='background-color: #654ddd;'>#{@parent.check_box('select', k)} #{k}:</td></tr>
             <tr><td style='background-color: #ffe;'>#{v[0]}</td></tr>
             <tr><td style='background-color: #eff;'>#{v[1]}</td></tr>"
  end
  @html << '</table>'
  self
end
end

###########################################################################
# Implementation of multitext_autocomplete DRG CMS form field.
# 
# multitext_autocomplete field is complex data entry field which uses autocomplete
# function when selecting multiple values for MongoDB Array field. Array typically holds
# id's of selected documents and control typically displays value of the field name 
# defined by search options.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ multitext_autocomplete (required)
# * +table+ Collection (table) name. When defined search must contain field name
# * +search:+ Search may consist of three parameters from which are separated either by dot (.) or comma(,)
#   * search_field_name; when table option is defined search must define field name which will be used for search query
#   * collection_name.search_field_name; Same as above except that table options must be ommited.
#   * collection_name.search_field_name.method_name; When searching is more complex custom search
#   method may be defined in CollectionName model which will provide result set for search.
#      
# Form example:
#      90:
#        name: kats
#        type: multitext_autocomplete
#        search: dc_category.name      
#        html:
#          size: 30
###########################################################################
class MultitextAutocomplete < DrgcmsField

###########################################################################
# Returns value for readonly field
###########################################################################
def ro_standard(table, search)
  result = ''
  table = table.classify.constantize
  return self if @record[@yaml['name']].nil?
    @record[@yaml['name']].each do |element|
      result << table.find(element)[search] + '<br>'
    end
  super(result)
end

###########################################################################
# Render multitext_autocomplete field html code
###########################################################################
def render 
# search field name
  if @yaml['search'].to_s.match(/\./)
    table, field_name, method = @yaml['search'].split(/\.|\,/) 
    search = method.nil? ? field_name : "#{field_name}.#{method}"
  else # search and table name are separated
    search = field_name = @yaml['search']
  end
# determine table name 
  if @yaml['table']
    table = if @yaml['table'].class == String
      @yaml['table']
# eval(how_to_get_my_table_name)    
    elsif @yaml['table']['eval']
      eval @yaml['table']['eval']
    else
      p "Field #{@yaml['name']}: Invalid table parameter!"
      nil
    end
  end
  unless (table and search)
    @html << 'Table or search field not defined!' 
    return self
  end
# 
  return ro_standard(table, search) if @readonly
# TODO check if table exists    
  collection = table.classify.constantize
  unless @record.respond_to?(@yaml['name'])
    @html << "Invalid field name: #{@yaml['name']}" 
    return self
  end
# put field to enter search data on form
  @yaml['html'] ||= {}
  @yaml['html']['value'] = ''   # must be. Otherwise it will look into record and return error
  _name = '_' + @yaml['name']
  @html << '<table class="ui-autocomplete-table"><td>'
  @html << @parent.link_to(@parent.fa_icon('plus-square lg', class: 'dc-animate dc-green'), '#',onclick: 'return false;') # dummy add. But it is usefull.

  record = record_text_for(@yaml['name'])    
  @html << ' ' << @parent.text_field(record, _name, @yaml['html'])                 # text field for autocomplete
  @html << "<div id =\"#{record}#{@yaml['name']}\">"        # div to list active records
# find value for each field inside categories 
  unless @record[@yaml['name']].nil?
    @record[@yaml['name']].each do |element|
# this is quick and dirty trick. We have model dc_big_table which can be used for retrive 
# more complicated options
# TODO retrieve choices from big_table
      rec = if table == 'dc_big_table'
        collection.find(@yaml['name'], @parent.session)
      else
        collection.find(element)
      end
# Related data is missing. It happends.
      @html << if rec
        link  = @parent.link_to(@parent.fa_icon('remove lg', class: 'dc-animate dc-red'), '#',
                onclick: "$('##{rec.id}').hide(); var v = $('##{record}_#{@yaml['name']}_#{rec.id}'); v.val(\"-\" + v.val());return false;")
        field = @parent.hidden_field(record, "#{@yaml['name']}_#{rec.id}", value: element)
        "<div id=\"#{rec.id}\" style=\"padding:2px;\">#{link} #{rec[field_name]}<br>#{field}</div>"
      else
        '** error **'
      end
    end
  end
  @html << "</div></td></table>"
# Create text for div to be added when new category is selected  
  link    = @parent.link_to(@parent.fa_icon('remove lg', class: 'dc-animate dc-red'), '#', 
            onclick: "$('#rec_id').hide(); var v = $('##{record}_#{@yaml['name']}_rec_id'); v.val(\"-\" + v.val());return false;")
  field   = @parent.hidden_field(record, "#{@yaml['name']}_rec_id", value: 'rec_id')
  one_div = "<div id=\"rec_id\" style=\"padding:2px;\">#{link} rec_search<br>#{field}</div>"
    
# JS stuff    
  @js << <<EOJS
$(document).ready(function() {
  $("##{record}_#{_name}").autocomplete( {
    source: function(request, response) {
      $.ajax({
        url: "#{ @parent.url_for( controller: 'dc_common', action: 'autocomplete' )}",
        type: "POST",
        dataType: "json",
        data: { input: request.term, table: "#{table}", search: "#{search}" #{(',id: "'+@yaml['id'] + '"') if @yaml['id']} },
        success: function(data) {
          response( $.map( data, function(key) {
            return key;
          }));
        }
      });
    },
    change: function (event, ui) { 
      var div = '#{one_div}';
      div = div.replace(/rec_id/g, ui.item.id)
      div = div.replace('rec_search', ui.item.value)
      $("##{record}#{@yaml['name']}").append(div);
      $("##{record}_#{_name}").val('');
    },
    minLength: 2
  });
});
EOJS

  self 
end

###########################################################################
# Class method for retrieving data from multitext_autocomplete form field.
###########################################################################
def self.get_data(params, name)
  r = []
  params['record'].each do |k,v| 
# if it starts with - then it was removed
    r << BSON::ObjectId.from_string(v) if k.match("#{name}_") and v[0,1] != '-'
  end
  r.uniq!
  r
end

end
  
###########################################################################
# Implementation of select DRG CMS form field.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ select (required)
# * +choices:+ Values for choices separated by comma. Values can also be specified like description:value.
# In the example description will be shown to user, but value will be saved to document.
#    choices: 'OK:0,Ready:1,Error:2'
#    choices: Ruby,Pyton,PHP
# * +eval:+ Choices will be provided by evaluating expression
#   * eval: dc_choices4('model_name','description_field_name','_id'); dc_choices4 helper will provide data for select field. 
#   * eval: ModelName.choices4_field; ModelName class will define method choices4_field which 
#   will provide data for select field.
#   * collection_name.search_field_name.method_name; When searching is more complex custom search
#   method may be defined in CollectionName model which will provide result set for search.
# * If choices or eval is not defined choices will be provided from translation helpers. For example: 
#   Collection has field status choices for field may be provided by en.helpers.model_name.choices4_status 
#   entry of english translation. English is of course default translation. If you provide translations in
#   your local language then select choices will be localized.
#    en.helpers.model_name.choices4_status: 'OK:0,Ready:1,Error:2'
#    sl.helpers.model_name.choices4_status: 'V redu:0,Pripravljen:1,Napaka:2'
# * +html:+ html options which apply to select field (optional)
#      
# Form example:
#    30:
#      name: type
#      type: select
#    40:
#      name: parent
#      type: select
#      eval: DcCategory.values_for_parent
#      html:
#        include_blank: true      
###########################################################################
class Select < DrgcmsField
  
###########################################################################
# Return values, when choices options will be returned by evaluating expression
###########################################################################
def do_eval(e)
  e.strip!
  method = e.split(/\ |\(/).first
  return eval(e) if respond_to?(method) # id method defined here
  return eval('@parent.'+e) if @parent.respond_to?(method) # is method defined in helpers
# eval whatever it is
  eval e
end
  
###########################################################################
# Create choices array for select field.
###########################################################################
def get_choices
  begin
    choices = case 
    when @yaml['choices'] then @yaml['choices']
    when @yaml['eval']    then
      do_eval(@yaml['eval'])
    else 
      c = t('helpers.label.' + @form['table'] + '.choices4_' + @yaml['name'] )
      c = 'Error' if c.match( 'translation missing' )
      c
    end
  # Convert string to Array
    choices.class == String ?
      choices.chomp.split(',').inject([]) {|r,v| r << (v.match(':') ? v.split(':') : v )} :
      choices
  rescue Exception => e 
    p "Error in select eval. #{e.message}"
    ['error'] # return empty array when error occures
  end
end

###########################################################################
# Return value when readonly is required
###########################################################################
def ro_standard
  value = @record.respond_to?(@yaml['name']) ? @record[@yaml['name']] : nil
  return self if value.nil?
#  
  get_choices.each do |choice|
      p choice, value
    if choice.class == Array
      return super(choice.first) if choice.last == value
    else
      return super(choice) if choice == value
    end  
  end
  super('')
end

###########################################################################
# Render select field html code
###########################################################################
def render
  return ro_standard if @readonly
  set_initial_value('html','selected')
 #
  @yaml['html'].symbolize_keys!
  record = record_text_for(@yaml['name'])  
  @html << @parent.select(record, @yaml['name'], get_choices, @yaml['html'])
  self
end

end

###########################################################################
# Implementation of check_box DRG CMS form field.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ check_box (required)
# * +choices:+ Values check_box separated by comma (1,0) (yes,no)
# * +checked_value:+ 1 or yes or approved
# * +unchecked_value:+ 0 or no or not approved
# * +html:+ html options which apply to check_box field (optional)
#      
# Form example:
#    30:
#      name: active
#      type: check_box
#    40:
#      name: status
#      type: check_box
#      choices: yes,no
###########################################################################
class CheckBox < DrgcmsField
  
###########################################################################
# Render check_box field html code
###########################################################################
def render
  set_initial_value('html','default')
# checked flag must be set    
  @yaml['html']['checked'] = !@parent.dc_dont?(@yaml['html']['default']) if @yaml['html']['default']
# disable it if readonly  
  @yaml['html']['disabled'] = @readonly ? true : nil
# If choices are present split them to set checked and unchecked value     
  @yaml['checked_value'], @yaml['unchecked_value'] = @yaml['choices'].split(',') if @yaml['choices']
  @yaml['html'].symbolize_keys!
  record = record_text_for(@yaml['name'])
  @html << if @yaml['checked_value']
    @parent.check_box(record, @yaml['name'], @yaml['html'], @yaml['checked_value'], @yaml['unchecked_value'] || '0')
  else
    @parent.check_box(record, @yaml['name'], @yaml['html'])
  end
  self
end
end

###########################################################################
# Implementation of comment DRG CMS form field. Comments may also be written
# on the place of form field.
# 
# ===Form options:
# * +text:+ any text. Text will be translated if key is found in translations. (required)
# * +type:+ comment (required)
#
# Form example:
#    30:
#      name: active
#      type: check_box

###########################################################################
class Comment < DrgcmsField
  
###########################################################################
# Render comment field html code
###########################################################################
def render
  @html << t(@yaml['text'], @yaml['text'])
  self
end
end

###########################################################################
# Implementation of link_to DRG CMS form field. link_to form field is mostly used by polls but can
# be also incorporated anywhere on the form.
# 
# ===Form options:
# * +type:+ link_to (required)
# * +caption:+ Link caption 
# * +icon:+ Link icon
# * +url:+ direct url link
# * +controller:+ controller name
# * +action:+ action name 
# * +html:+ html options which apply to link_to (optional)
#      
# Form example:
#    30:
#      type: link_to
#      caption: Some action
#      icon: cogs
#      controller: my_controller
#      action: my_action
#      id: id # will be replaced by record._id
###########################################################################
class LinkTo < DrgcmsField
  
###########################################################################
# Render link_to field html code
###########################################################################
def render
  @yaml['html'] ||= {}
  @yaml['html']['class'] ||= 'dc-link dc-animate'
  @yaml['html'].symbolize_keys!
#
  @yaml[:id] = record._id if @yaml[:id] == 'id'
  url = @yaml['url'] || "#{@yaml[:controller]}/#{@yaml[:action]}/#{@yaml[:id]}"
  url.gsub!('//','/')                             # no action and id
  url = '/' + @yaml['url'] unless url[0,1] == '/' # no leading /
  url.chop if url[0,-1] == '/'                    # remove trailing /
#
  caption = @yaml['caption'] || @yaml['text']
  @html << @parent.dc_link_to(caption, @yaml['icon'], url, @yaml['html'])
  self
end
end

###########################################################################
# Create submit_tag form field. submit_tag form field is mostly used by polls but can
# be also incorporated in the middle of form.
# 
# ===Form options:
# * +type:+ submit_tag (required)
# * +caption:+ Submit field caption 
# * +icon:+ Icon
# * +html:+ html options which apply to link_to (optional)
#      
# Form example:
#    40:
#      type: submit_tag
#      caption: translate.this
#      icon: check
###########################################################################
class SubmitTag < DrgcmsField
  
###########################################################################
# Render submit_tag field html code
###########################################################################
def render
  @yaml['html'] ||= {}
  @yaml['html']['class'] ||= 'dc-submit'
  @yaml['html'].symbolize_keys!
  text = @yaml['caption'] || @yaml['text']
  text = t(@yaml['text']) if text.match(/\./)
  
  @html << @parent.submit_tag(text, @yaml['html'])
  self
end
end

###########################################################################
# Implementation of password DRG CMS form field.
# 
# ===Form options:
# * +type:+ password_field (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to password field (optional)
# 
# Form example:
#    20:
#      name: password
#      type: pasword_field
#      html:
#        size: 20
#        
#    30:
#      name: password_confirmation
#      type: pasword_field
#      html:
#        size: 20
#        
###########################################################################
class PasswordField < DrgcmsField
  
###########################################################################
# Render password field html code
# 
###########################################################################
def render
  return self if @readonly
  @yaml['html'] ||= {}
  record = record_text_for(@yaml['name'])  
  @html << @parent.password_field(record, @yaml['name'], @yaml['html'])
  self
end
end

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

####################################################################
# Get data for DateSelect field
# According to  https://gist.github.com/315227
####################################################################
def self.get_data(params, name)
  attrs = params['record'].collect do |key, value|
    if key =~ /^#{Regexp.escape(name.to_s)}\((\d+)(\w)\)$/
      [$1.to_i, value.send("to_#$2")]
    end
  end.compact.sort_by(&:first).map(&:last)
# Return nil if error
  begin
    Time.zone.local(*attrs) #unless attrs.empty?
  rescue 
    nil
  end
end

end

###########################################################################
# Create datetime_select form field
# 
# ===Form options:
# * +type:+ date_select (required)
# * +name:+ Field name (required) 
# * +options:+ options which apply to date_select field (optional)
# * +html:+ html options which apply to password field (optional)
# 
# Form example:
#    60:
#      name: end_time
#      type: date_time_select
#      options:
#        include_blank: true
###########################################################################
class DatetimeSelect < DrgcmsField
  
###########################################################################
# Render datetime_select field html code
###########################################################################
def render
  return ro_standard( @parent.dc_format_value(@record[@yaml['name']])) if @readonly
#
  @yaml['options'] ||= {}
  set_initial_value('options','default')
  @yaml['options'].symbolize_keys!
  @yaml['html'].symbolize_keys!
#
  record = record_text_for(@yaml['name'])
  @html << @parent.datetime_select(record, @yaml['name'], @yaml['options'], @yaml['html'])
  self
end

###########################################################################
# DatetimeSelect get_data method.
###########################################################################
def self.get_data(params, name)
  DateSelect.get_data(params, name)
end

end

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
  value = @record[@yaml['name']] ? I18n.localize(@record[@yaml['name']].localtime.to_date) : nil
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
###########################################################################
# Implementation of date_time_picker DRG CMS form field with help of jQuery DateTimePicker plugin
# 
# ===Form options:
# * +type:+ date_time_picker (required)
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
#      type: date_time_picker
#      options: 'step: 60'
###########################################################################
class DatetimePicker < DrgcmsField
  
###########################################################################
# Render date_time_picker field html code
###########################################################################
def render
  value = @record[@yaml['name']] ? I18n.localize(@record[@yaml['name']].localtime) : nil
  return ro_standard( @parent.dc_format_value(value)) if @readonly
#
  @yaml['options'] ||= {}
  set_initial_value
  @yaml['html']['size'] ||= 14
  @yaml['html']['value'] = value if @record[@yaml['name']]
#
  @yaml['options']['lang']   ||= "'#{I18n.locale}'"
  @yaml['options']['format'] ||= "'#{t('datetimepicker.formats.datetime')}'"
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
# DateTimePicker get_data method.
###########################################################################
def self.get_data(params, name)
  t = params['record'][name] ? params['record'][name].to_datetime : nil
  t ? Time.zone.local(t.year, t.month, t.day, t.hour, t.min) : nil
end

end

###########################################################################
# Implementation of text_autocomplete DRG CMS form field.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ text_autocomplete (required)
# * +table+ Collection (table) name. When defined search must contain field name
# * +search:+ Search may consist of three parameters from which are separated either by dot (.) or comma(,)
#   * search_field_name; when table option is defined search must define field name which will be used for search query
#   * collection_name.search_field_name; Same as above except that table options must be ommited.
#   * collection_name.search_field_name.method_name; When searching is more complex custom search
#   method may be defined in CollectionName model which will provide result set for search.
# 
# Form example:
#    10:
#      name: user_id
#      type: text_autocomplete
#      search: dc_user.name
#      html:
#        size: 30
###########################################################################
class TextAutocomplete < DrgcmsField
 
###########################################################################
# Render text_autocomplete field html code
###########################################################################
def render
# Return descriptive text and put it into input field
# search field name
  if @yaml['search'].class == Hash
    table    = @yaml['search']['table']
    ret_name = @yaml['search']['field']
    method   = @yaml['search']['method']
  elsif @yaml['search'].match(/\./)
    table, ret_name, method = @yaml['search'].split('.') 
  else
    ret_name = @yaml['search']
  end
# determine table name 
  if @yaml['table']
    table = if @yaml['table'].class == String
      @yaml['table']
# eval(how_to_get_my_table_name)    
    elsif @yaml['table']['eval']
      eval @yaml['table']['eval']
    else
      p "Field #{@yaml['name']}: Invalid table parameter!"
      nil
    end
  end
  return 'Table or field keyword not defined!' unless (table and ret_name)
# TODO check if table exists 
  t = table.classify.constantize
# find record and return value of field
  value_send_as = 'p_' + @yaml['name']
  value = if @parent.params[value_send_as]
    @parent.params[value_send_as]
  elsif @record and @record[@yaml['name']]
    @record[@yaml['name']]
  end
# Found value to be written in field  
  if value
    record = t.find(value)
    value_displayed = record[ret_name] if record      
  end
# return if readonly
  return ro_standard(value_displayed) if @readonly
# Add method back, so autocomplete will know that it must search for method inside class
  ret_name = "#{ret_name}.#{method}" if method
  @yaml['html'] ||= {}
  @yaml['html']['value'] = value_displayed
#    
  _name = '_' + @yaml['name']
  record = record_text_for(@yaml['name'])  
  @html << @parent.text_field(record, _name, @yaml['html'])
  if @yaml['with_new']
    @html << @parent.image_tag('drg_cms/add.png', class: 'in-edit-add', title: t('drgcms.new'), 
             style: "vertical-align: top;", 'data-table' => @yaml['with_new'] )    
  end
  @html << @parent.hidden_field(record, @yaml['name'], value: value)        # actual value will be in hidden field
# JS stuff    
  @js << <<EOJS
$(document).ready(function() {
  $("##{record}_#{_name}").autocomplete( {
    source: function(request, response) {
      $.ajax({
        url: '/dc_common/autocomplete',
        type: "POST",
        dataType: "json",
        data: { input: request.term, table: "#{table}", search: "#{ret_name}" #{(',id: "'+@yaml['id'] + '"') if @yaml['id']} },
        success: function(data) {
          response( $.map( data, function(key) {
            return key;
          }));
        }
      });
    },
    change: function (event, ui) { 
      $("##{record}_#{@yaml['name']}").val(ui.item.id);
    },
    minLength: 2
  });
});
EOJS
    
  self 
end
end

###########################################################################
# Implementation of text_area DRG CMS form field.
# 
# ===Form options:
# * +type:+ text_area (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to text_area field (optional)
# 
# Form example:
#    10:
#      name: css
#      type: text_area
#      html:
#        size: 100x30
###########################################################################
class TextArea < DrgcmsField
  
###########################################################################
# Render text_area field html code
###########################################################################
def render
  return ro_standard if @readonly
#
  @yaml['html'] ||= {}
  value_send_as = 'p_' + @yaml['name']
  @yaml['html']['value'] = @parent.params[value_send_as] if @parent.params[value_send_as]

  record = record_text_for(@yaml['name'])
  @html << @parent.text_area(record, @yaml['name'], @yaml['html'])
  self
end
end

###########################################################################
# Implementation of text_field DRG CMS form field.
# 
# ===Form options:
# * +type:+ text_field (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to text_field field (optional)
# 
# Form example:
#    10:
#      name: title
#      type: text_field
#      html:
#        size: 30
###########################################################################
class TextField < DrgcmsField
  
###########################################################################
# Render text_field field html code
###########################################################################
def render
  return ro_standard if @readonly
  set_initial_value
#
  record = record_text_for(@yaml['name'])
  @html << @parent.text_field( record, @yaml['name'], @yaml['html']) 
  self
end
end

###########################################################################
# Implementation of text_with_select DRG CMS form field. Field will provide
# text_field entry field with select dropdown box with optional values for the field.
# Form options are mostly same as in select field. 
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ text_with_select (required)
# * +choices:+ Values for choices separated by comma. Values can also be specified like description:value.
# In this case description will be shown to user, but value will be saved to document.
#   * choices: 'OK:0,Ready:1,Error:2'
#   * choices: Ruby,Pyton,PHP
# * +eval:+ Choices will be provided by evaluating expression
#   * eval: dc_choices4('model_name','description_field_name','_id'); dc_choices4 helper will provide data for select field. 
#   * eval: ModelName.choices4_field; ModelName class will define method choices4_field which 
#   will provide data for select field. Since expression is evaluated in the context of Form Field object
#   even session session variables can be accessed. Ex. +eval: 'MyClass.method(@parent.session[:user_id])'+
#   * collection_name.search_field_name.method_name; When searching is more complex custom search
#   method may be defined in CollectionName model which will provide result set for search.
# * If choices or eval is not defined choices will be provided from translation helpers. For example: 
#   Collection has field status choices for field may be provided by en.helpers.model_name.choices4_status 
#   entry of english translation. English is of course default translation. If you provide translations in
#   your local language then select choices will be localized.
#   * en.helpers.model_name.choices4_status: 'OK:0,Ready:1,Error:2'
#   * sl.helpers.model_name.choices4_status: 'V redu:0,Pripravljen:1,Napaka:2'
# * +html:+ html options which apply to select and text_field fields (optional)
# 
# Form example:
#    10:
#      name: link
#      type: text_with_select
#      eval: '@parent.dc_page_class.all_pages_for_site(@parent.dc_get_site)'
#      html:
#        size: 50
###########################################################################
class TextWithSelect < Select

###########################################################################
# Render text_with_select field html code
###########################################################################
def render
  return ro_standard if @readonly  
  set_initial_value('html','value')
  
  record = record_text_for(@yaml['name'])
  @html << @parent.text_field( record, @yaml['name'], @yaml['html']) 
  @yaml['html']['class'] = 'text-with-select'
  @yaml['html'].symbolize_keys!
  @html << @parent.select( @yaml['name'] + '_', nil, get_choices, { include_blank: true }, { class: 'text-with-select' })

  # javascript to update text field if new value is selected in select field
  @js =<<EOJS
$(document).ready(function() {
 $('##{@yaml['name']}_').change( function() {
  if ($(this).val().toString().length > 0) {
    $('##{record}_#{@yaml['name']}').val( $(this).val() );
  }
  $('##{record}_#{@yaml['name']}').focus();
 });
});
EOJS
  self
end
end

###########################################################################
# Implementation of html_field DRG CMS form field. 
# 
# HtmlField class only implements code for calling actual html edit field code.
# This is by default drg_default_html_editor gem which uses CK editor javascript plugin 
# or any other plugin. Which plugin will be used as html editor is defined by 
# dc_site.settings html_editor setting. 
# 
# Example of dc_site.setting used for drg_default_html_editor gem.
#    html_editor: ckeditor
#    ck_editor:
#      config_file: /files/ck_config.js  
#      css_file: /files/ck_css.css
#   file_select: elfinder
#   
# Form example:
#    10:
#      name: body
#      type: html_field
#      options: "height: 500, width: 550, toolbar: 'basic'" 
###########################################################################
class HtmlField < DrgcmsField

###########################################################################
# Render html_field field html code
###########################################################################
def render
  return ro_standard if @readonly  
# retrieve html editor from page settings
  editor_string = @parent.dc_get_site.params['html_editor'] if @parent.dc_get_site
  editor_string ||= 'ckeditor'
# 
  klas_string = editor_string.camelize
  if DrgcmsFormFields.const_defined?(klas_string)
    klas = DrgcmsFormFields::const_get(klas_string)
    o = klas.new(@parent, @record, @yaml).render
    @js << o.js
    @html << o.html 
  else
    @html << "HTML editor not defined. Check site.settings or include drgcms_default_html_editor gem."
  end
  self
end
end

###########################################################################
# Implementation of file_select DRG CMS form field.
# 
# FileSelect like HtmlField implements redirection for calling document manager edit field code.
# This can be drg_default_html_editor's elfinder or any other code defined
# by dc_site.settings file_select setting.
# 
# Example of dc_site.setting used for drg_default_html_editor gem.
#    html_editor: ckeditor
#    ck_editor:
#      config_file: /files/ck_config.js  
#      css_file: /files/ck_css.css
#   file_select: elfinder
#   
# Form example:
#    60:
#      name: picture
#      type: file_select
#      html:
#        size: 50   
###########################################################################
class FileSelect < DrgcmsField

###########################################################################
# Render file_select field html code
###########################################################################
def render
  return ro_standard if @readonly  
# retrieve html editor from page settings
  selector_string = @parent.dc_get_site.params['file_select'] if @parent.dc_get_site 
  selector_string ||= 'elfinder' 
# 
  klas_string = selector_string.camelize
  if DrgcmsFormFields.const_defined?(klas_string)
    klas = DrgcmsFormFields::const_get(klas_string)
    o = klas.new(@parent, @record, @yaml).render
    @js << o.js
    @html << o.html 
  else
    @html << "File select component not defined. Check site.settings or include drgcms_default_html_editor gem."
  end
  self
end
end

end