#--
# Copyright (c) 2021+ Damjan Rems
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
# Controls for creating help files
######################################################################
module DcHelpControl

######################################################################
# Will fill dc_temp with help documents found in a defined project directory.
######################################################################
def project_refresh
  DcTemp.clear(temp_key)
  if params[:record][:select_project].present?
    session[:help_project] = params[:record][:select_project]
    help_dir_name = "#{session[:help_project]}help/"
    FileUtils.mkdir(help_dir_name) unless File.exist?(help_dir_name)

    Dir["#{help_dir_name}*"].each do |file_name|
      DcTemp.new(key: temp_key,
                 project: session[:help_project],
                 form_name: File.basename(file_name,'.*'),
                 locale: File.extname(file_name).sub('.',''),
                 updated_at: File.mtime(file_name)).save
    end

  end
  url = "/cmsedit?form_name=dc_help_1&table=dc_temp&p_select_project=#{params[:record][:select_project]}"
  render json: { url: url }
end

######################################################################
# Will save data to help file
######################################################################
def dc_before_save
  rec = params[:record]
  file_name = "#{@record.project}help/#{@record.form_name}.#{@record.locale}"
  data = { 'index' => @record.index, 'form' => @record.form }
  File.write(file_name, data.to_yaml)
end

######################################################################
# Will save data to help file
######################################################################
def dc_before_edit
  return if @record.new_record?

  file_name = "#{@record.project}help/#{@record.form_name}.#{@record.locale}"
  data = YAML.load_file(file_name)
  @record.index = data['index']
  @record.form = data['form']
end


######################################################################
# Will return query to report data
######################################################################
def data_filter
  DcTemp.where(key: temp_key).order_by(order: 1).collation(locale: 'sl')
end

private

######################################################################
# Will return choices for select project input field on a form
######################################################################
def self.choices_for_project
  r = DrgCms.paths(:forms).map do |path|
    path = path.to_s.delete_suffix('forms')
    a = path.split('/')
    project = a[a.size - 2]
    project = nil if project == 'app'
    [project, path]
  end
  [['Project', nil]] + r.select(&:first).sort
end

######################################################################
# Will return temp key for data saved in dc_temp file
######################################################################
def temp_key
  "dc-help-#{session[:user_id]}"
end

end 
