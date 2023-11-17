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
require 'sort_alphabetical'

###########################################################################
# 
# DcApplicationHelper defines common helper methods for using with DRG CMS.
#
###########################################################################
module DcApplicationHelper
# page document
attr_reader :page
# design document
attr_reader :design
# site document
attr_reader :site
# menu document
attr_reader :menu
# selected menu_item document
attr_reader :menu_item
# tables url parameter
attr_reader :tables
# ids url parameter
attr_reader :ids
# form object
attr_reader :form
# options object
attr_reader :options
# part
attr_reader :part

# page title
attr_accessor :page_title
# all parts read from page, design, ...
attr_accessor :parts
#
attr_accessor :record
#
attr_accessor :record_footer
# json_ld
attr_reader :json_ld

############################################################################
# When @parent is present then helper methods are called from parent class otherwise 
# from self. 
############################################################################
def _origin #:nodoc:
  @parent ? @parent : self  
end

############################################################################
# Writes out deprication msg. It also adds site_name to message, so it is easier to
# find where the message is comming from.
############################################################################
def dc_deprecate(msg)
  ActiveSupport::Deprecation.warn("#{dc_get_site.name}: #{msg}")
end

############################################################################
# This is main method used for render parts of design into final HTML document.
# 
# Parameters:
# [renderer] String or Symbol. Class name (in lowercase) that will be used to render final HTML code. 
# If class name is provided without '_renderer' suffix it will be added automatically.
# 
# When renderer has value :part, it is a shortcut for dc_render_design_part method which
# is used to draw parts of layout on design.
# 
# [opts] Hash. Additional options that are passed to method. Options are merged with
# options set on site, design, page and passed to renderer object.
# 
# Example:
#    <%= dc_render(:dc_page, method: 'view', category: 'news') %>
############################################################################
def dc_render(renderer, opts={})
  return dc_render_design_part(renderer[:part]) if renderer.class == Hash

  opts[:edit_mode]  = session[:edit_mode] 
  opts[:editparams] = {}
  
  opts = @options.merge(opts) # merge options with parameters passed on site, page, design ...
  opts.symbolize_keys!        # this makes lots of things easier
  # Create renderer object
  klass = renderer.to_s.downcase
  klass += '_renderer' unless klass.match('_renderer') #
  obj = Kernel.const_get(klass.classify, Class.new).new(self, opts) rescue nil

  if obj
    html = obj.render_html
    @css  << obj.render_css.to_s
    html.nil? ? '' : html.html_safe # nil can happened  
  else
    I18n.t 'drgcms.no_class', class: klass
  end
end

########################################################################
# Used for designs with lots of common code and one (or more) part which differs.
# It will simply replace anchor code with value of variable.
# 
# Example: As used in design. Backslashing < and % is important \<\%
#    <% part = "<div  class='some-class'>\<\%= dc_render(:my_renderer, method: 'render_method') \%\></div>" %>
#    <%= dc_replace_in_design(piece: 'piece_name', replace: '[main]', with: part) %>
# 
# Want to replace more than one part. Use array.
#    <%= dc_replace_in_design(replace: ['[part1]','[part2]'], with: [part1, part2]) %>
# 
# This helper is replacement for old 'script' method defined in dc_piece_renderer, 
# but it uses design defined in site document if piece parameter is not set.
########################################################################
def dc_replace_in_design(opts={})
  design = opts[:piece] ? DcPiece.find(name: opts[:piece]).script : dc_get_site.design
  layout = opts[:layout] || (dc_get_site.site_layout.size > 2 ? dc_get_site.site_layout : nil)
  if opts[:replace]
    # replace more than one part of code
    if opts[:replace].class == Array
      0.upto(opts[:replace].size - 1) {|i| design.sub!(opts[:replace][i], opts[:with][i])}
    else
      design.sub!(opts[:replace], opts[:with])
    end
  end
  render(inline: design, layout: nil)
end

########################################################################
# Used for designs with lots of common code and one (or more) part which differs.
# It will simply replace anchor code with value of variable.
# 
# Example: As used in design. Backslashing < and % is important \<\%
#    <% part = "<div  class='some-class'>\<\%= dc_render(:my_renderer, method: 'render_method') \%\></div>" %>
#    <%= dc_replace_in_design(piece: 'piece_name', replace: '[main]', with: part) %>
# 
# Want to replace more than one part. Use array.
#    <%= dc_replace_in_design(replace: ['[part1]','[part2]'], with: [part1, part2]) %>
# 
# This helper is replacement for old 'script' method defined in dc_piece_renderer, 
# but it uses design defined in site document if piece parameter is not set.
########################################################################
def dc_render_from_site(opts={})
  design = opts[:piece] ? DcPiece.find(name: opts[:piece]).script : dc_get_site.design
  layout = opts[:layout] || (dc_get_site.site_layout.size > 2 ? dc_get_site.site_layout : nil)
  
  render(inline: design, layout: opts[:layout], with: opts[:with])
end

########################################################################
# Used for designs with lots of common code and one (or more) part which differs.
# Point is to define design once and replace some parts of design dinamically.
# Design may be defined in site and design doc defines only parts that vary
# from page to page.
# 
# Example: As used in design.
#    <%= dc_render_design_part(@main) %>
#    
#    main variable is defined in design body for example:
#    
#    @main = Proc.new {render partial: 'parts/home'}
# 
# This helper is replacement dc_render_from_site method which will soon be deprecated. 
########################################################################
def dc_render_design_part(part)
  case
  when part.nil? then logger.error('ERROR dc_render_design_part! part is NIL !'); ''
  # Send as array. Part may be defined with options on page. First element has
  # name of element which defines what to do. If not defined default behaviour is
  # called. That is what is defined in second part of array.
  when part.class == Array then
    if @options.dig(:settings, part.first)
      #TODO to be defined 
    else  
      result = part.last.call
      result.class == Array ? result.first : result
    end
  when part.class == Proc then
    result = part.call
    result.class == Array ? result.first : result
  # Send as string. Evaluate content of string
  when part.class == String then eval part
  # For future maybe. Just call objects to_s method.
  else
    part.to_s
  end.html_safe
end

def dc_render_design(part) 
  dc_render_design_part(part) 
end

############################################################################
# This is main method used for render parts of design into final HTML document.
# 
# Parameters:
# [renderer] String or Symbol. Class name (in lowercase) that will be used to render final HTML code. 
# If class name is provided without '_renderer' suffix it will be added automatically.
# 
# When renderer has value :part, it is a shortcut for dc_render_design_part method which
# is used to draw parts of layout on design.
# 
# [opts] Hash. Additional options that are passed to method. Options are merged with
# options set on site, design, page and passed to renderer object.
# 
# Example:
#    <%= dc_render(:dc_page, method: 'view', category: 'news') %>
############################################################################
def dc_render_partial(opts={})
  _origin.render(partial: opts[:partial], formats: [:html], locals: opts[:locals])
end

########################################################################
# Helper for rendering top CMS menu when in editing mode
########################################################################
def dc_page_top
  if @design && @design.rails_view.present?
    # Evaluate parameters in design body
    eval(@design.body)
  end
  session[:edit_mode] > 0 ? render(partial: 'cmsedit/edit_stuff') : ''
end

########################################################################
# Helper for adding additional css and javascript code added by documents
# and renderers during page rendering.
########################################################################
def dc_page_bottom
  %(<style>#{@css}</style>#{javascript_tag @js}).html_safe
end

############################################################################
# Creates title div for DRG CMS dialogs. Title may also contain pagination section on right side if 
# result_set is provided as parameter.
# 
# Parameters:
# [text] String. Title caption.
# [result_set=nil] Document collection. If result_set is passed pagination links will be created.
#  
# Returns:
# String. HTML code for title.
############################################################################
def dc_table_title(text, result_set = nil)
  c = %(<div class="dc-title">#{text})
  c << dc_help_button(result_set)

  if result_set&.respond_to?(:current_page)
    c << %(<div class="dc-paginate">#{paginate(result_set, :params => {action: 'index', clear: 'no', filter: nil})}</div>)
  end
  c << '<div style="clear: both;"></div></div>'
  c.html_safe
end

############################################################################
# Creates title for cmsedit edit action dialog.
#
# Returns:
# String. HTML code for title.
############################################################################
def dc_edit_title
  session[:form_processing] = "form:title:"
  title_data = @form['form']['title']
  if title_data.class == String
    t(title_data, title_data)
  # defined as form:title:edit
  elsif title_data&.dig('edit') && !@form['readonly']
    t( title_data['edit'], title_data['edit'] )
  elsif title_data&.dig('show') && @form['readonly']
    t( title_data['show'], title_data['show'] )
  else
    c = (@form['readonly'] ? t('drgcms.show') : t('drgcms.edit')) + " : "
    c << (@form['title'].class == String ? t( @form['title'], @form['title'] ) : t_tablename(@form['table']))
    # add description field value to title
    field_name = title_data['field'] if title_data
    c << " : #{@record[ field_name ]}" if field_name && @record.respond_to?(field_name)
    c
  end
end

############################################################################
# Creates title for cmsedit new action dialog. 
# 
# Returns:
# String. HTML code for title.
############################################################################
def dc_new_title
  session[:form_processing] = "form:title:"
  title_data = @form['form']['title']
  if title_data.class == String
    t(title_data, title_data)
  # defined as form:title:new
  elsif title_data&.dig('new')
    t( title_data['new'], title_data['new'] )
  else
    # in memory structures
    if @form['table'] == 'dc_memory'
      return t( @form['title'], @form['title'] ) if @form['title']

      t("#{@form['i18n_prefix']}.tabletitle", '')
    else
      "#{t('drgcms.new')} : #{t_tablename(@form['table'])}"    
    end
  end
end

############################################################################
# Similar to rails submit_tag, but also takes care of link icon, translation, ...
############################################################################
def dc_submit_tag(caption, icon, parms, rest = {})
  icon_image = dc_icon_for_link(icon, nil)
  %(<button type="submit" class="dc-submit" name="commit" value="#{t(caption, caption)}">#{icon_image} #{t(caption, caption)}</button>).html_safe
end

############################################################################
# Returns icon code if icon is specified
############################################################################
def dc_icon_for_link(icon, clas = 'dc-link-img')
  return '' if icon.blank?

  if icon.match(/\./)
    _origin.image_tag(icon, class: clas)
  elsif icon.match('<i')
    icon
  else
    _origin.fa_icon(icon)
  end
end
  
############################################################################
# Similar to rails link_to, but also takes care of link icon, translation, ...
############################################################################
def dc_link_to(caption, icon, parms, rest={})
  icon_pos = 'first'
  if parms.class == Hash
    parms.stringify_keys!
    rest.stringify_keys!
    url = parms.delete('url')
    rest['target'] ||=  parms.delete('target')
    parms['controller'] ||= 'cmsedit'
    icon_pos = parms.delete('icon_pos') || 'first'
  end

  icon_image = dc_icon_for_link(icon)
  if caption
    caption = t(caption, caption)
    icon_image << ' ' if icon_image
  end

  body = (%w[first left].include?(icon_pos) ? "#{icon_image}#{caption}" : "#{caption} #{icon_image}").html_safe
  url ? _origin.link_to(body, url, rest) : _origin.link_to(body, parms, rest)
end

####################################################################
# Returns flash messages formatted for display on message div.
# 
# Returns:
# String. HTML code formatted for display.
####################################################################
def dc_flash_messages()
  err    = _origin.flash[:error]
  war    = _origin.flash[:warning]
  inf    = _origin.flash[:info]
  note   = _origin.flash[:note]
  html   = ''
  unless err.nil? and war.nil? and inf.nil? and note.nil?
    html << "<div class=\"dc-form-error\">#{err}</div>" if err
    html << "<div class=\"dc-form-warning\">#{war}</div>" if war
    html << "<div class=\"dc-form-info\">#{inf}</div>" if inf
    html << note if note
    _origin.flash[:error]   = nil
    _origin.flash[:warning] = nil
    _origin.flash[:info]    = nil
    _origin.flash[:note]    = nil
  end
  # Update fields on the form
  if _origin.flash[:update]
    html << "<div class=\"dc-form-updates\">\n"
    _origin.flash[:update].each do |field, value|
      html << %Q[<div data-field="#{field}" data-value="#{value}"></div>\n]
    end
    html << '</div>'
    _origin.flash[:update] = nil
  end
  html.html_safe
end

########################################################################
# Decamelizes string. This probably doesn't work very good with non ascii chars.
# Therefore it is very unwise to use non ascii chars for table (collection) names.
# 
# Parameters: 
# [Object] model_string. String or model to be converted into decamelized string.
# 
# Returns:
# String. Decamelized string.
########################################################################
def decamelize_type(model_string)
  model_string ? model_string.to_s.underscore : nil
end

####################################################################
# Returns validation error messages for the document (record) formatted for 
# display on message div.
# 
# Parameters: 
# [doc] Document. Document record which will be checked for errors.
# 
# Returns:
# String. HTML code formatted for display.
####################################################################
def dc_error_messages_for(doc)
  return '' unless doc && doc.errors.any?

  msgs = doc.errors.inject('') do |r, error|
    label = t("helpers.label.#{decamelize_type(doc.class)}.#{error.attribute}", error.attribute)
    r << "<li>#{label} : #{error.message}</li>"
  end

  %(
<div class="dc-form-error"> 
  <h2>#{t('drgcms.errors_no')} #{doc.errors.size}</h2>  
  <ul>#{msgs}</ul>  
</div>).html_safe
end

####################################################################
# Returns warning messages if any set in a model.
#
# When warnings array is added to model its content can be written on top of the form.
#
# Parameters:
# [doc] Document. Document record which will be checked for errors.
#
# Returns:
# String. HTML code formatted for display.
####################################################################
def dc_warning_messages_for(doc)
  return ''
  return '' unless doc && doc.respond_to?(:warnings)

  msgs = doc.warnings.inject('') do |r, error|
    label = t("helpers.label.#{decamelize_type(doc.class)}.#{error.attribute}", error.attribute)
    msgs << "<li>#{label} : #{error.message}</li>"
  end

  %(
<div class="dc-form-warning"> 
  <h2>#{t('drgcms.warnings_no')} #{doc.warnings.size}</h2>  
  <ul>#{msgs}</ul>  
</div>).html_safe
end

####################################################################
# Checks if CMS is in edit mode (CMS menu bar is visible).
#  
# Returns:
# Boolean. True if in edit mode
####################################################################
def dc_edit_mode?
  _origin.session[:edit_mode] > 1
end

####################################################################
# Will create HTML code required to create new document.
# 
# Parameters: 
# [opts] Hash. Optional parameters for url_for helper. These options must provide at least table and form_name
# parameters. 
# 
# Example:
#    if @opts[:edit_mode] > 1
#      opts = {table: 'dc_page;dc_part', form_name: 'dc_part', ids: @doc.id }
#      html << dc_link_for_create( opts.merge!({title: 'Add new part', 'dc_part.name' => 'initial name', 'dc_part.order' => 10}) ) 
#    end
# 
# Returns:
# String. HTML code which includes add image and javascript to invoke new document create action.
####################################################################
def dc_link_for_create(opts)
  opts.stringify_keys!  
  title = opts.delete('title') #
  title = t(title, title) if title
  target = opts.delete('target')  || 'iframe_cms'
  opts['form_name']  ||= opts['table'].to_s.split(';').last
  opts['action']       = 'new'
  opts['controller'] ||= 'cmsedit'
  js = "$('##{target}').attr('src', '#{_origin.url_for(opts)}'); return false;"
  dc_link_to(nil, _origin.fa_icon('plus-circle'), '#',
             { onclick: js, title: title, alt: 'Create', class: 'dc-inline-link'}).html_safe
end

####################################################################
# Will create HTML code required to edit document.
# 
# Parameters: 
# [opts] Hash. Optional parameters for url_for helper. These options must provide 
# at least table, form_name and id parameters. Optional title, target and icon parameters
# can be set.
# 
# Example:
#    html << dc_link_for_edit( @options ) if @opts[:edit_mode] > 1
#    
# Returns:
# String. HTML code which includes edit image and javascript to invoke edit document action.
####################################################################
def dc_link_for_edit(opts)
  opts.stringify_keys!  
  title  = opts.delete('title') #
  title  = t(title)
  target = opts.delete('target') || 'iframe_cms'
  icon   = opts.delete('icon') || 'edit-o'
  opts['controller'] ||= 'cmsedit'
  opts['action']     ||= 'edit'
  opts['form_name']  ||= opts['table'].to_s.split(';').last
  js  = "$('##{target}').attr('src', '#{_origin.url_for(opts)}'); return false;"
  dc_link_to(nil, _origin.fa_icon(icon), '#',
             { onclick: js, title: title, class: 'dc-inline-link', alt: 'Edit'})
end

####################################################################
# Create edit link with edit picture. Subroutine of dc_page_edit_menu.
####################################################################
def dc_link_menu_tag(title) #:nodoc:
  html = %(
<dl>
  <dt><div class='drgcms_popmenu dc-inline-link' href="#">
    #{_origin.fa_icon('file-text-o', title: title)}
  </div></dt>
  <dd>
    <ul class=' div-hidden drgcms_popmenu_class'>
)

  yield html
  html << "</ul></dd></dl>"
end

####################################################################
# Create one option in page edit link. Subroutine of dc_page_edit_menu.
####################################################################
def dc_link_for_edit1(opts, link_text) #:nodoc:
  icon = opts.delete('icon')
  url  = _origin.url_for(opts)
  "<li><div class='drgcms_popmenu_item' style='cursor: pointer;' data-url='#{url}'>
#{_origin.fa_icon(icon)} #{link_text}</div></li>\n"
end

########################################################################
# Create edit menu for editing existing or creating new dc_page documents. Edit menu
# consists of for options.
# * Edit content. Will edit only body part od document.
# * Edit advanced. Will create edit form for editing all document fields.
# * New page. Will create new document and pass some initial data to it. Initial data is saved to cookie.
# * New part. Will create new part of document.
# 
# Parameters:
# [opts] Hash. Optional parameters for url_for helper. These options must provide at least table and form_name
# and id parameters. 
# 
# Example:
#    html << dc_page_edit_menu() if @opts[:edit_mode] > 1
# 
# Returns: 
# String. HTML code required for manipulation of currently processed document.
########################################################################
def dc_page_edit_menu(opts = @opts)
  opts[:edit_mode] ||= _origin.session[:edit_mode]
  return '' if opts[:edit_mode] < 2

  # save some data to cookie. This can not go to session.
  page  = opts[:page] || @page
  table = _origin.site.page_class.underscore
  kukis = { "#{table}.dc_design_id" => page.dc_design_id,
#            "#{table}.menu_id"      => page.menu_id,
            "#{table}.kats"         => page.kats,
            "#{table}.page_id"      => page.id,
            "#{table}.dc_site_id"   => _origin.site.id
  }
  _origin.cookies[:record] = Marshal.dump(kukis)
  title = "#{t('drgcms.edit')}: #{page.subject}"
  opts[:editparams] ||= {}
  dc_link_menu_tag(title) do |html|
    opts[:editparams].merge!( controller: 'cmsedit', action: 'edit', 'icon' => 'edit-o' )
    opts[:editparams].merge!( :id => page.id, :table => _origin.site.page_class.underscore, form_name: opts[:form_name], edit_only: 'body' )
    html << dc_link_for_edit1( opts[:editparams], t('drgcms.edit_content') )
    
    opts[:editparams].merge!( edit_only: nil, 'icon' => 'edit-o' )
    html << dc_link_for_edit1( opts[:editparams], t('drgcms.edit_advanced') )
    
    opts[:editparams].merge!( action: 'new', 'icon' => 'plus' )
    html << dc_link_for_edit1( opts[:editparams], t('drgcms.edit_new_page') )

    opts[:editparams].merge!(ids: page.id, form_name: 'dc_part', 'icon' => 'plus',
                             table: "#{_origin.site.page_class.underscore};dc_part"  )
    html << dc_link_for_edit1( opts[:editparams], t('drgcms.edit_new_part') )
  end.html_safe
end

########################################################################
# Return page class model defined in site document page_class field. 
# 
# Used in forms, when method must be called from page model and model is overwritten by 
# user's own model.
# 
# Example as used on form:
#    30:
#      name: link
#      type: text_with_select
#      eval: 'dc_page_class.all_pages_for_site(@parent.dc_get_site)'
########################################################################
def dc_page_class
  dc_get_site.page_klass
end

########################################################################
# Return menu class model defined in site document menu_class field. 
# 
# Used in forms for providing menus class to the forms object.
# 
# Example as used on form:
#    30:
#      name: menu_id
#      type: tree_view
#      eval: 'dc_menu_class.all_menus_for_site(@parent.dc_get_site)'
########################################################################
def dc_menu_class
  dc_get_site.menu_class.classify.constantize
end

####################################################################
# Parse site name from url and return dc_site document. Site document will be cached in
# @site variable.
# 
# If not in production environment and site document is not found
# method will search for 'test' document and return dc_site document found in alias_for field.
# 
# Returns:
# DCSite. Site document.
####################################################################
def dc_get_site
  return @site if @site # already cached

  req = _origin.request.url # different when called from renderer
  uri  = URI.parse(req)
  @site = DcSite.find_by(name: uri.host)
  # Site can be aliased
  @site = DcSite.find_by(name: @site.alias_for) if @site&.alias_for.present?
  # Development. If site with name test exists use alias_for field as pointer to real site data
  if @site.nil? && ENV["RAILS_ENV"] != 'production'
    @site = DcSite.find_by(name: 'test')
    @site = DcSite.find_by(name: @site.alias_for) if @site
  end 
  @site = nil if @site && !@site.active # site is disabled
  @site
end

############################################################################
# Return array of policies defined in a site document formated to be used
# as choices for select field. Method is used for selecting site policy where
# policy for displaying data is required.
# 
# Example (as used in forms):
#    name: policy_id
#    type: select
#    eval: dc_choices4_site_policies
#    html:
#      include_blank: true      
############################################################################
def dc_choices4_site_policies
  site = dc_get_site()
  site.dc_policies.where(active: true).order_by(name: 1).map { |policy| [ policy.name, policy.id] }
end

############################################################################
# Returns list of all collections (tables) as array of choices for usage in select fields.
# List is collected from cms_menu.yml files and may not include all collections used in application.
# Currently list is only used for helping defining collection names on dc_permission form.
#
# Example (as used in forms):
#    form:
#      fields:
#        10:
#          name: table_name
#          type: text_with_select
#          eval: dc_choices4_all_collections
############################################################################
def dc_choices4_all_collections
  models = Mongoid.models.map(&:to_s).uniq.map(&:underscore).delete_if { |e| e.match('/') }
  models.sort.inject([]) do |r, model_name|
    r << ["#{model_name} - #{t("helpers.label.#{model_name}.tabletitle", '')}", model_name]
  end
end

##########################################################################
# Code for top CMS menu.
##########################################################################
def dc_cms_menu
  menus = {}
  DrgCms.paths(:forms).reverse.each do |path|
    filename = "#{path}/cms_menu.yml"
    next if !File.exist?(filename)

    menu  = YAML.load_file(filename) rescue nil # load menu
    menus = CmsHelper.forms_merge(menu['menu'], menus) if menu.dig('menu') # merge menus
  end

  html = '<ul>'
  menus.to_a.sort.each do |index, menu|    # sort menus, result is array of sorted hashes
    next unless menu['caption']

    icon = menu['icon'].match('/') ? image_tag(menu['icon']) : fa_icon(menu['icon']) #external or fa- image
    html << %(<li class="cmsedit-top-level-menu"><div>#{icon}#{t(menu['caption'])}</div><ul>)
    menu['items'].to_a.sort.each do |index1, value|   # again, sort menu items first 
      html << if value['link']
        opts = { target: value['target'] || 'iframe_cms' }
        "<li>#{dc_link_to(t(value['caption']), value['icon'] || '', value['link'], opts)}</li>"
      else
        opts = { controller: value['controller'], action: value['action'],
                 table: value['table'], form_name: value['form_name'] || value['table'],
                 target: value['target'] || 'iframe_cms',
               }
        # additional parameters
        value['params'].each { |k, v| opts[k] = dc_value_for_parameter(v) } if value['params']
        "<li>#{dc_link_to(t(value['caption']), value['icon'] || '', opts)}</li>"
      end
    end   
    html << '</ul></li>'  
  end
  html.html_safe
end

############################################################################
# Returns list of directories as array of choices for use in select field 
# on folder permission form. Directory root is determined from dc_site.files_directory field.
############################################################################
def dc_choices4_folders_list
  public = File.join(Rails.root,'public')
  home   = File.join(public,dc_get_site.files_directory)
  choices = Dir.glob(home + '/**/*/').select { |fn| File.directory?(fn) }
  choices << home # add home
  choices.collect! { |e| e.gsub(public,'') } # remove public part
  choices.sort
end

############################################################################
# Returns choices for select input field when choices are generated from
# all documents in collection.
# 
# Parameters:  
# [model] String. Collection (table) name in lowercase format.
# [name] String. Field name containing description text.
# [id] String. Field name containing id field. Default is '_id'
# [options] Hash. Various options. Currently site: (:only, :with_nil, :all) is used.
# Will return only documents belonging to current site, also with site not defined,
# or all documents.
# 
# Example (as used in forms):
#    50:
#      name: dc_poll_id
#      type: select
#      eval: dc_choices4('dc_poll','name','_id')
############################################################################
def dc_choices4(model, name, id = '_id', options = {})
  model = model.classify.constantize
  qry   = model.only(id, name)
  if (param = options[:site])
    sites = [dc_get_site.id] unless param == :all
    sites << nil if param == :with_nil 
    qry   = qry.in(dc_site_id: sites) if sites
  end
  qry = qry.and(active: true) if model.method_defined?(:active)
  qry = qry.order_by(name => 1).collation(locale: I18n.locale.to_s)
  qry.map { |e| [e[name], e[id]] }
end

############################################################################
# Returns list of choices for selection top level menu on dc_page form. Used for defining which 
# top level menu will be highlited when page is displayed.
# 
# Example (as used in forms):
#    20:
#      name: menu_id
#      type: select
#      eval: dc_choices4_menu      
############################################################################
def dc_choices4_menu
  m_clas = dc_get_site.menu_class
  m_clas = 'DcSimpleMenu' if m_clas.blank?
  klass  = m_clas.classify.constantize
  klass.choices4_menu(dc_get_site)
end

############################################################################
# Will add data to record cookie. Record cookie is used to preload some 
# data on next create action. Create action will look for cookies[:record] and 
# if found initialize fields on form with matching name to value found in cookie data.
# 
# Example:
#    kukis = {'dc_page.dc_design_id' => @page.dc_design_id,
#             'dc_page.dc_menu_id' => @page.menu_id)
#   dc_add2_record_cookie(kukis)
############################################################################
def dc_add2_record_cookie(hash)
  kukis = if @parent.cookies[:record] and @parent.cookies[:record].size > 0
    Marshal.load(@parent.cookies[:record])
  else
    {}
  end
  hash.each {|k,v| kukis[k] = v }
  @parent.cookies[:record] = Marshal.dump(kukis)
end

############################################################################
# Will check if user roles allow user to view data in document with defined access_policy.
# 
# Parameters:
# [ctrl] Controller object or object which holds methods to access session object. For example @parent
# when called from renderer.
# [policy_id] Document or documents policy_id field value required to view data. Method will automatically 
# check if parameter send has policy_id field defined and use value of that field.
# 
# Example:
#    can_view, message = dc_user_can_view(@parent, @page) 
#    # or
#    can_view, message = dc_user_can_view(@parent, @page.policy_id)
#    return message unless can_view
# 
# Returns:
# True if access_policy allows user to view data. 
# False and message from policy that is blocking view if access is not allowed.
############################################################################
def dc_user_can_view(ctrl, policy_id)
  @can_view_cache ||= {}
  policy_id = policy_id.policy_id if policy_id&.respond_to?(:policy_id)
  # Eventualy object without policy_id will be checked. This is to prevent error
  policy_id = nil unless policy_id.class == BSON::ObjectId
  return @can_view_cache[policy_id] if @can_view_cache[policy_id]

  site = ctrl.site
  policies = if site.inherit_policy.blank? 
    site.dc_policies
  else
    Mongo::QueryCache.cache { DcSite.find(site.inherit_policy) }.dc_policies
  end
  # permission defined by default policy
  default_policy = Mongo::QueryCache.cache { policies.find_by(is_default: true) }
  return cache_add(policy_id, false, 'Default access policy not found for the site!') unless default_policy

  permissions = {}
  default_policy.dc_policy_rules.to_a.each { |v| permissions[v.dc_policy_role_id] = v.permission }
  # update permissions with defined policy
  part_policy = nil
  if policy_id
    part_policy = Mongo::QueryCache.cache { policies.find(policy_id) }
    return cache_add(policy_id, false, 'Access policy not found for part!') unless part_policy

    part_policy.dc_policy_rules.to_a.each { |v| permissions[v.dc_policy_role_id] = v.permission }
  end
  # apply guest role if no roles defined
  if ctrl.session[:user_roles].nil?
    role = Mongo::QueryCache.cache { DcPolicyRole.find_by(system_name: 'guest', active: true) }
    return cache_add(policy_id, false, 'System guest role not defined!') unless role

    ctrl.session[:user_roles] = [role.id]
  end
  # Check if user has any role that allows him to view part
  can_view = ctrl.session[:user_roles].reduce(false) do |result, role|
    break true if permissions[role] && permissions[role] > 0
  end

  msg = ''
  unless can_view
    msg = part_policy ? t(part_policy.message, part_policy.message) : t(default_policy.message, default_policy.message)
    # message may have variable content
    msg = _origin.render(inline: msg, layout: nil) if msg.match('<%=')
  end
  cache_add(policy_id, can_view, msg)
end

####################################################################
# Check if user has required role assigned to its user profile. If role is passed as
# string method will check roles for name and system name.
# 
# Parameters:
# [role] DcPolicyRole/String. Required role. If passed as string role will be searched in dc_policy_roles collection.
# [user] User id. Defaults to session[:user_id].
# [roles] Array of roles that will be searched. Default session[:user_roles].
# 
# Example:
#    if dc_user_has_role('decision_maker', session[:user_id), session[:user_roles]) 
#      do_something_important
#    end
#    
# Returns:
# Boolean. True if user has required role.    
####################################################################
def dc_user_has_role( role, user=nil, roles=nil )
  roles = _origin.session[:user_roles] if roles.nil?
  user  = _origin.session[:user_id] if user.nil?
  return false if user.nil? or roles.nil?

  role = DcPolicyRole.get_role(role)
  return false if role.nil?
  # role is included in roles array
  roles.include?(role._id)
end

####################################################################
# Returns true if parameter has value of 0, false, no, none or -. Returns default
# if parameter has nil value.
# 
# Parameters:
# [what] String/boolean/Integer. 
# [default] Default value when what has value of nil. False by default.
# 
# Example:
#    dc_dont?('none') # => true
#    dc_dont?('-')    # => true
#    dc_dont?(1)      # => false
####################################################################
def dc_dont?(what, default=false)
  return default if what.nil?

  %w(0 n - no none false).include?(what.to_s.downcase.strip)
end

############################################################################
# Truncates string length maximal to the size required and takes care, that words are not broken in middle.
# Used for output text summary with texts that can be longer then allowed space.
# 
# Parameters:
# [string] String of any size.
# [size] Maximal size of the string to be returned. 
# 
# Example:
#    dc_limit_string(description, 100)
#    
# Returns:
# String, truncated to required size. If string is truncated '...' will be added to the end.
############################################################################
def dc_limit_string(string, size)
  return string if string.size < size

  string = string[0,size]
  string.chop! until (string[-1,1] == ' ' or string == '')
  string << '...'
end

############################################################################
# Returns key defined in DcBigTable as array of choices for use in select fields.
# DcBigTable can be used like a key/value store for all kind of predefined values 
# which can be linked to site and or locale.
# 
# Parameters:
# [key] String. Key name to be searched in dc_big_tables documents.
# 
# Example:
#    10:
#      name: category
#      type: select
#      eval: dc_big_table 'categories_for_page'  # as used on form
# 
# Returns:
# Array of choices ready for select field.
############################################################################
def dc_big_table(key)
  ret = []
  bt = DcBigTable.find_by(key: key, site: dc_get_site._id, active: true)
  bt = DcBigTable.find_by(key: key, site: nil, active: true) if bt.nil?
  return ret if bt.nil? 

  locale = I18n.locale.to_s
  bt.dc_big_table_values.each do |v|   # iterate each value
    next unless v.active

    desc = ''
    v.dc_big_table_locales.each do |l| # iterate each locale
      if l.locale == locale
        desc = l.description
        break
      end
    end
    desc = v.description if desc.blank? # get description from value description
    desc = v.value if desc.blank?       # still blank. Use value as description
    ret << [desc, v.value] 
  end
  ret.sort_alphabetical_by(&:first)
end

########################################################################
# Will return name for value defined in dc_big_table
########################################################################
def dc_big_table_name_for_value(key, value)
  dc_big_table(key).each { |k, val| return k if val.to_s == value.to_s}
  '???'
end

########################################################################
# Will return html code required for load DRG form into iframe. If parameters 
# are passed to method iframe url will have initial value and thus enabling automatic form
# load on page display.
# 
# Parameters:
# [table] String: Collection (table) name used to load initial form.
# [opts] Hash: Optional parameters which define url for loading DRG form.
# These parameters are :action, :oper, :table, :form_name, :id, :readonly
# 
# Example:
#    # just iframe code
#    <%= dc_iframe_edit(nil) %>
#    # load note form for note collection
#    <%= dc_iframe_edit('note') %>
#    # on register collection use reg_adresses form_name to display data with id @register.id
#    <%= dc_iframe_edit('register', action: :show, form_name: 'reg_adresses', readonly: 1, id: @register.id ) %>
# 
# Returns:
# Html code for edit iframe
########################################################################
def dc_iframe_edit(table, opts={})
  ret = if params.to_unsafe_h.size > 2 && table  # controller, action, path is minimal
    params[:controller] = 'cmsedit'
    params[:action]     = (params[:oper] && (params[:oper] == 'edit')) ? 'edit' : 'index'
    params[:action]     = opts[:action] unless params[:oper]
    params[:table]      ||= table 
    params[:form_name]  ||= opts[:form_name] || table 
    params[:id]         ||= params[:idp] || opts[:id]
    params[:readonly]   ||= opts[:readonly]
    params[:path]       = nil
    params.permit! # rails 5 request
    "<iframe id='iframe_edit' name='iframe_edit' src='#{url_for params}'></iframe>"
  else
    "<iframe id='iframe_edit' name='iframe_edit'></iframe>"
  end
  ret.html_safe
end

########################################################################
# Will return value from Rails and DRG internal objects.
# This objects can be params, session, record, site, page
# 
# Parameters:
# [object] String: Internal object holding variable. Possible values are session, params, record, site, page, class
# [var_name] String[symbol]: Variable name (:user_name, 'user_id', ...)
# [current_document] Object: If passed and object is 'record' then it will be used for retrieving data.
# 
# Example:
#    # called when constructing iframe for display
#    dc_internal_var('session', :user_id)
#    dc_internal_var('params', :some_external_parameter)
#    dc_internal_var('site', :name)
#    # or even
#    dc_internal_var('class', 'ClassName.class_method_name')
#    
# 
# Returns:
# Value of variable or error when not found
########################################################################
def dc_internal_var(object, var_name, current_document = nil)
  begin
    case object
    when 'session' then _origin.session[var_name]
    when 'params'  then _origin.params[var_name]
    when 'site'    then _origin.dc_get_site.send(var_name)
    when 'page'    then _origin.page.send(var_name)
    when 'record'  then
      current_document ? current_document.send(var_name) : _origin.record.send(var_name)
    when 'class'   then
      clas, method_name = var_name.split('.')
      klas = clas.classify.constantize
      # call method. Error will be caught below.
      klas.send(method_name)
    else
      'dc_internal: UNKNOWN OBJECT'
    end
  rescue Exception => e
    Rails.logger.debug "\ndc_internal_var. Runtime error. #{e.message}\n"
    Rails.logger.debug(e.backtrace.join($/)) if Rails.env.development?
    'dc_internal: ERROR'
  end
end

########################################################################
# Will return whole path to document if document is embedded in another document.
# 
# Parameters:
# [document] Object: Document object
# 
# Returns:
# String of ID-s separated by semicolon.
#######################################################################
def dc_document_path(document)
  path, parent = [document.id], document._parent
  while parent
    path << parent.id
    parent = parent._parent
  end 
  path.reverse.join(';')
end

########################################################################
# Will return formated code for embedding json+ld data into page
# 
# Returns:
# HTML data to be embedded into page header
#######################################################################
def dc_get_json_ld
  return '' if @json_ld.blank?

  %(
<script type="application/ld+json">
#{JSON.pretty_generate({ '@context' => 'http://schema.org', '@graph' => @json_ld })}
</script>).html_safe
end

########################################################################
# Will add new element to json_ld structure
# 
# Parameters:
# [element] Hash or Array of hashes: json+ld element
#######################################################################
def dc_add_json_ld(element)
  @json_ld ||= []
  if element.class == Array
    @json_ld += element
  else
    @json_ld << element
  end
end

########################################################################
# Will return meta data for SEO optimizations.
# It will also create special link rel="canonical" tag if defined in meta tags or page document.
# 
# Returns:
# HTML data to be embedded into page header
#######################################################################
def dc_get_seo_meta_tags
  html = ''
  has_canonical = false
  html << @meta_tags.inject('') do |r, tag|
    r << if tag.first.match('canonical')
           has_canonical = true
           dc_get_link_canonical_tag(tag.last)
         else
           %(<meta #{tag.first} content="#{tag.last}">\n  )
         end
  end if @meta_tags
  html << dc_get_link_canonical_tag(@page&.canonical_link) unless has_canonical
  html.html_safe
end

########################################################################
# helper for setting canonical link on the page
#######################################################################
def dc_get_link_canonical_tag(href = nil)
  return %(<link rel="canonical" href="#{request.url}">\n) if href.blank?

  unless href.match(/^http/i)
    uri  = URI.parse(request.url)
    href = "#{uri.scheme}://#{uri.host}/#{href.delete_prefix('/')}"
  end
  %(<link rel="canonical" href="#{href}">\n)
end

########################################################################
# Will add a meta tag to internal hash structure. If meta tag already exists it
# will be overwritten.
# 
# Parameters:
# [name] String: meta name
# [content] String: meta content
########################################################################
def dc_add_meta_tag(type, name, content)
  return if content.blank?

  @meta_tags ||= {}
  key = "#{type}=\"#{name}\""
  @meta_tags[key] = content
end

#######################################################################
# Will return alt image option when text is provided. When text is blank
# it will extract alt name from picture file_name. This method returns
# together with alt="image-tag" tag.
# 
# Parameters:
# [file_name] String: Filename of a picture
# [text] String: Alt text name
# 
# Returns:
# [String] alt="image-tag"
#######################################################################
def dc_img_alt_tag(file_name, text = nil)
  %( alt="#{dc_img_alt(file_name, text)}" ).html_safe
end

#######################################################################
# Will return alt image option when text is provided. When text is blank
# it will extract alt name from picture file_name. This method returns just 
# alt name.
# 
# Parameters:
# [file_name] String: Filename of a picture
# [text] String: Alt text name
#
# Returns:
# [String] alt_image_name
#######################################################################
def dc_img_alt(file_name, text = nil)
  return text if text.present?

  name = File.basename(file_name.to_s)
  name[0, name.index('.')].downcase rescue name
end

private

########################################################################
# To cache localy dc_user_can_view response for a single call. It has large gains on sites
# with large menus.
########################################################################
def cache_add(id, can_view, msg)
  @can_view_cache[id] = [can_view, msg]
end


end
