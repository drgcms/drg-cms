#--
# Copyright (c) 2020+ Damjan Rems
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
# Common methods required by reports
######################################################################
module DcReport
attr_accessor :report_id
attr_accessor :bulk

######################################################################
# Clear result if params[:clear] is 'yes' when form is first displayed
######################################################################
def dc_new_record
  DcTemp.clear(temp_key) unless params[:clear].to_s == 'no'
end

######################################################################
# If exists, set report section as form, so it can be used to display result.
######################################################################
def dc_update_form
  return unless @form && @form['report'] && CmsHelper.table_param(params) == 'dc_temp'

  @form = @form['report']
end

######################################################################
# Print to PDF action
######################################################################
def print
  begin
    pdf_do
  rescue Exception => e
    dc_dump_exception(e)
    render json: { msg_error: t('drgcms.runtime_error') } and return
  end

  pdf_file = "tmp/document-#{Time.now.to_i}.pdf"
  @pdf.render_file Rails.root.join('public', pdf_file)

  render json: print_response(pdf_file)
end

######################################################################
# Export data do excel action
######################################################################
def export
  export_to_excel( temp_key )
end

######################################################################
# Default filter to select data for result.
######################################################################
def data_filter
  params['clear'].to_s == 'yes' ? DcTemp.where(key: false) : DcTemp.where(key: temp_key).order_by(order: 1)
end

private

######################################################################
# Will create response message for print action. Response consists of
# opening pdf file in new browser tab and additional print_message if defined.
######################################################################
def print_response(pdf_file)
  response = { window: "/#{pdf_file}" }
  response.merge!(report_message) if respond_to?(:report_message, true)
  response
end

######################################################################
# Temp key consists of report name and user's id. Key should be added
# to every dc_temp document and is used to define data, which belongs
# to current user.
######################################################################
def temp_key
  "#{@report_id}-#{session[:user_id]}"
end

######################################################################
# Initialize report. Set report_id internal variable and initialize bulk
# for bulk saving data to dc_temp collection.
######################################################################
def init_report(id)
  @report_id = id
  @bulk = []
end

######################################################################
# Check if all send fields are blank.
######################################################################
def all_blank?(*fields)
  fields.each {|e| e.blank? ? true : (break false) }
end

######################################################################
# Will write bulk data to dc_temp collection.
######################################################################
def bulk_write(doc, the_end = false)
  if doc.nil? || doc.class == TrueClass
    the_end = true
  else
    @bulk << doc
  end

  if (the_end && @bulk.size > 0) || @bulk.size > 100
    DcTemp.collection.insert_many(@bulk) 
    @bulk = []
  end
end

######################################################################
# Export data to Excel
######################################################################
def export_to_excel(report_id)
  dc_form_read if @form.blank?
  # use report options if present
  columns = (@form['report'] ? @form['report'] : @form)['result_set']['columns'].sort

  n, workbook = 0, Spreadsheet::Workbook.new
  excel = workbook.create_worksheet(name: report_id)
  # header
  columns.each_with_index do |column, i|
    caption = column.last['caption'] || column.last['label']
    label = t(caption)
    excel[n, i] = label.match(/translation missing/i) ? caption : label
  end

  data_filter.each do |doc|
    n += 1
    columns.each_with_index do |column, i|
      value = doc[column.last['name']]
      value = case value.class.to_s
              when /Integer|Float/ then value
              when /Decimal/ then value.to_s.to_f
              else
                value.to_s.gsub('<br>', ";").gsub(/\<\/strong\>|\<strong\>|\<\/b\>|\<b\>/, '')
              end
      excel[n, i] = value
    end
  end
  file_name = "#{report_id}-#{Time.now.to_i}.xls"
  workbook.write Rails.root.join('public', 'tmp', file_name)
  dc_render_ajax(operation: :window, value: "/tmp/#{file_name}")
end

############################################################################
# Returns html code for displaying date/time formatted by strftime. Will return '' if value is nil.
# 
# Parameters:
# [value] Date/DateTime/Time.  
# [format] String. strftime format mask. Defaults to locale's default format.
############################################################################
def dc_format_date_time(value, format = nil)
  return '' if value.nil?

  format ||= value.class == Date ? t('date.formats.default') : t('time.formats.default')
  value.strftime(format)
end

##############################################################################
# Initialize PDF document for print
##############################################################################
def pdf_init(opts={})
  opts[:margin] ||= [30,30,30,30]
  opts[:page_size] ||= 'A4'

  pdf = Prawn::Document.new(opts)
  pdf.font_size = opts[:font_size] if opts[:font_size]

  pdf.encrypt_document( owner_password: :random,
                        permissions: { print_document: true,
                                       modify_contents: false,
                                       copy_contents: false,
                                       modify_annotations: false })
  pdf.font_families.update(
    'Arial' => { normal: Rails.root.join('public', 'arial.ttf'),
                 bold: Rails.root.join('public', 'arialbd.ttf') }
  )
  pdf.font 'Arial'
  pdf
end

################################################################################
# Prints out single text (or object) on report.
#
# @param [Object] txt : Text or object. Result of to_s method of the object is
# @param [Hash] opts
###############################################################################
def pdf_text(txt, opts = {})
  box_opts = opts.dup
  ypos = @pdf.cursor
  xpos = opts.delete(:atx) || 0
  box_opts[:single_line] ||= true
  box_opts[:at] ||= [xpos, ypos]

  @pdf.text_box(txt.to_s, box_opts)
end

################################################################################
# Skip line on report
#
# @param [Integer] skip . Number of lines to skip. Default 1.
###############################################################################
def pdf_skip(skip = 1)
  @pdf.text('<br>' * skip, inline_format: true)
end 

end
