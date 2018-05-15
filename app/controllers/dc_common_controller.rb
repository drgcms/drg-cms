#coding: utf-8
#--
# Copyright (c) 2012-2013 Damjan Rems
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
#  return '' unless session[:edit_mode] > 0 # 
  return render plain: t('drgcms.not_authorized') unless dc_user_can(DcPermission::CAN_VIEW)
# TODO Double check if previous line works as it should.
  table = params['table'].classify.constantize
  id = [params['id']] || '_id'
# call method in class if search parameter has . This is for user defined searches
# result must be returned as array of [id, search_field_value]
  a = if params['search'].match(/\./)
    name, method = params['search'].split('.')
    table.send(method, params['input']).inject([]) do |r,v|
      r << { label: v[0], value: v[0], id: v[1].to_s }
    end
# simply search which will search and return field_name defined in params['search']
  else
    table.where(params['search'] => /#{params['input']}/i).limit(20).inject([]) do |r,v|
      r << { label: v[params['search']], value: v[params['search']], id: v.id.to_s }
    end
  end

  render inline: a.to_json, formats: 'js'
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
# called without logged in  
  if session[:edit_mode] < 1 
    dc_render_404 
  else
    session[:edit_mode] = (session[:edit_mode] == 1) ? 2 : 1
    redirect_to params[:return_to]
  end
end

####################################################################
# Default user login action.
####################################################################
def process_login
# Somebody is probably playing
  return dc_render_404 unless ( params[:record] and params[:record][:username] and params[:record][:password] )

  unless params[:record][:password].blank? #password must not be empty
    user  = DcUser.find_by(username: params[:record][:username])
    if user and user.authenticate(params[:record][:password])
      fill_login_data(user, params[:record][:remember_me].to_i == 1)
      return redirect_to params[:return_to] ||  '/'
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
    if user
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
    return render inline: { 'msg_info' => (t ('drgcms.not_authorized')) }.to_json, formats: 'js'
  end
# selected fields to hash  
  restore = {} 
  params[:select].each {|key,value| restore[key] = value if value == '1' }
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
  render inline: result.to_json, formats: 'js'  
end

########################################################################
# Copy current record to clipboard as json text. It will actually ouput an 
# window with data formatted as json.
########################################################################
def copy_clipboard
# Only administrators can perform this operation  
  return render(plain: t('drgcms.not_authorized') )  unless dc_user_has_role('admin')
#  
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
  return render(plain: t('drgcms.not_authorized') ) unless dc_user_has_role('admin')
  
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

protected

########################################################################
# Update some anomalies in json data on paste_clipboard action.
########################################################################
def update_json(json, is_update=false) #:nodoc:
  result = {}
  json.each do |k,v|
    if v.class == Hash
      result[k] = v['$oid'] unless is_update
#TODO Double check if unless works as expected
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
  msg = dc_check_model(doc)
  msg ? " ERROR! #{msg}" : " NEW. OK." 
end

####################################################################
# Clears all session data related to login. 
####################################################################
def clear_login_data
  session[:edit_mode]   = 0
  session[:user_id]     = nil
  session[:user_name]   = nil
  session[:user_roles]  = nil
  cookies.delete :remember_me
end

####################################################################
# Fills session with data related to successful login.
####################################################################
def fill_login_data(user, remember_me)
  session[:user_id]    = user.id
  session[:user_name]  = user.name
  session[:edit_mode]  = 0 
  session[:user_roles] = []
  
# special for SUPERADMIN
  sa = DcPolicyRole.find_by(system_name: 'superadmin')
  if sa and (role = user.dc_user_roles.find_by(dc_policy_role_id: sa.id))
    session[:user_roles] << role.dc_policy_role_id
    session[:edit_mode]  = 2
    return
  end
# Every user has guest role
  guest = DcPolicyRole.find_by(system_name: 'guest')
  session[:user_roles] << guest.id if guest
# read default policy from site  
  default_policy = dc_get_site().dc_policies.find_by(is_default: true)
# load user roles      
  user.dc_user_roles.each do |role|
    next unless role.active
    next if role.valid_from and role.valid_from > Time.now.end_of_day.to_date
    next if role.valid_to   and role.valid_to < Time.now.to_date
# check if role is active in this site
    policy_role = default_policy.dc_policy_rules.find_by(dc_policy_role_id: role.dc_policy_role_id)
    next unless policy_role
# set edit_mode      
    session[:edit_mode] = 1 if policy_role.permission > 1
    session[:user_roles] << role.dc_policy_role_id
  end
# Save remember me cookie if not CMS user and remember me is selected
  if session[:edit_mode] == 0 and remember_me
    cookies.signed[:remember_me] = { :value => user.id, :expires => 180.days.from_now}
  end
end

end
