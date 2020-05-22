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
def choices_in_helper(all)
  helper = "helpers.label.#{@form['table']}.choices4_#{@yaml['name']}"
  c = t(helper)
  if c.match( 'translation missing' )
    helper = "choices_for_#{@form['table']}_#{@yaml['name']}"
    return "Error. #{helper} not defined" if c.match( 'translation missing' )
  end
  c
end

###########################################################################
# Choices are defined by evaluating an exspression. This is most common class
# method defined in a class. SomeClass.get_choices4.
###########################################################################
def choices_in_eval(e, all=false)
  e.strip!
  if @yaml['depend'].nil?
    method = e.split(/\ |\(/).first
    return eval(e) if respond_to?(method) # id method defined here
    return eval('@parent.'+e) if @parent.respond_to?(method) # is method defined in helpers
    # eval whatever it is there
    eval e
  else
    # add event listener to depend field
    @js << %Q[
$(document).ready(function() {
  $('#record_#{@yaml['depend']}').change( function(e) { update_select_depend('record_#{@yaml['name']}', 'record_#{@yaml['depend']}','#{e}');});
  $('#_record_#{@yaml['depend']}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '_record_#{@yaml['depend']}','#{e}');});
});
]
    # depend field might be virtual field. Its value should be set in params
    depend_value = if @yaml['depend'][0] == '_'
      @parent.params["p_#{@yaml['depend']}"]
    else
      @record[@yaml['depend']]
    end
    
    e << " '#{depend_value}'"
    eval e
  end
end

###########################################################################
# Create choices array for select field.
###########################################################################
def get_choices(all=false)
  begin
    choices = case 
    when @yaml['choices'] then 
      @yaml['choices']
    when @yaml['eval']    then
      choices_in_eval(@yaml['eval'], all)
    else
      choices_in_helper(all)
    end
  # Convert string to Array
    choices.class == String ?
      choices.chomp.split(',').inject([]) {|r,v| r << (v.match(':') ? v.split(':') : v )} :
      choices
  rescue Exception => e 
    Rails.logger.debug "Error in select eval. #{e.message}\n"
    ['error'] # return empty array when error occures
  end
end

###########################################################################
# Return value when readonly is required
###########################################################################
def ro_standard
  #value   = @yaml['html']['value'] ? @yaml['html']['value'] : nil
  value = @record.respond_to?(@yaml['name']) ? @record[@yaml['name']] : nil
  return self if value.nil?
# 
  choices = get_choices()
  if value.class == Array   # multiple choices
    html = ''
    value.each do |element|
      choices.each do |choice|
        if choice.to_s == element.to_s
          html << '<br>' if html.size > 0
          html << "#{element.to_s}"
        end
      end       
    end
    return super(html)
  else
    choices.each do |choice|
      if choice.class == Array
        return super(choice.first) if choice.last.to_s == value.to_s
      else
        return super(choice) if choice.to_s == value.to_s
      end 
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
  if @yaml['multiple']  
    @html << @parent.select(record, @yaml['name'], get_choices, @yaml['html'], {multiple: true})
    @js   << "$('##{record}_#{@yaml['name']}').selectMultiple();"
  else
    @html << @parent.select(record, @yaml['name'], get_choices, @yaml['html'])
  end
  self
end

###########################################################################
# Return value. 
###########################################################################
def self.get_data(params, name)
  if params['record'][name].class == Array
    params['record'][name].delete_if {|e| e.blank? }
    return nil if params['record'][name].size == 0
# convert to BSON objects   
    is_id = BSON::ObjectId.legal?(params['record'][name].first)
    return params['record'][name].map{ |e| BSON::ObjectId.from_string(e) } if is_id
    return params['record'][name]
  end
  params['record'][name]
end

end
end
