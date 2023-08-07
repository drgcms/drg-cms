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
# Set filter action called from form.
######################################################################
def filter_set
  record = params[:record]
  filter = "DcPollResult.where(dc_poll_id: '#{record[:dc_poll_id]}')"
  filter << ".and(:created_at.gte => '#{Time.parse(record[:start_date]).beginning_of_day}')" if record[:start_date].present?
  filter << ".and(:created_at.lte => '#{Time.parse(record[:end_date]).end_of_day}')" if record[:end_date].present?

  session['dc_poll_result'][:filter] = {'field'     => I18n.t('drgcms.filter_off'),
                                        'operation' => 'eval',
                                        'value'     => filter,
                                        'input'     => '',
                                        'table'     => 'dc_poll_result' }.to_yaml
  session['dc_poll_result'][:page] = 1 # must also be set

  render json: { url: '/cmsedit?t=dc_poll_result'}
end

######################################################################
# Export data to file
######################################################################
def data_export
  c, keys = '', []
  data_get.to_a.each do |doc|
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
def data_get
  return [] if session.dig('dc_poll_result', :filter).blank?

  filter = YAML.load(session['dc_poll_result'][:filter])
  eval filter['value'] rescue []
end

end 
