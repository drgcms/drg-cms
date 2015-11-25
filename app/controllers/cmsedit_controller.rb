#coding: utf-8
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
# Controls (among other) may contain 6 fixed callback methods.
# These methods are:
# * dc_new_record
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
#        flash[:error] = 'You can not perform this operation!'
#        nil
#      end
#    end
#      
# If filter method returns false user will be presented with flash error.
########################################################################
class CmseditController < DcApplicationController
before_action :check_authorization, :except => [:login, :logout]
before_filter :dc_reload_patches if Rails.env.development?
  
layout 'cms'

########################################################################
# Will check and set sorting options for current result set. Subroutine of index method.
########################################################################
def check_sort_options() #:nodoc:
  table_name = @tables.first[1]
  old_sort = session[table_name][:sort].to_s
  sort, direction = old_sort.split(' ')
# sort is requested
  if params['sort']
    # reverse sort if same selected
    if params['sort'] == sort
      direction = (direction == '1') ? '-1' : '1'
    end
    direction ||= 1
    sort = params[:sort]
    session[table_name][:sort] = "#{params['sort']} #{direction}"
    session[table_name][:page] = 1
  end
  @records.sort( sort => direction.to_i ) if session[table_name][:sort]
  params['sort'] = nil # otherwise there is problem with other links
end

########################################################################
# Set aditional filter options when filter is defined by filter method in control object.
########################################################################
def user_filter_options(model) #:nodoc:
# no filter is active or set off
  if params[:filter] == 'off' or (params[:filter].nil? and session[:tmp_filter].nil?)
    session[:tmp_filter] = nil
    return model
  end
# 
  table, field, oper, value = if params[:filter] == 'on' 
    [model.to_s, params[:filter_field], params[:filter_oper], params[:record][params[:filter_field]] ]
  else
    session[:tmp_filter].split("\t")
  end
# filter set previously on other collection
  if table != model.to_s
    session[:tmp_filter] = nil
    return model 
  end
#
  field = '_id' if field == 'id' # must be
  value = /#{value}/ if oper == 'like' # do regex if operation is like
# when field type is ObjectId transform value    
  if model.fields[field] and model.fields[field].type == BSON::ObjectId
    value = BSON::ObjectId.from_string(value) rescue nil
    flash[:error] = t('drgcms.not_id') if value.nil?
  end
# save filter to session  
  session[:tmp_filter] = [ table, field, oper, value ].join("\t")
  model.where(field => value)
end

########################################################################
# Will check and set current filter options for result set. Subroutine of index method.
########################################################################
def check_filter_options() #:nodoc:
  table_name = @tables.first[1]
  model      = @tables.first[0]
  session[table_name] ||= {}
# process page
  session[table_name][:page] = params[:page] if params[:page]
# new filter is applied
  if params[:filter]
    session[table_name][:filter] =
    if params[:filter] == 'off' # clear all values
      nil
    else
#      [ params[:filter_field], params[:filter_oper], params[:record][params[:filter_field]] ].join("\t")
      {'field' =>  params[:filter_field], 
       'operation' => params[:filter_oper], 
       'value' => params[:record][params[:filter_field]],
       'table' => table_name}.to_yaml
    end
    session[table_name][:page] = 1
    params[:filter]    = nil # must be. Otherwise kaminari includes parameter on paging and everything goes wrong
    params[:filter_id] = nil 
  end
# if data model has field dc_site_id ensure that only documents which belong to the site are selected.
  site_id = dc_get_site._id if dc_get_site
# dont't filter site if no dc_site_id field or user is ADMIN
  site_id = nil if !model.method_defined?('dc_site_id') or dc_user_can(DcPermission::CAN_ADMIN)
#  
  if @records = DcFilter.get_filter(session[table_name][:filter])
    @records = @records.and(dc_site_id: site_id) if site_id
  else
    @records = if site_id
      model.where(dc_site_id: site_id)
    else
      model
    end
  end
  
=begin      
  if session[table_name][:filter]

    field, oper, value = session[table_name][:filter].split( "\t")
    field = '_id' if field == 'id' # must be
    value = /#{value}/i if oper == 'like' # do regex if operation is like
# when field type is ObjectId transform value    
    if model.fields[field] and model.fields[field].type == BSON::ObjectId
      value = BSON::ObjectId.from_string(value) rescue nil
      flash[:error] = t('drgcms.not_id') if value.nil?
    end
    @records =  if site_id
      model.where(dc_site_id: site_id, field => value)
    else
      model.where(field => value)
    end

    filter = DcFilter.get_filter(session[table_name][:filter])
  else
     = if site_id
      model.where(dc_site_id: site_id)
    else
      model
    end
  end
=end  
# pagination if required
  per_page = (@form['result_set']['per_page'] || 30).to_i
  if per_page > 0
    @records = @records.page(session[table_name][:page]).per(per_page)
  end
end

########################################################################
# Index action.
########################################################################
def index
# If result_set is not defined on form, then it will fail. :return_to should know where to go
  if @form['result_set'].nil?
    return process_return_to(params[:return_to] || 'reload') 
  end
# result set is defined by filter method in control object
  if @form['result_set']['filter']
    if respond_to?(@form['result_set']['filter'])
      @records = send @form['result_set']['filter']
# something iz wrong. flash[] should have explanation.
      if @records.class == FalseClass
        @records = []
        return render(action: :index)
      end
# pagination
      unless @form['table'] == 'dc_dummy'
        per_page = (@form['result_set']['per_page'] || 30).to_i
        @records = @records.page(params[:page]).per(per_page) if per_page > 0
      end
    else
      p "Error: result_set:filter: #{@form['result_set']['filter']} not found in controls!"
    end
  else
    if @tables.size == 1 # for now enable only filtering of main tables
      check_filter_options()
      check_sort_options()
    else
      rec = @tables.first[0].find(@ids.first)          # top most document.id
      1.upto(@tables.size - 2) { |i| rec = rec.send(@tables[i][1].pluralize).find(@ids[i]) }  # find embedded childrens by ids
#      p rec,@tables, @tables.last[1].pluralize
      @records = rec.send(@tables.last[1].pluralize)   # current embedded set
# sort by order if order field is present in model
      if @tables.last[1].classify.constantize.respond_to?(:order)
        @records = @records.order_by('order asc')
      end
    end
  end
#
  respond_to do |format|
    format.html { render action:  :index }
    format.js   { render partial: :result }
  end
end

########################################################################
# Filter action. 
########################################################################
def filter
  index
end

########################################################################
# Show displays record in readonly mode.
########################################################################
def show
  find_record
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
  session[:edit_mode] = 0 unless params[:ok]
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
# New action.
########################################################################
def new
  if (m = callback_method('before_new') )
    ret = call_callback_method(m)
# Don't do anything if return is false
    return index if ret.class == FalseClass
  end  
# clear flash messages.
  flash[:error] = flash[:warning] = flash[:info] = nil 
  create_new_empty_record
  table = @tables.last[1] + '.'
# initial values set on page
  if cookies[:record] and cookies[:record].size > 0
    Marshal.load(cookies[:record]).each do |k,v|
      k = k.to_s
      if k.match(table)
        field = k.split('.').last
        @record.send("#{field}=", v) if @record.respond_to?(field)
      end
    end
  end
# initial values set in url
  params.each do |k,v|
    if k.match(table)
      field = k.split('.').last
      @record.send("#{field}=", v) if @record.respond_to?(field)
    end
  end
# This is how we set default values for new record
  dc_new_record() if respond_to?('dc_new_record') 
  @parms['action'] = 'create'
end

########################################################################
# Duplicate embedded document. Since embedded documents are returned differently 
# then top level document. Subroutine of duplicate_socument.
########################################################################
def duplicate_embedded(source) #:nodoc:
# TODO Works for two embedded levels. Dies with third and more levels.
  dest = {}
  source.each do |attribute_name, value|
    next if attribute_name == '_id' # don't duplicate _id
    if value.class == Array
      dest[attribute_name] = []
      value.each do |ar|
        dest[attribute_name] << duplicate_embedded(ar)
      end
    else      
# if duplicate string must be added. Useful for unique attributes
      add_duplicate = params['dup_fields'].to_s.match(attribute_name + ',')
      dest[attribute_name] = value
      dest[attribute_name] << ' dup' if add_duplicate
    end
  end
  dest
end

########################################################################
# Will create duplicate document of source document. This method is used for 
# duplicating document and is called from create action.
########################################################################
def duplicate_document(source)
  dest = {}
  source.attribute_names.each do |attribute_name|
    next if attribute_name == '_id' # don't duplicate _id
# if duplicate, string must be added. Useful for unique attributes
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
  dest
end

########################################################################
# Create (or duplicate) action. Action is also used for turning filter on.
########################################################################
def create
# abusing create for turning filter on
  return index if params[:filter].to_s == 'on'
# not authorized
  unless dc_user_can(DcPermission::CAN_CREATE)
    flash[:error] = t('drgcms.not_authorized')
    return index
  end
#
  if params['id'].nil? # create record
    create_new_empty_record
    params[:return_to] = 'index' if params[:commit] == t('drgcms.save&back') # save & back
    if save_data
      @parms['action'] = 'update'
      @parms['id'] = @record.id     # must be set, for proper update link
      flash[:info] = t('drgcms.doc_saved')
      return process_return_to(params[:return_to]) if params[:return_to]
      render action: :edit
    else
      render action: :new
    end
  else # duplicate record
    find_record
    params['dup_fields'] += ',' if params['dup_fields'] # for easier field matching
    new_doc = duplicate_document(@record)
    create_new_empty_record(new_doc)
    update_standards()
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
# Don't do anything if return is false
    return index if ret.class == FalseClass
  end  
  @parms['action'] = 'update'
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
#   
  if dc_user_can(DcPermission::CAN_EDIT_ALL) or
    ( @record.respond_to?('created_by') and
      @record.created_by == session[:user_id] and
      dc_user_can(DcPermission::CAN_EDIT) )
#
    if save_data
      params[:return_to] = 'index' if params[:commit] == t('drgcms.save&back') # save & back
      @parms['action'] = 'update'
# Process return_to link
      return process_return_to(params[:return_to]) if params[:return_to]      
    end
  else
    flash[:error] = t('drgcms.not_authorized')
  end
  render action: :edit
end

########################################################################
# Destroy action. Used also for enabling and disabling record.
########################################################################
def destroy
  find_record
# Which permission is required to delete 
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
#
  case
# not authorized    
  when !ok2delete then
    flash[:error] = t('drgcms.not_authorized')
    return index
  when params['operation'].nil? then
# Process before delete callback
    if (m = callback_method('before_delete') )
      ret = call_callback_method(m)
# Don't do anything if return is false
      return index if ret.class == FalseClass
    end
# document deleted
    if @record.destroy
      save_journal(:delete)
      flash[:info] = t('drgcms.record_deleted')
# Process after delete callback
      if (m = callback_method('after_delete') ) then call_callback_method(m) end
# Process return_to link
      return process_return_to(params[:return_to]) if params[:return_to]
    else
      flash[:error] = dc_error_messages_for(@record)
    end
    return index
# deaktivate document    
  when params['operation'] == 'disable' then
    if @record.respond_to?('active')
      @record.active = false
      save_journal(:update, @record.changes)
      update_standards()
      @record.save
      flash[:info] = t('drgcms.doc_disabled')
    end
# reaktivate document
  when params['operation'] == 'enable' then
    if @record.respond_to?('active')
      @record.active = true
      update_standards()
      save_journal(:update, @record.changes)
      @record.save
      flash[:info] = t('drgcms.doc_enabled')
    end
  end
#
  @parms['action'] = 'update'
  render action: :edit
end

protected

=begin
########################################################################
# Processes on_save_ok form directive. Data is saved to session for
# safety reasons.
########################################################################
def process_on_save_ok
  session[:on_save_ok_id]     = @record_id
  session[:on_save_ok_commit] = params[:commit]
  eval(params[:on_save_ok])
end
=end

########################################################################
# Merges two forms when current form extends other form. Subroutine of read_drg_cms_form.
# With a little help of https://www.ruby-forum.com/topic/142809 
########################################################################
def forms_merge(hash1, hash2) 
  target = hash1.dup
  hash2.keys.each do |key|
    if hash2[key].is_a? Hash and hash1[key].is_a? Hash
      target[key] = forms_merge(hash1[key], hash2[key])
      next
    end
    target[key] = hash2[key] == '/' ? nil :  hash2[key]
  end
# delete keys with nil value  
  target.delete_if{ |k,v| v.nil? }
end

########################################################################
# Read drgcms form into yaml object. Subroutine of check_authorization.
########################################################################
def read_drg_cms_form
  table_name = decamelize_type(params[:table].strip)
  @tables = table_name.split(';').inject([]) { |r,v| r << [v.classify.constantize, v] }
# split ids passed when embedded document
  ids = params[:ids].to_s.strip.downcase
  @ids = ids.split(';').inject([]) { |r,v| r << v }
# formname defaults to last table specified
  formname = params[:formname] || @tables.last[1]
  @form  = YAML.load_file( dc_find_form_file(formname) )
# when form extends another form file. 
  if @form['extend']
    form = YAML.load_file( dc_find_form_file(@form['extend']) )
    @form = forms_merge(form, @form)
  end
# add readonly key to form if readonly parameter is passed in url
  @form['readonly'] = 1 if params['readonly'] #and %w(1 yes true).include?(params['readonly'].to_s.downcase.strip)
# !!!!!! Always use strings for key names since @parms['table'] != @parms[:table]
  @parms = { 'table' => table_name, 'ids' => params[:ids], 'formname' => formname,
             'return_to' => params['return_to'], 'edit_only' => params['edit_only'],
             'readonly' => params['readonly'] 
           }
end

############################################################################
# Check if user is authorized for the action. If authorization is in order it will also
# load DRG form.
############################################################################
def check_authorization
  params[:table] ||= params[:formname]
# Just show menu
#  return show if params[:action] == 'show'
  return login if params[:id].in?(%w(login logout))
# request shouldn't pass
  if session[:user_roles].nil? or params[:table].to_s.strip.downcase.size < 3 or 
     !dc_user_can(DcPermission::CAN_VIEW)
    return render(action: 'error', locals: { error: t('drgcms.not_authorized')} )
  end

  read_drg_cms_form
# Permissions can be also defined on form
#TODO So far only can_view is used. Think about if using other permissions has sense
  if @form['permissions'].nil? or @form['permissions']['can_view'].nil? or
    dc_user_has_role(@form['permissions']['can_view'])
# Extend class with methods defined in drgcms_controls module. May include embedded forms therefor ; => _ 
    controls_string = (@form['controls'] ? @form['controls'] : params[:table].gsub(';','_')) + '_control'
    controls = "DrgcmsControls::#{controls_string.classify}".constantize rescue nil
    extend controls if controls 
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
def create_new_empty_record(initial_data=nil) #:nodoc:
  if @tables.size == 1
    @record = @tables.first[0].new(initial_data)
  else
    rec = @tables.first[0].find(@ids.first)             # top most record
    1.upto(@tables.size - 2) { |i| rec = rec.send(@tables[i][1].pluralize).find(@ids[i]) }  # find embedded childrens by ids
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
# set this only initialy. Allow to be set to nil on updates. This documents can then belong to all sites
# and will be directly visible only to admins
    record.dc_site_id = dc_get_site._id if record.respond_to?('dc_site_id') and record.dc_site_id.nil?
  end
end

########################################################################
# Since tabs have been introduced on form it is a little more complicated
# to get all edit fields on form. This method does it. Subroutine of save_data.
########################################################################
def fields_on_form() #:nodoc:
  fields = []
  if @form['form']['fields']
# second element of array is hash. Get only hash element
    @form['form']['fields'].each {|field| fields << field[1]}
  else
    @form['form']['tabs'].keys.each do |key|
      @form['form']['tabs'][key].each {|field| fields << field[1]}
    end  
  end
  fields
end

########################################################################
# Save document changes to journal table. Saves all parameters to retrieve record if needed.
# 
# [Parameters:]
# [operation] 'delete' or 'update'.
# [changes] Current document changed fields.
########################################################################
def save_journal(operation, changes = {})
#  return unless session[:save_journal]
  if operation == :delete
    @record.attributes.each {|k,v| changes[k] = v}
#  elsif operation == :new
#    changes = {}
  end
#
  if (operation != :update) or changes.size > 0
# determine site_id
    site_id = @record.site_id if @record.respond_to?('site_id')
    site_id = dc_get_site._id if site_id.nil? and dc_get_site
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
  data_key = key.gsub('_','-') # data fields translate _ to -
  cb = case
    when params['data'] && params['data'][data_key] then params['data'][data_key]
# if dc_ + key method is present in model then it will be called automatically     
    when respond_to?('dc_' + key) then 'dc_' + key
    when params[key] then params[key]
    else nil
  end
#  
  ret = case
    when cb.nil? then cb # otherwise there will be errors in next lines
    when cb.match('eval ') then cb.sub('eval ','')
    when cb.match('return_to ')
      params[:return_to] = cb.sub('return_to ','')
      return nil
    else cb
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
    when return_to.match(/parent\.reload/i) then 'parent.location.href=parent.location.href;'
    when return_to.match(/reload/i) then 'location.href=location.href;'
    else "location.href='#{return_to}'"
  end
  render text: js_tag(script)
end

########################################################################
# Save edited data. Take care that only fields defined on form are affected. 
# It also saves journal data and calls before_save and after_save callbacks.
########################################################################
def save_data
  fields = fields_on_form()
  return true unless fields.size > 0
#
  fields.each do |v|
    next if v['type'].match('embedded') # don't wipe embedded fields
    next if params[:edit_only] and params[:edit_only] != v['name'] # otherwise other fields would be wiped
    next unless @record.respond_to?(v['name']) # there can be temporary fields on the form
    next if v['readonly'] # fields with readonly option don't retain value and would be wiped
# return value from form field definition
    value = DrgcmsFormFields.const_get(v['type'].camelize).get_data(params, v['name'])
    @record.send("#{v['name']}=", value)
  end
# 
  operation = @record.new_record? ? :new : :update
# controls callback method
  if (m = callback_method('before_save') )
    ret = call_callback_method(m)
# dont's save if callback method returns false    
    return false if ret.class == FalseClass
  end
# maybe model has dc_before_save method defined. Call it. This was before callback
  @record.dc_before_save(self) if @record.respond_to?('dc_before_save')
#
  changes = @record.changes
  update_standards() if changes.size > 0  # update only if there has been some changes
  if (saved = @record.save)
    save_journal(operation, changes)
# callback methods
    if (m = callback_method('after_save') ) then call_callback_method(m)  end
# check if model has dc_after_save method
    @record.dc_after_save(self) if @record.respond_to?('dc_after_save')
  end
  saved
end
  
end
