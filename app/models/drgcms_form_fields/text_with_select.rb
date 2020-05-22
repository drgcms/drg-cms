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
# Implementation of text_with_select DRG CMS form field. Field will provide
# text_field entry field with select dropdown box with optional values for the field.
# Form options are mostly same as in select field. 
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ text_with_select (required)
# * +choices:+ Values for choices separated by comma. Values can also be specified like description:value.
# In this case description will be shown to user, but value will be saved to document.
#   choices: 'OK:0,Ready:1,Error:2'
#   choices: Ruby,Pyton,PHP
# * +eval:+ Choices will be provided by evaluating expression
#   eval: dc_choices4('model_name','description_field_name','_id'); dc_choices4 helper will provide data for select field. 
#   eval: ModelName.choices4_field; ModelName class will define method choices4_field which 
#   will provide data for select field. Since expression is evaluated in the context of Form Field object
# Even session session variables can be accessed. 
#   eval: 'MyClass.method(@parent.session[:user_id])'
# When searching is more complex custom search method may be defined in CollectionName 
# model which will provide result set for search.
#   eval: collection_name.search_field_name.method_name; 
# If choices or eval is not defined choices will be provided from translation helpers. For example: 
# Collection has field status. Choices for field will be provided by en.helpers.model_name.choices4_status 
# entry of english translation. English is of course default translation. If you provide translations in
# your local language then select choices will be localized.
#   en.helpers.model_name.choices4_status: 'OK:0,Ready:1,Error:2'
#   sl.helpers.model_name.choices4_status: 'V redu:0,Pripravljen:1,Napaka:2'
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
  #return ro_standard if @readonly  
  set_initial_value('html','value')
  
  record = record_text_for(@yaml['name'])
  @html << @parent.text_field( record, @yaml['name'], @yaml['html']) 
  @yaml['html']['class'] ||= ''
  @yaml['html']['class'] <<  ' text-with-select'
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
end
