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
# Implementation of text_autocomplete DRG CMS form field.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ text_autocomplete (required)
# * +table+ Collection (table) name. When defined search must contain field name
# * +with_new+ Will add an icon for shortcut to add new document to collection
# * +is_id+ Field value represent value as id. If false, field will use entered value and not value selected with autocomplete. Default is true.
# * +search:+ Search may consist of three parameters from which are separated either by dot (.) 
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
#      is_id: false
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
    table, ret_name, method = @yaml['search'].split(/\.|\,/).map(&:strip)
  else
    ret_name = @yaml['search']
  end
  # determine table name
  if @yaml['table']
    table = if @yaml['table'].class == String
      @yaml['table']
    elsif @yaml['table']['eval']
      eval @yaml['table']['eval']
    else
      Rails.logger.error "Field #{ @yaml['name'] }: Invalid table parameter!"
      nil
    end
  end
  return ro_standard 'Table or field keyword not defined!' unless (table && ret_name)
  # TODO check if table exists
  t = table.classify.constantize
  # find record and return value of field
  value_send_as = 'p_' + @yaml['name']
  value = if @parent.params[value_send_as]
    @parent.params[value_send_as]
  elsif @record and @record[@yaml['name']]
    @record[@yaml['name']]
  end
  # Found value to be written in field. If field is not found write out value.
  not_id = @parent.dc_dont?(@yaml['is_id'], false)
  if value
    record = t.find(value) unless not_id # don't if it's is not an id
    value_displayed = record ? record.send(ret_name) : value
  end
  # return if readonly
  return ro_standard(value_displayed) if @readonly
  # Add method back, so autocomplete will know that it must search for method inside class
  ret_name = "#{ret_name}.#{method}" if method
  @yaml['html'] ||= {}
  @yaml['html']['value'] = value_displayed
  @yaml['html']['placeholder'] ||= t('drgcms.search_placeholder') || nil
  #
  _name = '_' + @yaml['name']
  record = record_text_for(@yaml['name'])  
  @html << '<span class="dc-text-autocomplete">' + @parent.text_field(record, _name, @yaml['html']) + '<span></span>'
  if @yaml['with_new']
    @html << ' ' + 
             @parent.fa_icon('plus-square lg', class: 'in-edit-add', title: t('drgcms.new'), 
             style: "vertical-align: top;", 'data-table' => @yaml['with_new'] )    
  end
  @html << '</span>' + @parent.hidden_field(record, @yaml['name'], value: value)        # actual value will be in hidden field
  # JS stuff
  # allow unselected values on is_id: false option
  not_id_code = %(
if (ui.item == null) {  
$("##{record}_#{@yaml['name']}").val($("##{record}__#{@yaml['name']}").val() );
return;
} ) if not_id
  #
  @js << <<EOJS
$(document).ready(function() {
  $("##{record}_#{_name}").autocomplete( {
    source: function(request, response) {
      $.ajax({
        url: "/dc_common/autocomplete",
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
      #{not_id_code}
      if (ui.item == null) return;
      $("##{record}_#{@yaml['name']}").val(ui.item.id);
    },

    minLength: 2
  });
});
EOJS
    
  self 
end

###########################################################################
# Return value. Return nil if input field is empty
###########################################################################
def self.get_data(params, name)
  params['record']["_#{name}"].blank? ? nil : params['record'][name]
end

end
end
