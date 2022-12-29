#--
# Copyright (c) 2014+ Damjan Rems
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
# DRG Controls for DcPage model.
######################################################################
module DcPollResultControl

######################################################################
# Filter result data when filter is set
######################################################################
def poll_filter
  get_query
end

######################################################################
# Filter action called. Update url to reflect filter conditions and reload form.
######################################################################
def do_filter
  url = url_for(controller: 'cmsedit', action: :index, table: :dc_poll_result,
                'record[dc_poll_id]' => params[:record][:dc_poll_id],
                'record[start_date]' => params[:record][:start_date],
                'record[end_date]'   => params[:record][:end_date]
               )
  dc_render_ajax(operation: :url, value: url)
end

######################################################################
# Export data to file
######################################################################
def do_export
  c, keys = '', []
  get_query.to_a.each do |doc|
    # ensure, that fields are always in same order
    data = YAML.load(doc.data)
    if c.blank?
      data.each { |k, v| keys << k }
      c << I18n.t('helpers.label.dc_poll_result.created_at') + "\t"
      c << keys.join("\t") + "\n"
    end
    c << doc.created_at.strftime(I18n.t('date.formats.default') ) + "\t"
    keys.each { |k| c << data[k] + "\t" }
    c << "\n"
  end
  File.write(Rails.root.join('public', 'export.csv'), c)
  dc_render_ajax(operation: :window, value: 'export.csv')
end

private
######################################################################
# Creates query for Poll results
######################################################################
def get_query
  if params.dig(:record, :dc_poll_id).nil?
    qry = DcPollResult.all
  else  
    qry = DcPollResult.where(dc_poll_id: params[:record][:dc_poll_id])
    unless params[:record][:start_date].blank?
      start_date = DrgcmsFormFields::DatePicker.get_data(params,'start_date').beginning_of_day
      end_date   = DrgcmsFormFields::DatePicker.get_data(params,'end_date').end_of_day
      qry = qry.and(:created_at.gt => start_date).and(:created_at.lt => end_date)
    end
  end
  qry
end

end 
