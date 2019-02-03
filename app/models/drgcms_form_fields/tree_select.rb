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
# Implementation of tree_select DRG CMS form field. Field will provides
# multiple select functionality displayed as a tree. Might be used for selecting
# multiple categories in a parent-child tree view.# 
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ tree_select (required)
# * +choices:+ Values for choices separated by comma. Values can also be specified like description:value.
# In this case description will be shown to user, but value will be saved to document.
#   choices: 'OK:0,Ready:1,Error:2'
#   choices: Ruby,Pyton,PHP
# * +eval:+ Choices will be provided by evaluating expression
#   eval: ModelName.choices4_field; Model class should define method which will provide data for field. 
#   Data returned must be of type Array and have 3 elements.
#   1 - description text
#   2 - id value
#   3 - parent id
# * +html:+ html options which apply to select and text_field fields (optional)
# 
# Form example:
#    10:
#      name: categories
#      type: tree_select
#      eval: 'Categories.all_categories'
#      html:
#        size: 50x10
###########################################################################
class TreeSelect < Select

###########################################################################
# Prepare choices for tree data rendering.
###########################################################################
def make_tree(parent)
  return '' unless @choices[parent.to_s]
  @html << '<ul>'
  choices = if @choices[parent.to_s].first[3] != 0
    @choices[parent.to_s].sort_by {|e| e[3].to_i } # sort by order if first is not 0
#    @choices[parent.to_s].sort_alphabetical_by(&:first) # use UTF-8 sort
  else  
    @choices[parent.to_s].sort_alphabetical_by(&:first) # use UTF-8 sort
  end
  choices.each do |choice|
    jstree = %Q[{"selected" : #{choice.last ? 'true' : 'false'} }]
# data-jstree must be singe quoted
    @html << %Q[<li data-id="#{choice[1]}" data-jstree='#{jstree}'>#{choice.first}\n]
# call recursively for children     
    make_tree(choice[1]) if @choices[ choice[1].to_s ]
    @html << "</li>"
  end
  @html << '</ul>'  
end

###########################################################################
# Render tree_select field html code
###########################################################################
def render
  return ro_standard if @readonly  
  set_initial_value('html','value')
  require 'sort_alphabetical'  
  
  record = record_text_for(@yaml['name'])
  @html << "<div id=\"#{@yaml['name']}\" class=\"tree-select\" #{set_style()} >"
# Fill @choices hash. The key is parent object id
  @choices = {}
  do_eval(@yaml['eval']).each {|data| @choices[ data[2].to_s ] ||= []; @choices[ data[2].to_s ] << (data << false)}
# put current values hash with. To speed up selection when there is a lot of categories
  current_values = {}
  current = @record[@yaml['name']] || []
  current = [current] unless current.class == Array # non array fields
  current.each {|e| current_values[e.to_s] = true}
# set third element of @choices when selected
  @choices.keys.each do |key|
    0.upto( @choices[key].size - 1 ) do |i|
      choice = @choices[key][i]
      choice[choice.size - 1] = true if current_values[ choice[1].to_s ]
    end
  end
  make_tree(nil)
  @html << '</ul></div>'
# add hidden communication field  
  @html << @parent.hidden_field(record, @yaml['name'], value: current.join(','))
# save multiple indicator for data processing on return
  @html << @parent.hidden_field(record, "#{@yaml['name']}_multiple", value: 1) if @yaml['multiple']
# javascript to update hidden record field when tree looses focus
  @js =<<EOJS
$(function(){
  $("##{@yaml['name']}").jstree( {
    "checkbox" : {"three_state" : false},        
    "core" : { "themes" : { "icons": false },
               "multiple" : #{@yaml['multiple'] ? 'true' : 'false'}  },
    "plugins" : ["checkbox"]
  });
});
  
$(document).ready(function() {
  $('##{@yaml['name']}').on('focusout', function(e) {
    var checked_ids = [];
    var checked = $('##{@yaml['name']}').jstree("get_checked", true);
    $.each(checked, function() {
      checked_ids.push( this.data.id );
    });
    $('#record_#{@yaml['name']}').val( checked_ids.join(",") );
  });
});
EOJS
  self
end

###########################################################################
# Return value. Return nil if input field is empty
###########################################################################
def self.get_data(params, name)
  return nil if params['record'][name].blank?
#
  result = params['record'][name].split(',')
  result.delete_if {|e| e.blank? }
  return nil if result.size == 0
# convert to BSON objects if is BSON object ID
  result = result.map{ |e| BSON::ObjectId.from_string(e) } if BSON::ObjectId.legal?(result.first)
# return only first element if multiple values select was not alowed
  params['record']["#{name}_multiple"] == '1' ? result : result.first  
end

end
end
