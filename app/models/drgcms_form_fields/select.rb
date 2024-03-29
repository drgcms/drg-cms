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
# * +depend:+ Select options may depend on a value in some other field. If depend option is specified
#   then chices must be provided by class method and defined in eval option.
# * +html:+ html options which apply to select field (optional)
# * +with_new:+ model_name.form_name will invoke view dialog for selected option
# * +with_edit:+ model_name.form_name will invoke edit dialog for selected option
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
#    50:
#      name: company
#      type: select
#      choices: Audi,BMW,Mercedes
#        or
#      choices: helpers.label.model.choices4_field
#    60:
#      name: type
#      type: select
#      eval: Cars.choices4_type
#      depend: company
###########################################################################
class Select < DrgcmsField
  
###########################################################################
# Choices are defined in helper as:
# helper.label.table_name.choices_for_fieldname or
# choices4_tablename_fieldname
###########################################################################
def choices_in_helper(helper = nil)
  helper ||= "helpers.label.#{@form['table']}.choices4_#{@yaml['name']}"
  c = t(helper)
  if c.match(/translation missing/i)
    helper = "choices_for_#{@form['table']}_#{@yaml['name']}"
    return "Error. #{helper} not defined" if c.match(/translation missing/i)
  end
  c
end

###########################################################################
# Choices are defined by evaluating an expression. This is most common class
# method defined in a class. eg. SomeClass.get_choices4
###########################################################################
def choices_in_eval(e)
  e.strip!
  if @yaml['depend'].nil?
    method = e.split(/\ |\(/).first
    return eval(e) if respond_to?(method) # is method defined here
    return eval('@parent.' + e) if @parent.respond_to?(method) # is method defined in helper methods
    # eval whatever it is there
    eval e
  else
    # add event listener to depend field(s)
    depend_value = ''
    @js << "\n$(document).ready(function() {\n"
    @yaml['depend'].split(',') do |depend|
      depend.strip!
      depend_value << ',' if depend_value.present?
      # depend field might be virtual field. It's value should be set in params
      depend_value << (depend[0] == '_' ? @parent.params["p_#{depend}"] : @record[depend]).to_s
      next if depend == @yaml['name'] # self may be sent, but don't listen to change event

      @js << %(
$('#record_#{depend}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '#{@yaml['depend']}', '#{e}');});
$('#_record_#{depend}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '#{@yaml['depend']}', '#{e}');});
)
    end
    @js <<  + "});\n"
    e << " '#{depend_value}'"
    eval e
  end
end

###########################################################################
# Create choices array for select field.
###########################################################################
def get_choices
  begin
    choices = case
              when @yaml['eval'] then
                choices_in_eval(@yaml['eval'])
              when @yaml['choices'] then
                @yaml['choices'].match('helpers.') ? choices_in_helper(@yaml['choices']) : @yaml['choices']
              else
                choices_in_helper()
              end
    return choices unless choices.class == String

    choices.chomp.split(',').map { |e| e.match(':') ? e.split(':') : e }
  rescue Exception => e
    Rails.logger.error "\nError in select eval. #{e.message}\n"
    Rails.logger.debug(e.backtrace.join($/)) if Rails.env.development?
    ['error'] # return empty array when error occures
  end
end

###########################################################################
# Will add code to view more data about selected option in a window
###########################################################################
def add_view_code
  return '' if (data = @record.send(@yaml['name'])).blank?

  table, form_name = @yaml['with_view'].split(/\ |\,/).delete_if(&:blank)
  url  = @parent.url_for(controller: 'cmsedit', id: data, action: :edit, table: table, form_name: form_name, readonly: true, window_close: 1 )
  icon = @parent.mi_icon('visibility-o md-18')
  %(<span class="dc-window-open" data-url="#{url}"> #{icon}</span>)
end

###########################################################################
# Will add code to view more data about selected option in a window
###########################################################################
def add_edit_code
  return '' if (data = @record.send(@yaml['name'])).blank?

  table, form_name = @yaml['view'].split(/\ |\,/).delete_if(&:blank)
  url  = @parent.url_for(controller: 'cmsedit', id: data, action: :edit, table: table, form_name: form_name, window_close: 1 )
  icon = @parent.mi_icon('edit-o md-18')
  %(<span class="dc-window-open" data-url="#{url}"> #{icon}</span>)
end

###########################################################################
# Return value when readonly is required
###########################################################################
def ro_standard
  value = @record.respond_to?(@yaml['name']) ? @record.send(@yaml['name']) : nil
  return self if value.blank?

  html = ''
  choices = get_choices()
  if value.class == Array   # multiple choices
    value.each do |element|
      choices.each do |choice|
        if choice.to_s == element.to_s
          html << '<br>' if html.size > 0
          html << "#{element.to_s}"
        end
      end       
    end
  else
    choices.each do |choice|
      if choice.class == Array
        (html = choice.first; break) if choice.last.to_s == value.to_s
      else
        (html = choice; break) if choice.to_s == value.to_s
      end 
    end
    html << add_view_code if @yaml['with_view']
  end
  super(html)
end

###########################################################################
# Render select field html code
###########################################################################
def render
  return ro_standard if @readonly

  set_initial_value('html','selected')
  # separate options and html part
  options_part = {}
  @yaml['html'].symbolize_keys!
  %i(selected include_blank).each { |sym| options_part[sym] = @yaml['html'].delete(sym) if @yaml['html'][sym] }
  @yaml['html'][:multiple] = true if @yaml['multiple']

  record = record_text_for(@yaml['name'])
  if @yaml['html'][:multiple]
    @yaml['html']['class'] = "#{@yaml['html']['class']} select-multiple"
    @html << @parent.select(record, @yaml['name'], get_choices, options_part, @yaml['html'])
    @js   << "$('##{record}_#{@yaml['name']}').selectMultiple();"
  else
    @html << @parent.select(record, @yaml['name'], get_choices, options_part, @yaml['html'])
    # add code for view more data
    @html << view_code_add() if @yaml['with_view']
    @html << edit_code_add() if @yaml['with_edit'] && !@readonly
  end
  self
end

###########################################################################
# Return value. 
###########################################################################
def self.get_data(params, name)
  if params['record'][name].class == Array
    params['record'][name].delete_if {|e| e.blank? }
    return if params['record'][name].size == 0

    # convert to BSON objects
    is_id = BSON::ObjectId.legal?(params['record'][name].first)
    return params['record'][name].map{ |e| BSON::ObjectId.from_string(e) } if is_id
  end
  params['record'][name]
end

end

end
