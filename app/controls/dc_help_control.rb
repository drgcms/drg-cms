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
    # far less complicated if saved to session
    session[:help_project] = params[:record][:select_project]
    session[:help_lang] = params[:record][:lang_1]
    help_dir_name = "#{session[:help_project]}/help/"
    # create help directory if not yet exists
    FileUtils.mkdir(help_dir_name) unless File.exist?(help_dir_name)
    Dir["#{help_dir_name}*"].each do |file_name|
      lang = File.extname(file_name).sub('.','')
      next unless lang == session[:help_lang]

      DcTemp.new(key: temp_key,
                 project: session[:help_project],
                 form_name: File.basename(file_name,'.*'),
                 lang: lang,
                 updated_at: File.mtime(file_name)).save
    end
  end
  render json: { url: url_for(controller: :cmsedit, table: :dc_temp, form_name: :dc_help_1) }
end

######################################################################
# Will populate fields with default values
######################################################################
def dc_new_record
  @record.project = session[:help_project]
  @record.lang = session[:help_lang]
end

######################################################################
# Will read data from help file
######################################################################
def dc_before_edit
  file_name = "#{session[:help_project]}/help/#{@record.form_name}.#{session[:help_lang]}"
  data = YAML.load_file(file_name)
  @record.index = data['index']
  @record.form = data['form']
  flash[:warning] = "Use only in development!" unless Rails.env.development?
end

######################################################################
# Will save data to help file
######################################################################
def dc_before_save
  rec = params[:record]
  file_name = "#{session[:help_project]}/help/#{@record.form_name}.#{@record.lang}"
  data = { 'index' => @record.index, 'form' => @record.form }
  File.write(file_name, data.to_yaml)
end

######################################################################
# Will return query to report data
######################################################################
def data_filter
  DcTemp.where(key: temp_key).order_by(order: 1)
end

private

######################################################################
# Will return choices for select project input field on a form
######################################################################
def self.choices_for_project
  r = DrgCms.paths(:forms).map do |path|
    path = path.to_s
    a = path.split('/')
    project = a[a.size - 3]
    project = if project == 'app'
                a[a.size - 4] + ' : ' + a.last(2).join('/')
              else
                project + ' : ' + a.last
              end
    [project, path]
  end
  [[I18n.t('drgcms.dc_help.project'), nil]] + r.sort
end

######################################################################
# Will return choices for selecting help file name, based on forms already
# present in forms directory.
######################################################################
def self.choices_for_form_name(session)
  Dir["#{session[:help_project]}/*.yml"].map { |file_name| File.basename(file_name,'.*') }.sort
end

######################################################################
# Will return temp key for data saved in dc_temp file
######################################################################
def temp_key
  "dc-help-#{session[:user_id]}"
end

end 
