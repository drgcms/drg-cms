#--
# Copyright (c) 2022+ Damjan Rems
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

######################################################################
# Common controls for cms controller
######################################################################
module CmseditControl

######################################################################
#
######################################################################
def filter_off
  table_name = CmsHelper.table_param(params).strip.split(';').first.underscore
  session[table_name][:filter] = nil
  url = url_for( controller: 'cmsedit', t: table_name, f: CmsHelper.form_param(params))

  render json: { url: url }
end

######################################################################
#
######################################################################
def filter_on
  table_name = CmsHelper.table_param(params).strip.split(';').first.underscore
  set_session_filter(table_name)
  url = url_for( controller: 'cmsedit', t: table_name, f: CmsHelper.form_param(params))

  render json: { url: url }
end

private
########################################################################
# Will set session[table_name][:filter] and save last filter settings to session.
# subroutine of check_filter_options.
########################################################################
def set_session_filter(table_name)
  # models that can not be filtered (for now)
  return if %w(dc_temp dc_memory).include?(CmsHelper.table_param(params))
  # field_name should exist on set filter condition
  return if params[:filter_oper] && params[:filter_field].blank?

  filter_value = if params[:filter_value].nil?
                   #NIL indicates that no filtering is needed
                   '#NIL'
                 else
                   if params[:filter_value].class == String && params[:filter_value][0] == '@'
                     # Internal value. Remove leading @ and evaluate expression
                     expression = DcInternals.get(params[:filter_value])
                     eval(expression) rescue '#NIL'
                   else
                     # No filter when empty
                     params[:filter_value] == '' ? '#NIL' : params[:filter_value]
                   end
                 end
  # if filter field parameter is omitted then just set filter value
  session[table_name][:filter] =
    if params[:filter_field].nil?
      saved = YAML.load(session[table_name][:filter])
      saved['value'] = filter_value
      saved.to_yaml
    else
      # as field defined. Split name and alternative input field
      field = if params[:filter_field].match(' as ')
                params[:filter_input] = params[:filter_field].split(' as ').last.strip
                params[:filter_field].split(' as ').first.strip
              else
                params[:filter_field]
              end

      {'field'     => field,
       'operation' => params[:filter_oper],
       'value'     => filter_value,
       'input'     => params[:filter_input],
       'table'     => table_name }.to_yaml
    end
  # must be. Otherwise kaminari includes parames on paging links
  params[:filter_id]     = nil
  params[:filter_oper]   = nil
  params[:filter_input]  = nil
  params[:filter_field]  = nil
end

end 
