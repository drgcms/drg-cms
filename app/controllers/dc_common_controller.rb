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

########################################################################
# This controller holds some common actions used by CMS.
########################################################################
class DcCommonController < DcApplicationController
layout false

########################################################################
# This action is called on ajax autocomplete call. It checks if user has rights to
# view data. 
# 
# URL parameters:
# [table] Table (collection) model name in lower case indicating table which will be searched.
# [id] Name of id key field that will be returned. Default is '_id'
# [input] Search data entered in input field.
# [search] when passed without dot it defines field name on which search 
# will be performed. When passed with dot class_method.method_name is assumed. Method name will
# be parsed and any class with class method name can be evaluated. Class method must accept
# input parameter and return array [ [_id, value],.. ] which will be used in autocomplete field.
# 
# Return:
# JSON array [label, value, id] of first 20 documents that confirm to query.
########################################################################
def autocomplete
  # table parameter must be defined. If not, get it from search parameter
  if params['table'].nil? and params['search'].match(/\./)
    name = params['search'].split('.').first
    params['table'] = name.underscore
  end
  return render plain: t('drgcms.not_authorized') unless dc_user_can(DcPermission::CAN_VIEW)

  table = params['table'].classify.constantize
  id    = [params['id']] || '_id'
  input = params['input'].gsub(/\(|\)|\[|\]|\{|\}/, '')
  # call method in class if search parameter contains . This is for user defined searches
  a = if params['search'].match(/\./)
        name, method = params['search'].split('.')
        table.send(method, input).map do |v|
          { label: v[0], value: v[0], id: (v[1] || v[0]).to_s }
        end
      # will search and return field_name defined in params['search']
      else
        table.where(params['search'] => /#{input}/i).limit(20).map do |v|
          { label: v[params['search']], value: v[params['search']], id: v.id.to_s }
        end
      end

  render plain: a.to_json
end

########################################################################
# Register and record click when ad link is clicked.
########################################################################
def ad_click
  if params[:id] and (ad = DcAd.find(params[:id]))
    ad.clicked += 1
    ad.save
    DcAdStat.create!(dc_ad_id: params[:id], ip: request.ip, type: 2 ) 
  else
    logger.error "ERROR ADS: Invalid ad id=#{params[:id]} ip=#{request.ip}."
  end

  render body: nil
end

##########################################################################
# Toggle CMS edit mode.This action is called when user clicks CMS option on 
# top of the browser.
##########################################################################
def toggle_edit_mode
  session[:edit_mode] ||= 0 
  # error when not logged in
  return dc_render_404 if session[:edit_mode] < 1

  # if return_to_ypos parameter is present it will forward it and thus scroll to
  # aproximate position it was when toggle was clicked
  session[:edit_mode] = (session[:edit_mode] == 1) ? 2 : 1
  uri = Rack::Utils.parse_nested_query(request.url)
  # it parses only on & so first (return_to) parameter also contains url
  url = uri.first.last
  if (i = url.index('return_to_ypos')).to_i > 0
    url = url[0, i-1]
  end 
  # offset CMS menu
  if (ypos = uri['return_to_ypos'].to_i) > 0
    ypos += session[:edit_mode] == 2 ? 250 : -250
  end
  url << (url.match(/\?/) ? '&' : '?')
  url << "return_to_ypos=#{ypos}"
  redirect_to url
end

####################################################################
# Default user login action.
####################################################################
def process_login
  # Somebody is probably playing
  return dc_render_404 unless ( params[:record] && params[:record][:username] && params[:record][:password] )

  unless params[:record][:password].blank? #password must not be empty
    user  = DcUser.find_by(username: params[:record][:username], active: true)
    if user and user.authenticate(params[:record][:password])
      fill_login_data(user, params[:record][:remember_me].to_i == 1)
      return redirect_to params[:return_to] ||  '/'
    else
      clear_login_data # on the safe side
    end
  end
  flash[:error] = t('drgcms.invalid_username')
  redirect_to params[:return_to_error] ||  '/'
end

####################################################################
# Default user logout action.
####################################################################
def logout
  clear_login_data
  redirect_to params[:return_to] || '/'
end

####################################################################
# Alternative login action with remember_me cookie. If found it will automatically 
# login user otherwise user will be presented with regular login dialog.
####################################################################
def login
  if cookies.signed[:remember_me]
    user = DcUser.find(cookies.signed[:remember_me])
    if user and user.active
      fill_login_data(user, true)
      return redirect_to params[:return_to]
    else
      clear_login_data # on the safe side
    end
  end
  # Display login
  route = params[:route] || 'poll'
  redirect_to "/#{route}?poll_id=login&return_to=#{params[:return_to]}"
end

####################################################################
# Action for restoring document data from journal document.
####################################################################
def restore_from_journal
  # Only administrators can perform this operation
  unless dc_user_has_role('admin')
    return render plain: { 'msg_info' => (t ('drgcms.not_authorized')) }.to_json
  end
  # selected fields to hash
  restore = {} 
  params[:select].each { |key,value| restore[key] = value if value == '1' }
  result = if restore.size == 0
    { 'msg_error' => (t ('drgcms.dc_journal.zero_selected')) }
  else
    journal_doc = DcJournal.find(params[:id])
    # update hash with data to be restored
    JSON.parse(journal_doc.diff).each {|k,v| restore[k] = v.first if restore[k] }
    # determine tables and document ids
    tables = journal_doc.tables.split(';')
    ids = (journal_doc.ids.blank? ? [] : journal_doc.ids.split(';') ) << journal_doc.doc_id
    # find document
    doc = nil
    tables.each_index do |i|
      doc = if doc.nil?
        (tables[i].classify.constantize).find(ids[i])
      else
        doc.send(tables[i].pluralize).find(ids[i])
      end
    end
    # restore and save values
    restore.each { |field,value| doc.send("#{field}=",value) }
    doc.save
    # TODO Error checking
    { 'msg_info' => (t ('drgcms.dc_journal.restored')) }
  end
  render plain: result.to_json
end

########################################################################
# Copy current record to clipboard as json text. It will actually ouput an 
# window with data formatted as json.
########################################################################
def copy_clipboard
  # Only administrators can perform this operation
  return render(plain: t('drgcms.not_authorized') )  unless dc_user_can(DcPermission::CAN_ADMIN,'dc_site')

  respond_to do |format|
    # just open new window to same url and come back with html request
    format.json { dc_render_ajax(operation: 'window', url: request.url ) }
    
    format.html do
      doc = dc_find_document(params[:table], params[:id], params[:ids])
      text = "<br><br>[#{params[:table]},#{params[:id]},#{params[:ids]}]<br>"
      render plain: text + doc.as_document.to_json
    end
  end  
end

########################################################################
# Paste data from clipboard into text_area and update documents in destination database.
# This action is called twice. First time for displaying text_area field and second time 
# ajax call for processing data.
########################################################################
def paste_clipboard
  # Only administrators can perform this operation
  return render(plain: t('drgcms.not_authorized') )  unless dc_user_can(DcPermission::CAN_ADMIN,'dc_site')

  result = ''
  respond_to do |format|
    # just open new window to same url and come back with html request
    format.html { return render('paste_clipboard', layout: 'cms') }
    format.json {
      table, id, ids = nil
      params[:data].split("\n").each do |line|
        line.chomp!
        next if line.size < 5                 # empty line. Skip

        begin
          if line[0] == '['                   # id(s)
            result << "<br>#{line}"
            line = line[/\[(.*?)\]/, 1]       # just what is between []
            table, id, ids = line.split(',')
          elsif line[0] == '{'                # document data
            result << process_document(line, table, id, ids)
          end
        rescue Exception => e 
          result << " Runtime error. #{e.message}\n"
          break
        end
      end
    }
  end
  dc_render_ajax(div: 'result', value: result )
end

########################################################################
# Will add new json_ld element with blank structure into dc_json_ld field on a 
# document.
########################################################################
def add_json_ld_schema
  edited_document = DcJsonLd.find_document_by_ids(params[:table], params[:ids])
  yaml = YAML.load_file( dc_find_form_file('json_ld_schema') )
  schema_data = yaml[params[:schema]]
  # Existing document
  if edited_document.dc_json_lds.find_by(type: "@#{params[:schema]}")
    return render json: {'msg_error' => t('helpers.help.dc_json_ld.add_error', schema: params[:schema] ) }
  else
    add_empty_json_ld_schema(edited_document, schema_data, params[:schema], params[:schema], yaml)
  end
  render json: {'reload_' => 1}
end

########################################################################
# Will provide help data
########################################################################
def help
  form_name = params[:form_name] || params[:table]
  @form = form_name ? YAML.load_file(dc_find_form_file(form_name)) : {}
  return render json: {} if @form.nil?

  help_file_name = @form['help'] || @form['extend'] || params[:form_name] || params[:table]
  help_file_name = find_help_file(help_file_name)
  @help = YAML.load_file(help_file_name) if help_file_name
  # no auto generated help on index action
  return render json: {} if params[:type] == 'index' && @help.nil?

  render json: { popup: render_to_string(partial: 'help') }
end

protected

########################################################################
# Will search for help file and return it's path if found
########################################################################
def find_help_file(help_file_name)
  file_name = nil
  DrgCms.paths(:forms).reverse.each do |path|
    f = "#{path}/help/#{help_file_name}.#{I18n.locale}"
    file_name = f and break if File.exist?(f)
  end
  file_name
end

########################################################################
# Subroutine of add_json_ld_schema for adding one element
########################################################################
def add_empty_json_ld_schema(edited_document, schema, schema_name, schema_type, yaml) #:nodoc
  data = {}
  doc = DcJsonLd.new
  doc.name = schema_name
  doc.type = schema_type
 
  edited_document.dc_json_lds << doc
  schema.each do |element_name, element|
    next if element_name == 'level' # skip level element
    if yaml[element['type']]
      if element['n'].to_s == '1'
        # single element
        doc_1 = yaml[element['type'] ]
        data[element_name] = doc_1
      else
        # array
        add_empty_json_ld_schema(doc, yaml[element['type']], element_name, element['type'], yaml)
      end
    else
      data[element_name] = element['text']
    end
  end
  doc.data = data.to_yaml
  doc.save
end

########################################################################
# Update some anomalies in json data on paste_clipboard action.
########################################################################
def update_json(json, is_update=false) #:nodoc:
  result = {}
  json.each do |k,v|
    if v.class == Hash
      result[k] = v['$oid'] unless is_update
      # TODO Double check if unless works as expected
    elsif v.class == Array
      result[k] = []
      v.each {|e| result[k] << update_json(e, is_update)}
    else
      result[k] = v
    end
  end 
  result
end

########################################################################
# Processes one document. Subroutine of paste_clipboard.
########################################################################
def process_document(line, table, id, ids)
  if params[:do_update] == '1' 
    doc = dc_find_document(table, id, ids)
    # document found. Update it and return
    if doc
      doc.update( update_json(ActiveSupport::JSON.decode(line), true) )
      msg = dc_check_model(doc)
      return (msg ? " ERROR! #{msg}" : " UPDATE. OK.")
    end
  end
  # document will be added to collection
  if ids.to_s.size > 5
    #TODO Add embedded document
    " NOT SUPPORTED YET!"
  else
    doc = table.classify.constantize.new( update_json(ActiveSupport::JSON.decode(line)) )
    doc.save
  end
  msg = DrgCms.model_check(doc)
  msg ? " ERROR! #{msg}" : " NEW. OK." 
end

end
