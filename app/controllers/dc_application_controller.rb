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

##########################################################################
# DcApplicationControllerController holds methods which are useful for all 
# application controllers.
##########################################################################
class DcApplicationController < ActionController::Base
protect_from_forgery with: :null_session, only: Proc.new { |c| c.request.format.json? }
before_action :dc_set_locale

########################################################################
# Writes anything passed as parameter to logger file. 
# Very useful for debuging strange errors.
# 
# @param [Objects] args any parameter can be passed 
########################################################################
def dc_dump(*args)
  args.each do |arg|
    logger.debug arg.to_s
  end
end
  
####################################################################
# Return true if CMS is in edit mode
# 
# @return [Boolean] True if user CMS edit mode is selected
####################################################################
def dc_edit_mode?
  session[:edit_mode] > 1
end

####################################################################
# Checks if user has required role.
# 
# @param [DcPolicyRole or String] role can be passed as DcPolicyRole object or
# as role name. If passed as name, dc_policy_roles is searched for appropriate role.
#
# @return [Boolean] True if user has required role added to his profile.
# 
# @example If user has required role
#    if dc_user_has_role('admin') ...
#    if dc_user_has_role('Site editors') ...
####################################################################
def dc_user_has_role(role)
  role = DcPolicyRole.get_role(role)
  return false if role.nil? || session[:user_roles].nil?
  # role exists in user_roles
  session[:user_roles].include?(role._id)
end

####################################################################
# Determines site from url and returns site document. 
# 
# @return [DcSite] site document. If site is not found and not in production environment,
# 'test' document is returned. If site has alias set then alias site document is
# returned.
# 
# @example Returns Google analytics code from site settings
#    settings = dc_get_site.params['ga_acc']
####################################################################
def dc_get_site
  return @site if @site

  uri  = URI.parse(request.url)
  cache_key = ['dc_site', uri.host]

  @site = DrgCms.cache_read(cache_key)
  return @site if @site

  @site = DcSite.find_by(name: uri.host)
  # Site can be aliased
  if @site&.alias_for.present?
    @site = DcSite.find_by(name: @site.alias_for)
  end
  # Development environment. Check if site with name test exists and use
  # alias_for as pointer to real site.
  if @site.nil? && ENV["RAILS_ENV"] != 'production'
    @site = DcSite.find_by(name: 'test')
    @site = DcSite.find_by(name: @site.alias_for) if @site
  end
  @site = nil if @site && !@site.active # site is disabled
  DrgCms.cache_write(cache_key, @site)
end

##########################################################################
# Will set page title according to data on dc_page or dc_site
#
# Sets internal @page_title variable.
##########################################################################
def set_page_title
  @page_title = @page.title.blank? ? @page.subject : @page.title
  dc_add_meta_tag(:name, 'description', @page.meta_description)
end

#######################################################################
# Will render public/404.html file with some debug code includded.
# 
# @param [Object] Object where_the_error_is. Additional data can be displayed with error.
# 
# @example Render error 
#   site = dc_get_site()
#   return dc_render_404('Site') unless site
########################################################################
def dc_render_404(where_the_error_is=nil)
  logger.info("Error 404;#{request.env['REQUEST_URI'] rescue ''};#{request.referer};#{where_the_error_is}")
  render(file: Rails.root.join('public/404.html'), status: 404)
end

########################################################################
# Will write document to dc_visits collection unless visit comes from robot. 
# It also sets session[is_robot] variable to true if robot.
########################################################################
def dc_log_visit
  if request.env["HTTP_USER_AGENT"] and request.env["HTTP_USER_AGENT"].match(/\(.*https?:\/\/.*\)/)
    logger.info "ROBOT: #{Time.now.strftime('%Y.%m.%d %H:%M:%S')} id=#{@page.id} ip=#{request.remote_ip}."
    session[:is_robot] = true
  else
    DcVisit.create(site_id: @site.id, 
                   user_id: session[:user_id], 
                   page_id: @page.id, 
                   ip: request.remote_ip,
                   session_id: request.session_options[:id],
                   time: Time.now )
  end
end

protected

###########################################################################
# Checks if user can perform (read, create, edit, delete) document in specified
# table (collection).
# 
# @param [Integer] permission: Required permission level
# @param [String] table: Collection (table) name for which permission is queried. Defaults to params[table].
# 
# @return [Boolean] true if user's role permits (is higher or equal then required) operation on a table (collection). 
# 
# @Example True when user has view permission on the table
#   if dc_user_can(DcPermission::CAN_VIEW, params[:table]) then ...
############################################################################
def dc_user_can(permission, table = params[:table])
  return false if session[:user_roles].nil?

  table = table.underscore
  permissions = DrgCms.cache_read(['dc_permission', table, dc_get_site.id]) { DcPermission.permissions_for_table(table) }
  session[:user_roles].inject(false) { |r, rule| break true if permissions[rule] && permissions[rule] >= permission }
end

####################################################################
# Read from cache
#
# @keys [Array] Array of keys
#
# @return [Object] Data returned from cache
####################################################################
def dc_cache_read(keys)
  if redis_cache_store?
    keys  = keys.dup
    first = keys.shift
    data  = redis.hget(first, keys.join(''))
    data ? Marshal.load(data) : nil
  else
    Rails.cache.read(keys.join(''))
  end
end

####################################################################
# Write data to cache
#
# @param [Array] keys: Array of keys
# @param [Object] data: Data written to cache
#
# @return [Object] data so dc_cache_write can be used as last statement in method.
####################################################################
def dc_cache_write(keys, data)
  if redis_cache_store?
    keys  = keys.dup
    first = keys.shift
    redis.hset(first, keys.join(''), Marshal.dump(data))
  else
    Rails.cache.write(keys.join(''), data)
  end
  data
end

####################################################################
# Detects if called from mobile agent according to http://detectmobilebrowsers.com/
# and set session[:is_mobile]
#
# Detect also if caller is a robot and set session[:is_robot]
####################################################################
def dc_set_is_mobile
  is_mobile = request.user_agent ? /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.match(request.user_agent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.match(request.user_agent[0..3])
                                 : false
  session[:is_mobile] = is_mobile ? 1 : 0

  if request.env["HTTP_USER_AGENT "] && request.env["HTTP_USER_AGENT"].match(/\(.*https?:\/\/.*\)/)
    logger.info "ROBOT: #{Time.now.strftime('%Y.%m.%d %H:%M:%S')} id=#{@page.id} ip=#{request.remote_ip}."
    session[:is_robot] = true
  end
end

##########################################################################
# Merge values from parameters fields (from site, page ...) into internal @options hash.
# 
# @param [String] parameters: passed as YAML string.
##########################################################################
def dc_set_options(parameters)
  @options ||= {}
  return if parameters.to_s.size < 3
  # parameters are set as YAML. This should be default in future.
  parms = YAML.load(parameters) rescue {}
  @options = @options.deep_merge(parms)
end

##########################################################################
# Check if document(s) has been modified since last visit. It turned out that caching
# is not that simple and that there are multiple caching scenarios that can be used.
# So this code is here just for a example, how documents can be checked for changed status.
# 
# @param [Documents] List of documents which are checked against last visit date
# 
# @return [Boolean] true when none of documents is changed.
##########################################################################
def dc_not_modified?(*documents)
  return false unless request.env.include? 'HTTP_IF_MODIFIED_SINCE'

  since_date = Time.parse request.env['HTTP_IF_MODIFIED_SINCE']
  last_modified = since_date
  documents.each do |doc|
    next unless doc.respond_to?(:updated_at)
    last_modified = doc.updated_at if doc.updated_at > last_modified
  end

  if last_modified >= since_date then
    render :nothing => true, :status => 304
    return true
  end
  false
end

##########################################################################
# Will determine design content or view filename which defines design.
# 
# Returns:
#  design_body: design body as defined in site or design document.
#  design_view: view file name which will be used for rendering design
##########################################################################
def get_design_and_render(design_doc)
  layout      = @site.site_layout.blank? ? 'content' : @site.site_layout
  site_top    = '<%= dc_page_top %>'
  site_bottom = '<%= dc_page_bottom %>'
  # lets try the rails way
 if @options[:control] && @options[:action]
    controller = "#{@options[:control]}_control".classify.constantize rescue nil
    extend controller if controller
    return send @options[:action] if respond_to?(@options[:action])
  end
  # design doc present
  if design_doc
    # defined as rails view
    design = if design_doc.rails_view.blank? || design_doc.rails_view == 'site'
      @site.rails_view
    else
      design_doc.rails_view
    end
    return render design, layout: layout unless design.blank?
    # defined as inline code
    design = design_doc.body.blank? ? @site.design : design_doc.body
    design = site_top + design + site_bottom
    return render(inline: design, layout: layout) unless design.blank?
  end
  # Design doc not defined
  if @site.rails_view.blank?
    design = site_top + @site.design + site_bottom
    render(inline: design, layout: layout)
  else
    render @site.rails_view, layout: layout
  end  
end

##########################################################################
# This is default page process action. It will search for site, page and
# design documents, collect parameters from different objects, add CMS edit code if allowed
# and at the end render design.body or design.rails_view or site.rails_view.
# 
# @example as defined in routes.rb
#   get '*path' => 'dc_application_controller#dc_process_default_request'
#   # or
#   get '*path' => 'my_controller#page'
#   # then in my_controller.rb
#   def page
#     dc_process_default_request
#   end
##########################################################################
def dc_process_default_request
  session[:edit_mode] ||= 0
  # Initialize parts
  @parts    = nil
  @js, @css = '', ''
  # find domain name in sites
  @site = dc_get_site
  # site not defined. render 404 error
  return dc_render_404('Site!') if @site.nil?

  dc_set_options(@site.settings)
  # HOMEPAGE. When no parameters is set
  params[:path]   = @site.homepage_link if params[:id].nil? and params[:path].nil?
  @options[:path] = params[:path].to_s.downcase.split('/')
  params[:path]   = @options[:path].first if @options[:path].size > 1
  # some other process request. It should fail if not defined
  return send(@site.request_processor) unless @site.request_processor.blank?

  # Search for page
  pageclass = @site.page_klass
  if params[:id]
    #Page.where(id: params[:id]).or(subject_link: params[:id]).first    
    @page = pageclass.find_by(:dc_site_id.in => [@site._id, nil], subject_link: params[:id], active: true)
    @page = pageclass.find(params[:id]) if @page.nil? # I think that there will be more subject_link searchers than id
  elsif params[:path]
    # path may point direct to page's subject_link
    @page = pageclass.find_by(:dc_site_id.in => [@site._id, nil], subject_link: params[:path], active: true)
    if @page.nil?
      # no. Find if defined in links
      link = DcLink.find_by(:dc_site_id.in => [@site._id, nil], name: params[:path])
      if link
        #pageclass.find_by(alt_link: params[:path])   
        dc_set_options link.params
        @page = pageclass.find(link.page_id)   
      end
    end
  end
  # if @page is not found render 404 error
  return dc_render_404('Page!') unless @page

  dc_set_is_mobile unless session[:is_mobile] # do it only once per session
  # find design if defined. Otherwise design MUST be declared in site
  if @page.dc_design_id
    @design = DcDesign.find(@page.dc_design_id)
    return dc_render_404('Design!') unless @design
  end
  dc_set_options @design.params if @design
  dc_set_options @page.params
  dc_add_json_ld(@page.get_json_ld)
  # Add edit menu
  if session[:edit_mode] > 0
    session[:site_id]         = @site.id
    session[:site_page_class] = @site.page_class
    session[:page_id]         = @page.id
  else
    # Log only visits from non-editors
    dc_log_visit()
  end
  set_page_title()
  get_design_and_render @design
end

###########################################################################
# Single site document kind of request handler.
# 
# This request handler assumes that all data for the site is saved in the site document. 
# 
# Page data is saved in dc_parts documents embedded into site document.
# Menus are created from description fields. 
# Menu links are created from link fields.
# 
# This kind of page may be good candidate for caching.
# # Just a reminder: request.session_options[:skip] = true
##########################################################################
def dc_single_sitedoc_request
  if @site.nil?
    session[:edit_mode] ||= 0
    @site = dc_get_site
    # @site is not defined. render 404 error
    return dc_render_404('Site!') unless @site

    dc_set_options(@site.settings)
  end
  # HOMEPAGE. When no parameters is set
  params[:path] = @site.homepage_link if params[:path].nil?  
  @parts = @site.dc_parts
  @part  = @parts.find_by(link: params[:path])
  return dc_render_404('Part!') unless @part

  @page_title = "#{@site.page_title} #{@part.name}"
  @js, @css = '', ''
  get_design_and_render nil
end

########################################################################
# Decamelizes string. Does oposite of camelize method. It probably doesn't work 
# very good with non ascii chars. Since this method is used for converting from model
# to collection names it is very unwise to use non ascii chars for table (collection) names.
# 
# @param [Object] model_string to be converted
#
# @example
#   decamelize_type(ModelName) # 'ModelName' => 'model_name'
########################################################################
def decamelize_type(model_string)
  model_string ? model_string.to_s.underscore : nil
end

####################################################################
# Return's error messages for the document formated for display on edit form.
# 
# @param [Document] document object which will be examined for errors.
#
# @return [String] HTML code for displaying error on edit form.
####################################################################
def dc_error_messages_for(document)
  return '' unless document.errors.any?

  msg = ''
  document.errors.each do |error|
    label = t("helpers.label.#{decamelize_type(document.class)}.#{error.attribute}")
    label = error.attribute if label.match(/translation missing/i)
    msg << "<li>#{label} : #{error.message}</li>"
  end

  %(
<div class="dc-form-error"> 
  <h2>#{t('drgcms.errors_no')} #{document.errors.size}</h2>  
  <ul>#{msg}</ul>  
</div>).html_safe
end

####################################################################
# Checks if any errors exist on document and writes error log. It can also 
# crash if requested. This is mostly usefull in development for debuging 
# model errors or when saving to multiple collections and where each save must be 
# checked if succesfull.
# 
# @param [Document] document: Document object to be checked
# @param [Boolean] crash: If true method should end in runtime error. Default = false.
# 
# @return [String] Error messages or empty string if everything is OK.
# 
# @Example Check for error when data is saved.
#   model.save
#   if (msg = dc_check_model(model) ).size > 0
#     p msg
#     error process ......
#   end
#      
####################################################################
def dc_check_model(document, crash = false)
  DrgCms.model_check(document, crash)
end

######################################################################
# Call rake task from controller.
# 
# @param [String] task: Rake task name
# @param [Hash] options: Options that will be send to task as environment variables
#
# @example Call rake task from application
#   dc_call_rake('clear:all', some_parm: some_id)
######################################################################
def dc_call_rake(task, options = {})
  options[:rails_env] ||= Rails.env
  args = options.map { |o, v| "#{o.to_s.upcase}='#{v}'" }
  system "rake #{task} #{args.join(' ')} --trace 2>&1 >> #{Rails.root}/log/rake.log &"
end

######################################################################
# Small helper for rendering ajax return code from controller. When ajax call is
# made from DRG CMS form return may be quite complicated. All ajax return combinations 
# can be found in drg_cms.js file. 
# 
# @param [Hash] opts: Options
#
# @return [JSON Response] Formatted to be used for ajax return.
# 
# @example
#   html_code = '<span>Some text</span>'
#   dc_render_ajax(div: 'mydiv', prepand: html_code) # Will prepand code to mydiv div
#   dc_render_ajax(class: 'myclass', append: html_code) # Will append code to all objects with myclass class
#   dc_render_ajax(operation: 'window', value: "/pdf_file.pdf") # will open pdf file in new window.
# 
######################################################################
def dc_render_ajax(opts)
  result = {}
  if opts[:div] || opts[:class]
    selector = opts[:div] ? '#' : '.' # for div . for class
    key = case
      when opts[:prepend] then "#{selector}+div"
      when opts[:append]  then "#{selector}div+"
    else "#{selector}div"
    end
    key << "_#{opts[:div]}#{opts[:class]}"
  else
    logger.error 'Error: dc_render_ajax. Operation is not set!' if opts[:operation].nil?
    key = "#{opts[:operation]}_"
  end
  result[key] = opts[:value] || opts[:url] || ''
  render json: result
end

########################################################################
# Find document by parameters. This is how cmsedit finds document based on url parameters.
# 
# @param [String] Table (collection) name. Could be dc_page;dc_part;... when searching for embedded document.
# @param [String] Id of the document
# @param [String] Ids of parent documents when document is embedded. Ids are separated by ; char. 
#
# @return [document]. Required document or nil if not found.
# 
# @example As used in Cmsedit_controller
#   dc_find_document(params[:table], params[:id], params[:ids])
########################################################################
def dc_find_document(table, id, ids)
  tables = table.split(';')
  if tables.size == 1
    doc = tables.first.classify.constantize.find(id)
  else
    ids = ids.split(';')
    doc = tables.first.classify.constantize.find(ids.first)                           # top most record
    1.upto(tables.size - 2) { |i| doc = doc.send(tables[i].pluralize).find(ids[i]) }  # find embedded childrens by ids
    doc = doc.send(tables.last.pluralize).find(id)   # our record
  end
  doc
end

########################################################################
# Reload patches in development. Since patching files are not automatically loaded in
# development environment this little method automatically reloads all patch files
# found in DrgCms.paths(:patches) path array.
########################################################################
def dc_reload_patches
  DrgCms.paths(:patches).each do |patches| 
    Dir["#{patches}/**/*.rb"].each { |file| require_dependency(file) }
  end
end

########################################################################
# Will set new default locale for application
#
# @param [String] new_locale : New locale value. If omitted it will be provided from params[:locale].
#  if new_locale value is 00, application's default_locale will be used.
########################################################################
def dc_set_locale(new_locale = nil)
  new_locale ||= params[:locale]
  if new_locale && new_locale != session[:locale]
    session[:locale] = new_locale == '00' ? nil : new_locale.to_sym
  end
  I18n.locale = session[:locale] ? session[:locale] : I18n.default_locale
end

############################################################################
# Writes out deprication msg. It also adds site_name to message, so it is easier to
# find where the message is comming from.
############################################################################
def dc_deprecate(msg)
  ActiveSupport::Deprecation.warn("#{dc_get_site.name}: #{msg}")
end

####################################################################
# Clears all session data related to login. 
####################################################################
def clear_login_data
  session[:edit_mode]   = 0
  session[:user_id]     = nil
  session[:user_name]   = nil
  set_default_guest_user_role
  cookies.delete :remember_me
end

############################################################################
# Sets at least default guest user to user roles when no user is set.
############################################################################
def set_default_guest_user_role
  guest = DcPolicyRole.find_by(system_name: 'guest')
  session[:user_roles] = [guest.id] if guest
end

####################################################################
# Fills session with data related to successful login.
# 
# @param [DcUser] user : User's document
# @param [Boolean] remember_me : false by default
####################################################################
def fill_login_data(user, remember_me = false)
  session[:user_id]   = user.id if user
  session[:user_name] = user.name.squish if user
  session[:edit_mode] = 0
  set_default_guest_user_role
  return unless user&.active

  # special for SUPERADMIN
  sa = DcPolicyRole.find_by(system_name: 'superadmin')
  if sa && (role = user.dc_user_roles.find_by(dc_policy_role_id: sa.id))
    session[:user_roles] << role.dc_policy_role_id
    session[:edit_mode] = 2
    return
  end
  # read default policy from site. Policy might be inherited from other site
  policy_site = dc_get_site()
  policy_site = DcSite.find(policy_site.inherit_policy) if policy_site.inherit_policy
  default_policy = policy_site.dc_policies.find_by(is_default: true)

  # load user roles from groups
  roles = {}
  user.member.each do |group_id|
    group = DcUser.find(group_id)
    next unless group.active

    group.dc_user_roles.each do |role|
      next unless role.active?
      roles[role.dc_policy_role_id] = role
    end
  end unless user.member.blank?

  # load user roles from user
  user.dc_user_roles.each do |role|
    # not active in user roles will remove role defined in groups
    unless role.active?
      roles.delete(role.dc_policy_role_id) if roles[role.dc_policy_role_id]
      next
    end
    roles[role.dc_policy_role_id] = role
  end
  # select only roles defined in default site policy and set edit_mode
  roles.each do |key, role|
    # check if role is active in this site
    policy_role = default_policy.dc_policy_rules.find_by(dc_policy_role_id: role.dc_policy_role_id)
    next unless policy_role
    # set edit_mode      
    session[:edit_mode] = 1 if policy_role.permission > 1
    session[:user_roles] << role.dc_policy_role_id
  end
  # Save remember me cookie if not CMS user and remember me is selected
  if session[:edit_mode] == 0 && remember_me
    cookies.signed[:remember_me] = { value: user.id, expires: 180.days.from_now }
  end
end

##########################################################################
# Will check if user's login data is still valid and reload user roles.
# 
# @param [Time] repeat_after : Check is repeated after time. This is by default performed every 24 hours.
##########################################################################
def dc_check_user_still_valid(repeat_after = 1.day)
  return if session[:user_id].nil?
  # last check more than repeat_after ago
  if (session[:user_chk] ||= Time.now) < repeat_after.ago
    user_id = session[:user_id]
    clear_login_data
    # reload user roles
    user = DcUser.find( user_id ) rescue nil
    fill_login_data(user)
    session[:user_chk] = Time.now
  end  
end

##########################################################################
# Evaluates Class.method in more predictable context then just calling eval
# 
# @param [String] class_method defined as MyClass.method_name
# @param [Object] params: optional parameters send to class_method
##########################################################################
def dc_eval_class_method(class_method, params = nil)
  klass, method = class_method.split('.')
  # check if class exists
  klass = klass.classify.constantize rescue nil
  if klass.nil?
    logger.error " Class in #{class_method} not defined!"
    return nil
  end
  # call method
  if klass.respond_to?(method)
    klass.send(method, params)
  else
    logger.error "Method in #{class_method} not defined!"
    nil
  end
end

##########################################################################
# Will add new element to json_ld structure
# 
# Parameters:
# [element] Hash or Array of hashes: 
##########################################################################
def dc_add_json_ld(element)
  @json_ld ||= []
  if element.class == Array
    @json_ld += element
  else
    @json_ld << element
  end
end

########################################################################
# Will add a meta tag to internal hash structure. If meta tag already exists it
# will be overwritten.
# 
# Parameters:
# [name] String: meta name
# [content] String: meta content
# 
########################################################################
def dc_add_meta_tag(type, name, content)
  return if content.blank?

  @meta_tags ||= {}
  key = "#{type}=\"#{name}\""
  @meta_tags[key] = content
end

########################################################################
# Will prepare flash[:update] data, which is used for updating elements
# on parent form.
#
# Parameters passed as hash:
# [field] String: Field name
# [head] String: Filed name in head of form
# [value] String: New value
# [readonly] Boolean: Field is readonly
#
########################################################################
def dc_update_form_element(field: nil, head: nil, value:, readonly: true)
  key = if field
    (readonly ? 'td_' : '') + "record_#{field}"
  elsif head
    "head-#{head}"
  end
  return if key.nil?

  flash[:update] ||= {}
  flash[:update][key] = value
end

####################################################################
# Checks if any errors exist on document and writes error log. It can also 
# crash if requested. This is mostly usefull in development for debuging 
# model errors or when updating multiple collections and each save must be 
# checked if succesfull.
# 
# @param [Document] Document object which will be checked
# @param [Boolean] If true method should end in runtime error. Default = false.
# 
# @return [String] Error messages or empty string if everything is OK.
# 
# @Example Check for error when data is saved.
#   model.save
#   if (msg = DcApplicationController.dc_check_model(model) ).size > 0
#     p msg
#     error process ......
#   end
#      
####################################################################
def self.dc_check_model(document, crash = false)
  DrgCms.model_check(document, crash)
end

########################################################################
# Will dump exception to rails log and console.
# 
# Parameters:
# [exception] Object: Exception caught
# 
########################################################################
def dc_dump_exception(exception)
  msg = [exception.message, *exception.backtrace].join($/)
  pp msg
  Rails.logger.error msg
end

private

########################################################################
# Determines if redis cache store is active
#
# @return [Boolean] : True if  redis cache store is active
########################################################################
def xredis_cache_store?
  (Rails.application.config.cache_store.first == :redis_cache_store) rescue false
end

########################################################################
# Returns redis object
#
# @return [Object] : Redis object
########################################################################
def xredis
  Rails.cache.redis
end

########################################################################
# Extends DRG CMS form file. Extended file is processed first and then merged
# with code in this form file. Form can extend only single form file.
#
# [Parameters:]
# [extend_option] : Value of @form['extend'] option
########################################################################
def dc_form_extend(extend_option)
  extend_option.chomp.split(',').each do |a_file|
    form_file_name = CmsHelper.form_file_find(a_file.strip)
    @form_js << read_js_drg_form(form_file_name)
    form  = YAML.load_file( form_file_name )
    @form = CmsHelper.forms_merge(form, @form)
    # If combined form contains tabs and fields options, move fields into fields tab
    if @form.dig('form', 'tabs') && @form.dig('form', 'fields')
      @form['form']['tabs']['fields'] = @form['form']['fields']
      @form['form']['fields'] = nil
    end
  end
end

########################################################################
# Include code from another DRG CMS form file. Included code is merged
# with current form file code. Form can include more than one other DRGCMS forms.
#
# [Parameters:]
# [include_option] : Value of @form['include'] option
########################################################################
def dc_form_include(include_option)
  includes = include_option.class == Array ? include_option : include_option.split(/\,|\;/)
  includes.each do |include_file|
    form_file_name = CmsHelper.form_file_find(include_file)
    @form_js << read_js_drg_form(form_file_name)
    form  = YAML.load_file(form_file_name)
    @form = CmsHelper.forms_merge(@form, form)
  end
end

########################################################################
# Will read data from form_file_name.js if exists.
#
# [Parameters:]
# [form_file_name] : Physical form filename
########################################################################
def read_js_drg_form(form_file_name)
  js_form_file_name = form_file_name.sub('.yml','.js')
  File.read(js_form_file_name) rescue ''
end

########################################################################
# Read DRG form into @form object. Subroutine of check_authorization.
########################################################################
def dc_form_read
  params[:table] ||= params[:t] || CmsHelper.form_param(params)
  table_name = decamelize_type(CmsHelper.table_param(params).strip)
  @tables = table_name.split(';').inject([]) { |r, v| r << [(v.classify.constantize rescue nil), v] }

  # split ids passed when embedded document
  ids = params[:ids].to_s.strip.downcase
  @ids = ids.split(';').inject([]) { |r,v| r << v }

  # form_name defaults to last table specified
  form_name = CmsHelper.form_param(params) || @tables.last[1]
  @form_js = ''

  # dynamically generated form
  @form = if CmsHelper.form_param(params) == 'method'
            dc_eval_class_method(params[:form_method], params)
          else
            form_file_name = CmsHelper.form_file_find(form_name)
            @form_js = read_js_drg_form(form_file_name)
            YAML.load_file(form_file_name)
          end

  # form includes or extends another form file
  dc_form_include(@form['include']) if @form['include']
  dc_form_extend(@form['extend'])   if @form['extend']
  @form['script'] = (@form['script'].blank? ? @form_js : @form['script'] + @form_js)
  # add readonly key to form if readonly parameter is passed in url
  @form['readonly'] = 1 if params['readonly'] #and %w(1 yes true).include?(params['readonly'].to_s.downcase.strip)

  # !!!!!! Always use strings for key names since @form_params['table'] != @form_params[:table]
  @form_params = { 'table' => table_name, 'ids' => params[:ids], 'form_name' => form_name,
                   'return_to' => params['return_to'], 'edit_only' => params['edit_only'],
                   'readonly' => params['readonly'], 'window_close' => params['window_close']}
end

########################################################################
# Will search for help file and return it's full path name if found.
########################################################################
def self.find_help_file(help_file_name)
  file_name = nil
  DrgCms.paths(:forms).reverse.each do |path|
    f = "#{path}/help/#{help_file_name}.#{I18n.locale}"
    file_name = f and break if File.exist?(f)
  end
  file_name
end

end
