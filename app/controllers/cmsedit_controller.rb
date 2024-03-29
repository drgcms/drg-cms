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
# This is main controller for processing actions by DRG forms. It provides 
# CRUD actions for editing MongoDB documents. DRG CMS does not require controller
# to be made for every document model but centers all actions into single 
# controller. Logic required to control data entry is provided within DRG 
# forms which are loaded dynamically for every action.
# 
# Most of data entry controls must therefore be done in document models definitions. 
# And there are controls that cannot be done in document models. Like controls
# which include url parameters or accessing session variables. This is hard to be done
# in model therefore cmsedit_controls had to be invented. cmsedit_controls are
# modules with methods that are injected into cmsedit_controller and act in runtime like 
# they are part of cmsedit_controller. 
# 
# Since Ruby and Rails provide some automagic loading of modules DRG CMS controls must be saved 
# into app/controllers/drgcms_controls folder. Every model can have its own controls file. 
# dc_page model's controls live in dc_page_controls.rb file. If model has embedded document
# its control's would be found in model_embedded_controls.rb. By convention module names
# are declared in camel case, so our dc_page_controls.rb declares DrgcmsControls::DcPageControls module.
# 
# Controls (among other) may contain 7 callback methods.
# These methods are:
# * dc_new_record
# * dc_dup_record
# * dc_before_edit
# * dc_before_save
# * dc_after_save
# * dc_before_delete
# * dc_after_delete
# 
# Methods dc_before_edit, before_save or before_delete may also effect flow of the application. If
# method return false (not nil but FalseClass) normal flow of the program is interrupted and last operation
# is canceled. 
# 
# Second control methods that can be declared in DRG CMS controls are filters for
# viewing and sorting documents. It is often required that dynamic filters are 
# applied to result_set documents. 
# 
#    result_set:
#      filter: current_users_documents
#      
# Example implemented controls method:
# 
#    def current_users_documents
#      if dc_user_can(DcPermission::CAN_READ)
#        dc_page.where(created_by: session[:user_id])
#      else
#        flash[:error] = 'User can not perform this operation!'
#        nil
#      end
#    end
#      
# If filter method returns false user will be presented with flash error.
########################################################################
class CmseditController < DcApplicationController
before_action :check_authorization, :except => [:login, :logout, :test, :run]
protect_from_forgery with: :null_session, only: Proc.new { _1.request.format.json? }
  
layout 'cms'

########################################################################
# Index action 
########################################################################
def index
  @form['result_set'] ||= {}
  redirected = (@form['table'] == 'dc_memory' ? process_in_memory : process_collections)
  return if redirected

  call_callback_method(@form['result_set']['footer'] || 'dc_footer')
  respond_to do |format|
    format.html { render action:  :index }
    format.js   { render partial: :result }
  end
end

########################################################################
# Filter action. 
########################################################################
def _filter
  index
end

########################################################################
# Show displays record in readonly mode.
########################################################################
def show
  find_record
  if @record.nil?
    flash[:error] ||= t('drgcms.doc_no_edit')
    return index
  end
  # before_show callback
  if (m = callback_method('before_show') )
    ret = call_callback_method(m)
    if ret.class == FalseClass
      @form['readonly'] = nil # must be
      flash[:error] ||= t('drgcms.not_authorized')
      return index
    end
  end  

  render action: 'edit', layout: 'cms'
end

########################################################################
# Login action. Used to login direct to CMS. It is mostly used when first time
# creating site and when something goes so wrong, that traditional login procedure 
# is not available.
# 
# Login can be called directly with url http://site.com/cmsedit/login
########################################################################
def login
  return set_test_site if params[:id] == 'test'

  session[:edit_mode] = 0 if !params[:ok]
  render action: 'login', layout: 'cms'
end

########################################################################
# Logout action. Used to logout direct from CMS.
# 
# Logout can be called directly with url http://site.com/cmsedit/logout
########################################################################
def logout 
  session[:edit_mode] = 0
  session[:user_id]   = nil
  render action: 'login', layout: 'cms'
end

########################################################################
# Shortcut for setting currently selected site in development. Will search
# for dc_site document with site name 'test' and set alias_for to site
# url parameter.
########################################################################
def set_test_site 
  # only in development
  return dc_render_404 unless Rails.env.development?

  alias_site = DcSite.find_by(:name => params[:site])
  return dc_render_404 unless alias_site

  # update alias for  
  site = DcSite.find_by(:name => 'test')
  site.alias_for = params[:site]
  site.save
  redirect_to '/'
end

########################################################################
# New action.
########################################################################
def new
  # clear flash messages.
  flash[:error] = flash[:warning] = flash[:info] = nil 
  create_new_empty_record
  # before_new callback
  if (m = callback_method('before_new') )
    ret = call_callback_method(m)
    return index if ret.class == FalseClass
  end  
  table = @tables.last[1] + '.'
  # initial values set on page
  if cookies[:record] && cookies[:record].size > 0
    Marshal.load(cookies[:record]).each do |k,v|
      k = k.to_s
      if k.match(table)
        field = k.split('.').last
        @record.send("#{field}=", v) if @record.respond_to?(field)
      end
    end
  end
  # initial values set in url (params)
  params.each do |k,v|
    if k.match(table)
      field = k.split('.').last
      @record.send("#{field}=", v) if @record.respond_to?(field)
    end
  end
  # new_record callback. Set default values for new record
  if (m = callback_method('new_record') ) then call_callback_method(m)  end
  @form_params['action'] = 'create'
end

########################################################################
# Duplicate embedded document. Since embedded documents are returned differently 
# then top level document. Subroutine of duplicate_socument.
#
#TODO Works for two embedded levels. Dies with third and more levels.
########################################################################
def duplicate_embedded(source) #:nodoc:
  dest = {}
  source.each do |attribute_name, value|
    next if attribute_name == '_id' # don't duplicate _id

    if value.class == Array
      dest[attribute_name] = []
      value.each do |ar|
        dest[attribute_name] << duplicate_embedded(ar)
      end
    else
      # if duplicate, string dup is added. For unique fields
      add_duplicate = params['dup_fields'].to_s.match(attribute_name + ',')
      dest[attribute_name] = value
      dest[attribute_name] << ' dup' if add_duplicate
    end
  end
  dest['created_at'] = Time.now if dest['created_at']
  dest['updated_at'] = Time.now if dest['updated_at']
  dest
end

########################################################################
# Will create duplicate document of source document. This method is used for 
# duplicating document and is subroutine of create action.
########################################################################
def duplicate_document(source)
  params['dup_fields'] += ',' if params['dup_fields'] # for easier field matching
  dest = {}
  source.attribute_names.each do |attribute_name|
    next if attribute_name == '_id' # don't duplicate _id

    # if duplicate, string dup is added. For unique fields
    add_duplicate = params['dup_fields'].to_s.match(attribute_name + ',')
    dest[attribute_name] = source[attribute_name]
    dest[attribute_name] << ' dup' if add_duplicate
  end
  # embedded documents
  source.embedded_relations.keys.each do |embedded_name|
    next if source[embedded_name].nil? # it happens

    dest[embedded_name] = []
    source[embedded_name].each do |embedded|
      dest[embedded_name] << duplicate_embedded(embedded)
    end
  end
  dest['created_at'] = Time.now if dest['created_at']
  dest['updated_at'] = Time.now if dest['updated_at']
  dest
end

########################################################################
# Create (or duplicate) action.
########################################################################
def create
  # not authorized
  unless dc_user_can(DcPermission::CAN_CREATE)
    flash[:error] = t('drgcms.not_authorized')
    return index
  end

  # create document
  if params['id'].nil?
    # Prevent double form submit
    return index if double_form_submit?

    create_new_empty_record
    if save_data
      flash[:info] = t('drgcms.doc_saved')
      params[:return_to] = 'index' if params[:commit] == t('drgcms.save&back') # save & back
      return process_return_to(params[:return_to]) if params[:return_to]

      @form_params['id'] = @record.id # must be set, for proper update link
      params[:id]  = @record.id # must be set, for find_record
      edit
    else # error
      return process_return_to(params[:return_to]) if params[:return_to]

      render action: :new
    end
  else # duplicate record
    find_record
    new_doc = duplicate_document(@record)
    create_new_empty_record(new_doc)
    if (m = callback_method('dup_record')) then call_callback_method(m) end
    update_standards
    @record.save!
    index
  end
end

########################################################################
# Edit action.
########################################################################
def edit
  find_record
  if (m = callback_method('before_edit') )
    ret = call_callback_method(m)
    # don't do anything if return is false
    return index if ret.class == FalseClass
  end
  @form_params['action'] = 'update'
  render action: :edit
end

########################################################################
# Update action.
########################################################################
def update
  find_record
  # check if record was not updated in mean time
  if @record.respond_to?(:updated_at)
    if params[:last_updated_at].to_i != @record.updated_at.to_i
      flash[:error] = t('drgcms.updated_by_other')
      return render(action: :edit)
    end
  end

  if dc_user_can(DcPermission::CAN_EDIT_ALL) ||
    (@record.respond_to?('created_by') && @record.created_by == session[:user_id] && dc_user_can(DcPermission::CAN_EDIT))

    if save_data
      params[:return_to] = 'index' if params[:commit] == t('drgcms.save&back') # save & back
      @form_params['action'] = 'update'
      # Process return_to
      return process_return_to(params[:return_to]) if params[:return_to]
    else
      # do not forget before_edit callback
      if m = callback_method('before_edit') then call_callback_method(m) end
      return render action: :edit
    end
  else
    flash[:error] = t('drgcms.not_authorized')
  end
  edit
end

########################################################################
# Destroy action. Used also for enabling and disabling record.
########################################################################
def destroy
  find_record
  # check permission required to delete
  permission = if params['operation'].nil?
    if @record.respond_to?('created_by') # needs can_delete_all if created_by is present and not owner
      (@record.created_by == session[:user_id]) ? DcPermission::CAN_DELETE : DcPermission::CAN_DELETE_ALL
    else
      DcPermission::CAN_DELETE    # by default
    end
  else # enable or disable record
    if @record.respond_to?('created_by')
      (@record.created_by == session[:user_id]) ? DcPermission::CAN_EDIT : DcPermission::CAN_EDIT_ALL
    else
      DcPermission::CAN_EDIT      # by default
    end
  end
  ok2delete = dc_user_can(permission)

  case
  # not authorized
  when !ok2delete then
    flash[:error] = t('drgcms.not_authorized')
    return index

  # delete document
  when params['operation'].nil? then
    # before_delete callback
    if (m = callback_method('before_delete') )
      ret = call_callback_method(m)
      # don't do anything if return is false
      return index if ret.class == FalseClass
    end

    if @record.destroy
      save_journal(:delete)
      flash[:info] = t('drgcms.record_deleted')
      # after_delete callback
      if (m = callback_method('after_delete') )
        call_callback_method(m)
      elsif params['after-delete'].to_s.match('return_to')
        params[:return_to] = params['after-delete']
      end
      # Process return_to link
      return process_return_to(params[:return_to]) if params[:return_to]
    else
      flash[:error] = dc_error_messages_for(@record)
    end
    return index
    
  # deactivate document
  when params['operation'] == 'disable' then
    if @record.respond_to?('active')
      @record.active = false
      save_journal(:update, @record.changes)
      update_standards()
      @record.save
      flash[:info] = t('drgcms.doc_disabled')
    end
    
  # reactivate document
  when params['operation'] == 'enable' then
    if @record.respond_to?('active')
      @record.active = true
      update_standards()
      save_journal(:update, @record.changes)
      @record.save
      flash[:info] = t('drgcms.doc_enabled')
    end

  #TODO reorder documents
  when params['operation'] == 'reorder' then

  end

  @form_params['action'] = 'update'
  render action: :edit
end

########################################################################
# Run action
########################################################################
def run
  # determine control file name and method
  control_name, method_name = params[:control].split('.')
  if method_name.nil?
    method_name  = control_name
    control_name = CmsHelper.table_param(params)
  end
  # extend with control methods
  extend_with_control_module(control_name)
  if respond_to?(method_name)
    # can it be called
    return return_run_error t('drgcms.not_authorized') unless can_process_run
    # call method
    respond_to do |format|
      format.json { send method_name }
      format.html { send method_name }
    end    
  else # Error message
    return_run_error "Method #{method_name} not defined in #{control_name}_control"
  end
end

protected

########################################################################
# Respond with error on run action
########################################################################
def return_run_error(text)
  respond_to do |format|
    format.json { render json: { msg_error: text } }
    format.html { render plain: text }
  end
end

########################################################################
# Can run call be processed
########################################################################
def can_process_run
  if respond_to?(:dc_can_process)
    response = send(:dc_can_process)
    return response unless response.class == Array
  else
    response = [DcPermission::CAN_VIEW, CmsHelper.table_param(params) || 'dc_memory']
  end
  dc_user_can *response
end

########################################################################
# Checks if user has permissions to perform operation on table and if not
# prepares response for not authorized message.
#
# @param [Integer] permission : Permission level defined in DcPermission constants eg. DcPermission::CAN_EDIT
# @param [String] collection_name : Table name on which user must have permission
#
# @return [Boolean] true when user has required permission otherwise false
########################################################################
def user_has_permission?(permission, collection_name)
  unless dc_user_can(permission, collection_name.to_s)
    respond_to do |format|
      format.json { render json: {msg_error: t('drgcms.not_authorized') } }
      format.html { render plain: t('drgcms.not_authorized') }
    end
    return false
  end
  true
end

############################################################################
# Load module if available. Try not to mask errors in control module
############################################################################
def load_controls_module(controls_string)
  begin
    controls_string.classify.constantize
  rescue NameError => e
    return nil if e.message.match('uninitialized constant') || e.message.match('wrong constant name')
    # report errors when loading existing module
    raise e
  end
end

############################################################################
# Dynamically extend cmsedit class with methods defined in controls module.
############################################################################
def extend_with_control_module(control_name = @form['controls'] || @form['control'])
  # May include embedded forms so ; => _
  control_name ||= CmsHelper.table_param(params).gsub(';','_')
  control_name += '_control' unless control_name.match(/control$|report$/i)
  # p '************',  control_name
  controls = load_controls_module(control_name)
  if controls
    # extend first with dc_report when report
    if control_name.match(/report$/i)
      extend DcReport
      init_report(control_name)
    end
    extend controls
    # Form may be dynamically updated before processed
    send(:dc_update_form) if respond_to?(:dc_update_form)
  end
end

############################################################################
# Check if user is authorized for the action. If authorization is in order it will also
# load DRG form.
############################################################################
def check_authorization
  params[:table] ||= params[:t] || CmsHelper.form_param(params)
  # Only show menu
  return login if params[:id].in?(%w(login logout test))

  table = params[:table].to_s.strip.downcase
  set_default_guest_user_role if session[:user_roles].nil?
  # request shouldn't pass
  if table != 'dc_memory' and 
     (table.size < 3 or !dc_user_can(DcPermission::CAN_VIEW))
    return render(action: 'error', locals: { error: t('drgcms.not_authorized')} )
  end
  dc_form_read

  # Permissions can be also defined in form
  #TODO So far only can_view is used. Think about if using other permissions has sense
  can_view = @form.dig('permissions','can_view')
  if can_view.nil? || can_view.split(',').any? { |role| dc_user_has_role(role) }
    extend_with_control_module
  else
    render(action: 'error', locals: { error: t('drgcms.not_authorized')} )
  end
end

########################################################################
# Find current record (document) for edit, update or delete.
########################################################################
def find_record #:nodoc:
  if @tables.size == 1
    @record = @tables.first[0].find(params[:id])
  else
    rec = @tables.first[0].find(@ids.first)                           # top most record
    1.upto(@tables.size - 2) { |i| rec = rec.send(@tables[i][1].pluralize).find(@ids[i]) }  # find embedded childrens by ids
    @record = rec.send(@tables.last[1].pluralize).find(params[:id])   # record to edit
  end
end

########################################################################
# Creates new empty record for new and create action.
########################################################################
def create_new_empty_record(initial_data = nil) #:nodoc:
  if @tables.size == 1
    @record = @tables.first[0].new(initial_data)
  else
    rec = @tables.first[0].find(@ids.first)             # top most record
    1.upto(@tables.size - 2) { |i| rec = rec.send(@tables[i][1].pluralize).find(@ids[i]) }  # find embedded children by ids
    @record = rec.send(@tables.last[1].pluralize).new(initial_data)   # new record
  end
end

########################################################################
# Update standard fields like updated_by, created_by, site_id
########################################################################
def update_standards(record = @record)
  record.updated_by = session[:user_id] if record.respond_to?('updated_by')
  if record.new_record?
    record.created_by = session[:user_id] if record.respond_to?('created_by')
    # set this only initialy. Allow to be set to nil on updates. Document can then belong to all sites
    # and will be directly visible only to admins
    record.dc_site_id = dc_get_site.id if record.respond_to?('dc_site_id') && record.dc_site_id.nil?
  end
  record.send(:set_history, self) if record.respond_to?(:set_history)
end

########################################################################
# Save document changes to journal table. Saves all parameters to retrieve record if needed.
# 
# [Parameters:]
# [operation] 'delete' or 'update'.
# [changes] Current document changed fields.
########################################################################
def save_journal(operation, changes = {})
  if operation == :delete
    @record.attributes.each { |k, v| changes[k] = v }
  end
  changes.except!('created_at', 'updated_at', 'created_by', 'updated_by')

  if (operation != :update) || changes.size > 0
    # determine site_id
    site_id = @record.site_id if @record && @record.respond_to?('site_id')
    site_id = dc_get_site._id if site_id.nil? && dc_get_site

    DcJournal.create(site_id: site_id,
                     operation: operation,
                     user_id: session[:user_id],
                     tables:  params[:table],
                     ids:     params[:ids],
                     doc_id:  params[:id],
                     ip:      request.remote_ip,
                     time:    Time.now,
                     diff:    changes.to_json)
  end
end

########################################################################
# Determines if callback method is defined in parameters or in control module. 
# Returns callback method name or nil if not defined.
########################################################################
def callback_method(key) #:nodoc:
  data_key = key.gsub('_', '-') # convert _ to -
  callback = case
    when params['data'] && params['data'][data_key] then params['data'][data_key]
    # dc_ + key method is present then call it automatically
    when @form.dig('permissions', key) then @form['permissions'][key]
    when respond_to?('dc_' + key) then 'dc_' + key
    when respond_to?(key) then key
    when params[data_key] then params[data_key]
    else nil
  end

  ret = case
    when callback.nil? then callback # otherwise there will be errors in next lines
    when callback.match('eval ') then callback.sub('eval ','')
    when callback.match('return_to ')
      params[:return_to] = callback.sub('return_to ','')
      return nil
    else callback
  end
  ret
end

########################################################################
# Calls callback method.
########################################################################
def call_callback_method(m) #:nodoc:
  send(m) if respond_to?(m)  
end

########################################################################
# Same as javascript_tag helper. Ajax form actions may results in javascript code to be returned.
# This will add javascript tag to code.
########################################################################
def js_tag(script) #:nodoc:
  "<script type=\"text/javascript\">#{script}</script>"
end

########################################################################
# Process return_to parameter when defined on form or set by controls methods. 
# params['return_to'] may contain 'index', 'reload' or 'parent.reload' or any valid url to
# return to, after successful controls method call.
########################################################################
def process_return_to(return_to)
  script = case
    when return_to == 'index' then return index
    when return_to.match(/eval=/i) then return_to.sub('eval=', '')
    when return_to.match(/parent\.reload/i) then 'parent.location.href=parent.location.href;'
    when return_to.match(/reload/i) then 'location.href=location.href;'
    when return_to.match(/window.close/i) then 'window.close();'
    when return_to.match(/none/i) then return
    else "location.href='#{return_to}'"
  end
  render html: js_tag(script).html_safe, layout: false
end

########################################################################
# Since tabs have been introduced on form it is a little more complicated
# to collect all edit fields on form. This method does it. Subroutine of save_data.
########################################################################
def fields_on_form #:nodoc:
  form_fields = []
  if @form['form']['fields']
    # read only field elements (key is Integer)
    @form['form']['fields'].each { |key, options| form_fields << options if key.class == Integer }
  else
    @form['form']['tabs'].keys.each do |tab|
      @form['form']['tabs'][tab].each { |key, options| form_fields << options if key.class == Integer }
    end  
  end
  form_fields
end

########################################################################
# Save edited data. Take care that only fields defined on form are affected. 
# It also saves journal data and calls before_save and after_save callbacks.
########################################################################
def save_data
  form_fields = fields_on_form()
  return true if form_fields.size == 0

  form_fields.each do |v|
    session[:form_processing] = v['name'] # for debuging
    next if v['type'].nil? || v['name'].nil? ||
            v['type'].match('embedded') || # don't wipe embedded types
            (params[:edit_only] && params[:edit_only] != v['name']) || # otherwise other fields would be wiped
            v['readonly'] || # fields with readonly option don't return value and would be wiped
            !@record.respond_to?(v['name']) # there are temporary fields on the form
    # good to know! How to get type of field @record.fields[v['name']].type
    # return value from form field definition
    value = DrgcmsFormFields.const_get(v['type'].camelize).get_data(params, v['name'])
    @record.send("#{v['name']}=", value)
  end

  # before_save callback
  if (m = callback_method('before_save') )
    ret = call_callback_method(m)
    # don't save if callback returns false
    return false if ret.class == FalseClass
  end

  # save data
  changes = @record.changes
  update_standards if changes.size > 0  # update only if there has been some changes
  if (saved = @record.save)
    operation = @record.new_record? ? :new : :update
    save_journal(operation, @record.previous_changes)
    # after_save callback
    if (m = callback_method('after_save') ) then call_callback_method(m) end
  end
  saved
end

########################################################################
# Will return comma separated data (field names) as array of symbols. For usage
# in select_fields and deny_fields
########################################################################
def separated_to_symbols(data)
  data.chomp.split(',').map { _1.strip.downcase.to_sym }
end

########################################################################
# Will process only (select_fields) and without (deny_fields) option
########################################################################
def process_select_and_deny_fields
  only = @form['result_set']['select_fields'] || @form['result_set']['only']
  @records = @records.only( separated_to_symbols(only) ) if only

  without = @form['result_set']['deny_fields'] || @form['result_set']['without']
  @records = @records.without( separated_to_symbols(without) ) if without
end

########################################################################
# Will check and set sorting options for current result set. Subroutine of index method.
########################################################################
def check_sort_options #:nodoc:
  table_name = @tables.first[1]
  return if session[table_name][:sort].nil? || @records.class != Mongoid::Criteria

  sort, direction = session[table_name][:sort].split(' ')
  @records = @records.order_by( sort => direction.to_i )
end

########################################################################
# Set aditional filter options when filter is defined by filter method in control object.
########################################################################
def user_filter_options(model) #:nodoc:
  table_name = @tables.first[1]
  if session[table_name]
    DcFilter.get_filter(session[table_name][:filter]) || model
  else
    model
  end
end

########################################################################
# Return current sort options for model (table)
########################################################################
def user_sort_options(model) #:nodoc:
  table_name = (model.class == String ? model : model.to_s).underscore
  return nil unless session[table_name][:sort]

  field, direction = session[table_name][:sort].split(' ')
  { field.to_sym => direction.to_i }
end

########################################################################
# Will check and set current filter options for result set. Subroutine of index method.
########################################################################
def check_filter_options #:nodoc:
  table_name = CmsHelper.table_param(params).strip.split(';').first.underscore
  model      = table_name.classify.constantize
  session[table_name] ||= {}
  # page is set
  session[table_name][:page] = params[:page] if params[:page]
  # if data model has field dc_site_id ensure that only documents which belong to the site are selected.
  site_id = dc_get_site._id if dc_get_site

  # don't filter site if no dc_site_id field or user is ADMIN
  site_id = nil if !model.method_defined?('dc_site_id') || dc_user_can(DcPermission::CAN_ADMIN)
  site_id = nil if session[table_name][:filter].to_s.match('dc_site_id')

  if @records = DcFilter.get_filter(session[table_name][:filter])
    @records = @records.and(dc_site_id: site_id) if site_id
  else
    @records = site_id ? model.where(dc_site_id: site_id) : model
  end
  process_select_and_deny_fields
  # pagination if required
  per_page = (@form['result_set']['per_page'] || 25).to_i
  @records = @records.page(session[table_name][:page]).per(per_page) if per_page > 0
end

########################################################################
# Process index action for normal collections.
########################################################################
def process_collections #:nodoc
  # If result_set is not defined on form, then it will fail. :return_to should know where to go
  if @form['result_set'].nil?
    process_return_to(params[:return_to] || 'reload')
    return true
  end
  # when result set is evaluated as Rails helper
  @form['result_set']['type'] ||= 'default'
  return unless @form['result_set']['type'] == 'default'

  # for now enable only filtering of top level documents
  if @tables.size == 1 
    check_filter_options()
    check_sort_options()
  end  
  # result set is defined by filter method in control object
  form_filter = @form['result_set']['filter'] || 'default_filter'
  if respond_to?(form_filter)
    @records = send(form_filter)
    # something went wrong. flash[] should have explanation.
    if @records.class == FalseClass
      @records = []
      render(action: :index)
      return true
    end
    process_select_and_deny_fields
    # pagination but only if not already set
    unless (@form['table'] == 'dc_memory' || (@records.respond_to?(:options) && @records.options[:limit]))
      per_page = (@form['result_set']['per_page'] || 25).to_i
      @records = @records.page(params[:page]).per(per_page) if per_page > 0
    end
  else
    if @tables.size > 1 
      rec = @tables.first[0].find(@ids.first)          # top most document.id
      1.upto(@tables.size - 2) { |i| rec = rec.send(@tables[i][1].pluralize).find(@ids[i]) }  # find embedded childrens by ids
      # TO DO. When field name is different then pluralized class name. Not working yet.
      embedded_field_name = @tables.last[0] ? @tables.last[1].pluralize : @tables.last[1]
      @records = rec.send(embedded_field_name)   # current embedded set
      # sort by order if order field is present in model
      if @tables.last[1].classify.constantize.respond_to?(:order)
        @records = @records.order_by(order: 1)
      end
    end
  end
  false
end

########################################################################
# Process index action for in memory data. default_filter method must fill @records array
# with data, that will be shown in browser.
########################################################################
def process_in_memory #:nodoc
  @records = []
  # result set is defined by filter method in control object
  if (method = @form['result_set']['filter'] || 'default_filter')
    send(method) if respond_to?(method)
  end
  # ensure that record has id field
  if @records.size > 0
    raise "Exception: id field must be set in dc_memory record!" unless @records.first.id
  end
  false
end

########################################################################
# Prevent double form submit
#
# There was a problem with old solution when user opened another browser session while
# entering data into new document. If in new session user added document to some other
# collection, save to document in primary session was silently ignored. Now creation time for last three forms
# is remembered. This will work unless user tries to add new document to the same collection in another session.
# But that is highly unlikely.
########################################################################
def double_form_submit?
  session[:dfs] ||= {}
  form_name = CmsHelper.form_param(params) || CmsHelper.table_param(params)
  params[:form_time_stamp] = params[:form_time_stamp].to_i
  if params[:form_time_stamp] <= update_dfs_time(form_name) && !Rails.env.test? # test must be excluded
    flash[:error] = I18n.t('drgcms.dfs')
    return true
  end
  update_dfs_time(form_name, params[:form_time_stamp])

  false
end

########################################################################
# Updates double_form_submit timings.
########################################################################
def update_dfs_time(form_name, time = nil)
  if time.nil?
    session[:dfs][form_name] ||= 0
  else
    session[:dfs][form_name] = time
    if session[:dfs].size > 3
      oldest = session[:dfs].invert.min
      session[:dfs].delete(oldest.last)
    end
  end
end

end
