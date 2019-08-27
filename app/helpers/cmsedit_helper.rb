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

###########################################################################
# 
# CmseditHelper module defines helper methods used by cmsedit actions. Output is controlled by 
# data found in 3 major sections of DRG CMS form: index, result_set and form sections. 
#
###########################################################################
module CmseditHelper
  # javascript part created by form helpers
  attr_reader :js 
  
############################################################################
# Get standard actions when actions directive contains single line.
# Subroutine of dc_actions_for_index
# 
# Allows for actions: new, filter, standard syntax
############################################################################
def define_standard_actions(actions_params, standard)
  actions = {}
  actions_params.split(',').each do |an_action|
    an_action.strip!
    if an_action == 'standard'
      actions.merge!(standard)
    else
      standard.each do |index, action| 
        (actions[index] = action; break) if action == an_action
      end
    end
  end 
  actions
end

############################################################################
# Creates action div for cmsedit index action. 
############################################################################
def dc_actions_for_index()
  return '' if @form['index'].nil? or @form['readonly']
  actions = @form['index']['actions']
  return '' if actions.nil? or actions.size == 0
  std_actions = {2 => 'new', 3 => 'sort', 4 => 'filter' }
  if actions.class == String
    actions = define_standard_actions(actions, std_actions)
  elsif actions['standard']
    actions.merge!(std_actions)
    actions['standard'] = nil
  end
  
# start div with hidden spinner image 
  html = <<EOT
<div id="dc-action-menu">
  <span class="dc-spinner div-hidden">#{fa_icon('spinner lg spin')}</span>
  <ul class="dc-action-menu">
EOT
# Remove actions settings and sort
  only_actions = []
  actions.each { |key, value| only_actions << [key, value] if key.class == Integer }
  only_actions.sort_by!(&:first)
  only_actions.each do |element|
    k,v = element
    session[:form_processing] = "index:actions: #{k}=#{v}"
    next if v.nil? # must be
    url = @parms.clone
    yaml = v.class == String ? {'type' => v} : v # if single definition simulate type parameter
    action = yaml['type'].to_s.downcase 
    if action == 'url'
      dc_deprecate "action: url will be deprecated. Use action: link in index: actions"
      action = 'link' 
    end
# if return_to is present link directly to URL 
    if action == 'link' and yaml['url']
      url = yaml['url']
    else
      url['controller'] = yaml['controller'] if yaml['controller']
      url['action']     = yaml['action'] || action
      url['table']      = yaml['table']  if yaml['table']
      url['form_name']  = yaml['form_name'] if yaml['form_name']
    end
# html link options
    yhtml = yaml['html'] || {}
    yhtml['title'] = yaml['title'] if yaml['title']
    html << '<li class="dc-animate">' 
# 
    html << case 
# sort
    when action == 'sort' then 
      choices = [['id','id']]
      if @form['index']['sort']
        @form['index']['sort'].split(',').each do |s| 
          s.strip!
          choices << [ t("helpers.label.#{@form['table']}.#{s}"), s ]
        end
      end
      fa_icon('sort-alpha-asc') + ' ' + t('drgcms.sort') + ' ' + 
              select('sort', 'sort', choices, { include_blank: true }, 
              { class: 'drgcms_sort', 'data-table' => @form['table']} )
# filter
    when action == 'filter' then 
      caption = t('drgcms.filter')
      caption << '&nbsp;' + fa_icon('caret-down lg') + DcFilter.menu_filter(self)
# add filter OFF link
      s = session[@form['table']]
      if s and s[:filter]
        caption << '&nbsp;&nbsp;' + dc_link_to(nil,'remove lg', {controller: 'cmsedit', 
                   filter: 'off', table: @form['table']}, { title: DcFilter.title4_filter_off(s[:filter]) }) 
      end
      caption
# new
    when action == 'new' then 
      caption = yaml['caption'] || 'drgcms.new'
      dc_link_to(caption,'plus', url, yhtml )
# menu      
    when action == 'menu' then  
      caption = t(v['caption'], v['caption']) + '&nbsp;' + fa_icon('caret-down lg')
      caption + eval(v['eval'])      
=begin
# reorder      
    when action == 'reorder' then  
      caption = t('drgcms.reorder')
      parms = @parms.clone
      parms['operation'] = v
      parms['id']       = params[:ids]
      parms['table']     = @form['table']
      dc_link_to( caption, 'reorder', parms, method: :delete )              
=end      
    else 
      caption = yaml['caption'] || yaml['text']
      icon    = yaml['icon'] ? yaml['icon'] : action
      dc_link_to(caption, icon, url, yhtml)
    end
    html << '</li>'
  end
  html << '</ul>'
  html << DcFilter.get_filter_field(self)
  html << '</div>'
  html.html_safe
end

############################################################################
# Creates filter div for cmsedit index/filter action.
############################################################################
def dc_div_filter()
  choices = []
  filter = (@form['index'] and @form['index']['filter']) ? @form['index']['filter'] + ',' : ''
  filter << 'id as text_field' # filter id is added by default
  filter.split(',').each do |f| 
    f.strip!
    name = f.match(' as ') ? f.split(' ').first : f
# like another field on the form
    if f.match(' like ')
      a = f.split(' ')
      name = a.first
      f    = a.last
    end
    choices << [ t("helpers.label.#{@form['table']}.#{name}", name), f ] 
  end
  choices4_operators = t('drgcms.choices4_filter_operators').chomp.split(',').inject([]) {|r,v| r << (v.match(':') ? v.split(':') : v )}
# currently selected options
  if session[@form['table']] and session[@form['table']][:filter]
    field_name, operators_value, dummy = session[@form['table']][:filter].split("\t")
  else
    field_name, operators_value = nil, nil
  end
  #{ form_tag :table => @form['table'], filter: :on, filter_input: 1, action: :index, method: :post }
  url = url_for(table: @form['table'],form_name: params['form_name'], filter: :on, filter_input: 1, action: :index, controller: :cmsedit)  
  html =<<EOT
  <div id="drgcms_filter" class="div-hidden">
    <h1>#{t('drgcms.filter_set')}</h1>
    
    #{ select(nil, 'filter_field1', options_for_select(choices, field_name), { include_blank: true }) }
    #{ select(nil, 'filter_oper', options_for_select(choices4_operators, operators_value)) }
    <div class="dc-menu">
      <div class="dc-link dc-animate drgcms_popup_submit" data-url="#{url}">#{fa_icon('check-square-o')} #{t('drgcms.filter_on')}</div>
      <div class="dc-link dc-animate">#{dc_link_to('drgcms.filter_off','close', {action: :index, filter: 'off', table: @form['table'], form_name: params['form_name']}) }</div>
    </div>
  </div>
EOT
  html.html_safe
end

############################################################################
# Creates title div for cmsedit index result set records. Title div also includes paging 
# options.
############################################################################
def dc_table_title_for_result(result=nil)
  title = if @form['title'] # form has title section
    t(@form['title'],@form['title'])
  else # get name from translations
    t('helpers.label.' + @form['table'] + '.tabletitle', @form['table'])
  end
  dc_table_title(title, result)
end

############################################################################
# Creates code for link or ajax action type. Subroutine of dc_actions_for_result.
############################################################################
def dc_link_or_ajax(yaml, parms) #:nodoc:
  rest = {}
  rest['method']  = yaml['method'] || yaml['request'] || 'get'
  rest['caption'] = yaml['caption'] || yaml['text']
#  rest['class']   = (yaml['type'] == 'link' ? 'dc-link' : 'dc-link-ajax') + ' dc-animate'
  rest['class']   = 'dc-animate'
  rest['title']   = yaml['title']
  
  dc_deprecate "Form: result_set:action:text directive will be deprecated. Use caption instead of text." if yaml['text']
  if yaml['type'] == 'link'
    dc_link_to(yaml['caption'], yaml['icon'], parms, rest ) 
  else
    rest['data-url'] = url_for(parms)
    rest['class'] << " fa fa-#{yaml['icon']}"
    fa_icon(yaml['icon'], rest ) 
  end
end

############################################################################
# Determines actions and width of actions column
############################################################################
def dc_actions_column()
  actions = @form['result_set']['actions']
# standard actions  
  actions = {'standard' => true} if actions.class == String && actions == 'standard'
  std_actions = {' 2' => 'edit', ' 3' => 'delete'}
  actions.merge!(std_actions) if actions['standard']
#  
  width = @form['result_set']['actions_width'] || 20*actions.size
  [ actions, "<div class=\"actions\" style=\"width: #{width}px;\">" ] 
end

############################################################################
# Creates actions that could be performed on single row of result set.
############################################################################
def dc_actions_for_result(document)
  actions = @form['result_set']['actions']
  return '' if actions.nil? or @form['readonly']
#  
  actions, html = dc_actions_column()
  actions.each do |k,v|
    session[:form_processing] = "result_set:actions: #{k}=#{v}"
    next if k == 'standard' # ignore standard definition
    parms = @parms.clone   
    yaml = v.class == String ? {'type' => v} : v # if single definition simulate type parameter
    html << case
    when yaml['type'] == 'edit' then
      parms['action'] = 'edit'
      parms['id']     = document.id
      dc_link_to( nil, 'pencil lg', parms )
    when yaml['type'] == 'duplicate' then
      parms['id']     = document.id
# duplicate string will be added to these fields.
      parms['dup_fields'] = yaml['dup_fields'] 
      parms['action'] = 'create'
      dc_link_to( nil, 'copy lg', parms, data: { confirm: t('drgcms.confirm_dup') }, method: :post )
    when yaml['type'] == 'delete' then
      parms['action'] = 'destroy'
      parms['id']     = document.id
      dc_link_to( nil, 'remove lg', parms, data: { confirm: t('drgcms.confirm_delete') }, method: :delete )
# undocumented so far
    when yaml['type'] == 'edit_embedded'
      parms['controller'] = 'cmsedit'
      parms['table'] +=  ";#{yaml['table']}"
      parms['ids']   ||= ''
      parms['ids']   +=  "#{document.id};"
      dc_link_to( nil, 'table lg', parms, method: :get )
    when yaml['type'] == 'link' || yaml['type'] == 'ajax' then
      if yaml['url']
        parms['controller'] = yaml['url']
        parms['idr']        = document.id
      else
        parms['id']         = document.id
      end
      parms['controller'] = yaml['controller'] if yaml['controller']
      parms['action']     = yaml['action']     if yaml['action']
      parms['table']      = yaml['table']      if yaml['table']
      parms['form_name']  = yaml['form_name']  if yaml['form_name']
      parms['target']     = yaml['target']     if yaml['target']
      dc_link_or_ajax(yaml, parms)
    else # error. 
      yaml['type'].to_s
    end
  end
  html << '</div>'
  html.html_safe
end

############################################################################
# Creates header div for result set.
############################################################################
def dc_header_for_result()
  html = '<div class="dc-result-header">'
  if @form['result_set']['actions'] and !@form['readonly']
    ignore, code = dc_actions_column()
    html << code + '</div>'
  end
# preparation for sort icon  
  sort_field, sort_direction = nil, nil
  if session[@form['table']]
    sort_field, sort_direction = session[@form['table']][:sort].to_s.split(' ')
  end
#  
  if (columns = @form['result_set']['columns'])
    columns.each do |k,v|
      session[:form_processing] = "result_set:columns: #{k}=#{v}"
#      
      th = %Q[<div class="th" style="width: #{v['width'] || '15%'};text-align: #{v['align'] || 'left'};"]
      v  = {'name' => v} if v.class == String      
      caption = v['caption'] || t("helpers.label.#{@form['table']}.#{v['name']}")
# no sorting when embedded documents or custom filter is active 
      sort_ok = @form['result_set'].nil? || (@form['result_set'] && @form['result_set']['filter'].nil?)
      sort_ok = sort_ok || (@form['index'] && @form['index']['sort'])
      if @tables.size == 1 and sort_ok
        icon = 'sort lg'
        if v['name'] == sort_field
          icon = sort_direction == '1' ? 'sort-alpha-asc lg' : 'sort-alpha-desc lg'
        end        
        th << ">#{dc_link_to(caption, icon, sort: v['name'], table: params[:table], form_name: params[:form_name], action: :index, icon_pos: :last )}</div>"
      else
        th << ">#{caption}</div>"
      end
      html << "<div class=\"spacer\"></div>" + th
    end
  end
  (html << '</div>').html_safe
end

############################################################################
# Creates link for single or double click on result column
############################################################################
def dc_clicks_for_result(document)
  html = ''
  if @form['result_set']['dblclick']
    yaml = @form['result_set']['dblclick']
    opts = {}
    opts[:controller] = yaml['controller'] || 'cmsedit'
    opts[:action]     = yaml['action']
    opts[:table]      = yaml['table']
    opts[:form_name]  = yaml['form_name']
    opts[:method]     = yaml['method'] || 'get'
    opts[:id]         = document['id']
    html << ' data-dblclick=' + url_for(opts) 
  else
     html << (' data-dblclick=' +
       url_for(action: 'show', controller: 'cmsedit', id: document.id, 
       readonly: (params[:readonly] ? 2 : 1), table: params[:table],
       form_name: params[:form_name], ids: params[:ids])  ) if @form['form'] 
  end
  html
end

############################################################################
# Formats value according to format supplied or data type. There is lots of things missing here.
############################################################################
def dc_format_value(value, format=nil)
# :TODO: Enable formating numbers.
  return '' if value.nil?
  klass = value.class.to_s
  case when klass.match('Time') then
    format ||= t('time.formats.default')
    value.strftime(format)  
  when klass.match('Date') then
    format ||= t('date.formats.default')
    value.strftime(format)  
  when format.to_s[0] == 'N' then
    dec = format[1].blank? ? nil : format[1].to_i
    sep = format[2].blank? ? nil : format[2]
    del = format[3].blank? ? nil : format[3]
    cur = format[4].blank? ? nil : format[4]
    dc_format_number(value, dec, sep, del, cur)
  else
    value.to_s
  end
end      

############################################################################
# Defines style or class for row (tr) or column (td)
############################################################################
def dc_style_or_class(selector, yaml, value, record)
  return '' if yaml.nil?
# alias record and value so both names can be used in eval
  field = value
  document = record
  html = selector ? "#{selector}=\"" : ''
  html << if yaml.class == String
    yaml
  else
    (yaml['eval'] ? eval(yaml['eval']) : '') rescue 'background-color:red;'
  end
  html << '"' if selector 
  html
end 

############################################################################
# Creates tr code for each row of result set.
############################################################################
def dc_row_for_result(document)
  clas  = "dc-#{cycle('odd','even')} " + dc_style_or_class(nil, @form['result_set']['tr_class'], nil, document)
  style = dc_style_or_class('style', @form['result_set']['tr_style'], nil, document)
  "<div class=\"dc-result-data #{clas}\" #{dc_clicks_for_result(document)} #{style}>".html_safe
end

############################################################################
# Creates column for each field of result set document.
############################################################################
def dc_columns_for_result(document)
  html = ''  
  return html unless @form['result_set']['columns']
#  
  @form['result_set']['columns'].each do |k,v|
    session[:form_processing] = "result_set:columns: #{k}=#{v}"
# convert shortcut to hash 
    v = {'name' => v} if v.class == String
# eval
    value = if v['eval']
      if v['eval'].match('dc_name4_id')
        a = v['eval'].split(',')
        if a.size == 3
          dc_name4_id(a[1], a[2], nil, document[ v['name'] ])
        else
          dc_name4_id(a[1], a[2], a[3], document[ v['name'] ])
        end
      elsif v['eval'].match('dc_name4_value')
        dc_name4_value( @form['table'], v['name'], document[ v['name'] ] )
      elsif v['eval'].match('eval ')
# evaluate with specified parameters
      else
        if v['params']
          if v['params'] == 'document'     # pass document as parameter when all
            eval( "#{v['eval']} document") 
          else                        # list of fields delimeted by ,
            params = v['params'].chomp.split(',').inject('') do |result,e| 
              result << (e.match(/\.|\:|\(/) ? e : "document['#{e.strip}']") + ','
            end
            params.chomp!(',')
            eval( "#{v['eval']} #{params}") 
          end
        else
          eval( "#{v['eval']} '#{document[ v['name'] ]}'") 
        end
      end
# as field        
    elsif document.respond_to?(v['name'])
      dc_format_value(document.send( v['name'] ), v['format']) 
# as hash (dc_memory)
    elsif document.class == Hash 
      document[ v['name'] ]
# error
    else
      "!!! #{v['name']}"
    end
#
    td = '<div class="spacer"></div><div class="td" '
    td << dc_style_or_class('class', v['td_class'], value, document)

    width_align = %Q[width: #{v['width'] || '15%'};text-align: #{v['align'] || 'left'};]
    style = dc_style_or_class('style', v['td_style'] || v['style'], value, document)
    style = if style.size > 1
      # remove trailing " add width and add trailing " back
      style.delete_suffix('"') + width_align + '"'
    else
      # create style string
      "style=\"#{width_align}\""
    end
    html << "#{td} #{style}>#{value}</div>"
  end
  html.html_safe
end

############################################################################
# Will return value for parameter required on form
############################################################################
def dc_value_for_parameter(param)
  if param.class == Hash
    dc_internal_var(param['object'] || 'record', param['method'])
  else
    param    
  end
end

############################################################################
# Creates actions div for edit form.
# 
# Displaying readonly form turned out to be challenge. For now when readonly parameter
# has value 2, back link will force readonly form. Value 1 or not set will result in
# normal link.
############################################################################
def dc_actions_for_form()
# create standard actions  
  std_actions = {' 1' => 'back', ' 2' => {'type' => 'submit', 'caption' => 'drgcms.save'},
               ' 3' => {'type' => 'submit', 'caption' => 'drgcms.save&back'} }
# when edit only  
  unless @record.id.nil?
    std_actions.merge!({' 6' => 'new'} )
    std_actions.merge!(@record.active ? {' 5' => 'disable'} : {' 5' => 'enable'} ) if @record.respond_to?('active')
    std_actions.merge!({' 7' => 'refresh'} )
  end
  actions = @form['form']['actions']
# shortcut for actions: standard 
  actions = nil if actions.class == String && actions == 'standard'
# standard actions
  actions = std_actions if actions.nil?
# readonly 
  actions = {' 1' => 'back'} if @form['readonly']
# Actions are strictly forbidden 
  if @form['form']['actions'] and dc_dont?(@form['form']['actions'])
    actions = []
  elsif actions['standard']
    actions.merge!(std_actions)
    actions['standard'] = nil
  end
# Update save and save&back
  actions.each do |k,v| 
    if v.class == String 
      if v.match(/save\&back/i)
        actions[k] = {'type' => 'submit', 'caption' => 'drgcms.save&back'}
      elsif v == 'save'
        actions[k] = {'type' => 'submit', 'caption' => 'drgcms.save'}      
      end
    end
  end
# Sort so that standard actions come first
  actions = actions.to_a.sort {|x,y| x[0].to_s <=> y[0].to_s} 
# Add spinner to the beginning
  c = %Q[<span class="dc-spinner div-hidden">#{fa_icon('spinner lg spin')}</span><ul class="dc-menu">]
  
  actions.each do |element|
    session[:form_processing] = "form:actions: #{element}"
    v = element[1]
    next if v.nil?  # yes it happends
    p "Using text option in actions_for form is replaced with caption. Table #{@form['table']}" if v['text']
# on_save_ok should't go inside td tags
    if (element[0] == 'on_save_ok') then
      c << hidden_field_tag(:on_save_ok, v)
      next
    end    
#    
    action_active = !(dc_dont?(v['when_new']) and @record.new_record?)
#    p [v['caption'], action_active]
    parms = @parms.clone
    if v.class == String
      next if params[:readonly] and !(v == 'back')
      
      c << '<li class="dc-link dc-animate">'
      c << case 
        when (v == 'back' or v == 'cancle') then
# If return_to is present link directly to URL        
          if parms['xreturn_to'] # disabled for now
            dc_link_to( 'drgcms.back','arrow-left', parms['return_to'] )
          else
            parms['action'] = 'index'
            parms['readonly'] = parms['readonly'].to_s.to_i < 2 ? nil : 1  
            dc_link_to( 'drgcms.back','arrow-left', parms )
          end
        when v == 'delete' then
          parms['operation'] = v
          parms['id']   = @record.id
          dc_link_to( 'drgcms.delete','remove', parms, data: { confirm: t('drgcms.confirm_delete') }, method: :delete )
        when v == 'new' then
          parms['action'] = v
          dc_link_to( 'drgcms.new', 'plus', parms)
        when (v == 'enable' or v == 'disable') then
          parms['operation'] = v
          parms['id']        = @record.id
          icon = (v == 'enable' ? 'thumbs-o-up' : 'thumbs-o-down')
          dc_link_to( "drgcms.#{v}",icon, parms, method: :delete )
        when v == 'edit' then
          parms['operation'] = v
          parms['id']        = @record.id
          dc_link_to( "drgcms.#{v}",v, parms )
        when v == 'refresh' then
          "<span onclick='window.location.href=window.location.href;'>#{fa_icon('refresh')} #{t('drgcms.refresh')}</span></li>"
      else 
        "err1 #{element[0]}=>#{v}"
      end
      c << '</td>'
    # non standard actions      
    else
      c << case 
      # submit button
      when v['type'] == 'submit'
        caption = v['caption'] || 'drgcms.save'
        icon    = v['icon'] || 'save'
        if action_active 
          '<li class="dc-link-submit dc-animate">' + 
             dc_submit_tag(caption, icon, {:data => v['params'], :title => v['title'] }) +
          '</li>'
        else
          "<li class=\"dc-link-no\">#{fa_icon(icon)} #{caption}</li>"
        end
      
      # delete with some sugar added
      when v['type'] == 'delete'
        parms['id']   = @record.id
        parms.merge!(v['params'])
        caption = v['caption'] || 'drgcms.delete'
        icon = v['icon'] || 'remove'
        '<li class="dc-link dc-animate">' + 
          dc_link_to( caption, icon, parms, data: t('drgcms.confirm_delete'), method: :delete ) +
        '</li>'
      
      # ajax or link button
      when v['type'] == 'ajax' || v['type'] == 'link' || v['type'] == 'window'
        parms = {}
        # direct url        
        if v['url']
          parms['controller'] = v['url'] 
          parms['idr']        = dc_document_path(@record)
        # make url from action controller
        else
          parms['controller'] = v['controller'] 
          parms['action']     = v['action'] 
          parms['table']      = v['table'] 
          parms['form_name']  = v['form_name']
        end
        # add current id to parameters
        parms['id'] = dc_document_path(@record)
        # additional parameters          
        v['params'].each { |k,v| parms[k] = dc_value_for_parameter(v) } if v['params']
        # Error if controller parameter is missing
        if parms['controller'].nil?
          "<li>#{t('drgcms.error')}</li>"
        else
          v['caption'] ||= v['text'] 
          caption = t("#{v['caption'].downcase}", v['caption'])
          #
          url = url_for(parms) rescue ''
          request = v['request'] || v['method'] || 'get'
          icon    = v['icon'] ? "#{fa_icon(v['icon'])} " : ''
          if v['type'] == 'ajax' # ajax button
            clas = action_active ? "dc-link-ajax dc-animate" : "dc-link-no"
            %Q[<li class="#{clas}" data-url="#{action_active ? url : ''}" 
               data-request="#{request}" title="#{v['title']}">#{icon}#{caption}</li>]
          elsif v['type'] == 'link'  # link button
            clas = action_active ? "dc-link dc-animate" : "dc-link-no"
            %Q[<li class="#{clas}">#{action_active ? dc_link_to(v['caption'],v['icon'], parms, {target: v['target']} ) : caption}</li>]
          elsif v['type'] == 'window' 
            clas = action_active ? "dc-link dc-animate dc-window-open" : "dc-link-no"
            %Q[<li class="#{clas}" data-url="#{action_active ? url : ''}">#{icon}#{caption}</li>]
          else 
            'Action Type error'
          end
        end
        
# Javascript action        
      when v['type'] == 'script'
#          v['caption'] ||= 'Caption missing!'
#          caption = t("#{v['caption'].downcase}", v['caption'])
          data = {'request' => 'script', 'script' => v['js']}
         %Q[<li class="dc-link-ajax dc-animate">#{ dc_link_to(v['caption'],v['icon'], '#', data: data ) }</li>]
      else
        '<li>err2</li>'
      end
    end
  end
  (c << '</ul>').html_safe
end

############################################################################
# Create background div and table definitions for result set.
############################################################################
def dc_background_for_result(start)
  if start == :start
    html = '<div class="dc-result-div" ' 
    html << (@form['result_set']['table_style'] ? 'style="overflow-x: scroll;" >' : '>')
  #
    html << "\n<div class=\"dc-result #{@form['result_set']['table_class']}\" "
    html << (@form['result_set']['table_style'] ? "style=\"#{@form['result_set']['table_style']}\" >" : '>')
  else
    html = '</div></div>'
  end
  html.html_safe
end

############################################################################
# Checks if value is defined and sets default. If values are sent it also checks
# if value is found in values. If not it will report error and set value to default.
# Subroutine of dc_fields_for_tab.
############################################################################
def dc_check_and_default(value, default, values=nil) #:nodoc:
  return default if value.nil?
# check if value is within allowed values  
  if values
    if !values.index(value) 
# parameters should be in downcase. Check downcase version.
      if n = values.index(value.downcase)
        return values[n]
      else
        logger.error("DRG Forms: Value #{value} not within values [#{values.join(',')}]. Default #{default} used!")
        return default
      end
    end
  end
  value
end

############################################################################
# Creates top or bottom horizontal line on form. 
############################################################################
def top_bottom_line(yaml, columns=2)
  '<div class="dc-separator"></div>'
end    

############################################################################
# Creates input fields for one tab. Subroutine of dc_fields_for_form.
############################################################################
def dc_fields_for_tab(fields_on_tab) #:nodoc:
  @js      ||= ''
  html       = '<div class="dc-form">'
  labels_pos = dc_check_and_default(@form['form']['labels_pos'], 'right', ['top','left','right'])
  hidden_fields  = ''
  odd_even       = nil
  group_option, group_count = 0, 0
  reset_cycle()
# options and fields must be separated before sorting  
#  form_options = fields.select {|field| field.class != Integer }
#  columns      = form_options.try(:[],'columns') || 1
# Select form fields and sort them by key
  form_fields  = fields_on_tab.select {|field| field.class == Integer }
  form_fields.to_a.sort.each do |element|
    options = element.last
    session[:form_processing] = "form:fields: #{element.first}=#{options}"
# ignore if edit_only singe field is required
    next if params[:edit_only] and params[:edit_only] != options['name'] 
# hidden_fields. Add them at the end
    if options['type'] == 'hidden_field'
      hidden_fields << DrgcmsFormFields::HiddenField.new(self, @record, options).render
      next
    end
# label
    text = if options['text']
      t(options['text'], options['text'])
    elsif options['name']
      t_name(options['name'], options['name'].capitalize.gsub('_',' ') )
    end
# help text can be defined in form or in translations starting with helpers. or as helpers.help.collection.field
    help = if options['help'] 
      options['help'].match('helpers.') ? t(options['help']) : options['help']
    end
    help ||= t('helpers.help.' + @form['table'] + '.' + options['name'],' ') if options['name'] 
# create field object from class and call its render method
    klas_string = options['type'].camelize
    field_html = if DrgcmsFormFields.const_defined?(klas_string) # check if field type is defined
      klas = DrgcmsFormFields.const_get(klas_string)
      field = klas.new(self, @record, options).render
      @js << field.js
      field.html 
    else # litle error string
      "Error: Code for field type #{options['type']} not defined!"
    end
# Line separator
    html << top_bottom_line(options['top-line']) if options['top-line']
# Begining of new row
    if group_count == 0
      html << '<div class="row-div">' 
      odd_even = cycle('odd','even')
      group_count  = options['group'] || 1 
      group_option = options['group'] || 1 
    end
#    
    html << if labels_pos == 'top'
%Q[
<div class="dc-form-label-top dc-color-#{odd_even} dc-align-left" title="#{help}">
  <label for="record_#{options['name']}">#{text} </label>
  <div id="td_record_#{options['name']}">#{field_html}</div>
</div> ]
    else
      label_width = 14
      # less place for label when more then 1 field per row
      label_width = 10 if group_option > 1 and group_option != group_count
      data_width  = (94 - 10*group_option)/group_option
%Q[
<div class="dc-form-label dc-color-#{odd_even} dc-align-#{labels_pos}" style="width:#{label_width}%;" title="#{help}">
  <label for="record_#{options['name']}">#{text} </label>
</div>
<div id="td_record_#{options['name']}" class="dc-form-field dc-color-#{odd_even}" style="width:#{data_width}%;">#{field_html}</div>
]
    end
# check if must go to next row
    group_count -= 1
    html << '</div>' if group_count == 0
    html << top_bottom_line(options['bottom-line']) if options['bottom-line']
  end
  html << '</div>' << hidden_fields
end

############################################################################
# Creates edit form div. 
############################################################################
def dc_fields_for_form()
  html, tabs, tdata = '',[], ''
# Only fields defined  
  if (form_fields = @form['form']['fields'])
    html << "<div id='data_fields' " + (@form['form']['height'] ? "style=\"height: #{@form['form']['height']}px;\">" : '>')  
    html << dc_fields_for_tab(form_fields) + '</div>'
  else
# there are multiple tabs on form 
    first = true # first tab 
    @form['form']['tabs'].keys.sort.each do |tabname|
      next if tabname.match('actions')
# Tricky. If field name is not on the tab skip to next tab
      if params[:edit_only]
        is_on_tab = false
        @form['form']['tabs'][tabname].each {|k,v| is_on_tab = true if params[:edit_only] == v['name'] }
        next unless is_on_tab
      end
# first div is displayed all other are hidden      
      tdata << "<div id='data_#{tabname.delete("\s\n")}'"
      tdata << ' class="div-hidden"' unless first
      tdata << " style=\"height: #{@form['form']['height']}px;\"" if @form['form']['height']
      tdata << ">#{dc_fields_for_tab(@form['form']['tabs'][tabname])}</div>"
      tabs << tabname
      first = false      
    end
# make it all work together
    html << '<ul class="dc-form-ul" >'
    first = true # first tab must be selected
    tabs.each do |tab| 
      html << "<li id='li_#{tab}' data-div='#{tab.delete("\s\n")}' class='dc-form-li #{'dc-form-li-selected' if first }'>#{t_name(tab, tab)}</li>" 
      first = false
    end
    html << '</ul>'
    html << tdata
  end
  # add last_updated_at hidden field so controller can check if record was updated in during editing
  html << hidden_field(nil, :last_updated_at, value: @record.updated_at.to_i) if @record.respond_to?(:updated_at)
  # add form time stamp to prevent double form submit
  html << hidden_field(nil, :form_time_stamp, value: Time.now.to_i)
  html.html_safe
end

############################################################################
# Returns username for id. Subroutine of dc_document_statistics
############################################################################
def _get_user_for(field_name) #:nodoc:
  if @record[field_name]
    u = DcUser.find(@record[field_name])
    return u ? u.name : @record[field_name]
  end
#  nil
end

############################################################################
# Creates current document statistics div (created_by, created_at, ....) at the bottom of edit form.
# + lots of more. At the moment also adds icon for dumping current document as json text.
############################################################################
def dc_document_statistics
  return '' if @record.new_record? or dc_dont?(@form['form']['info'])
  html =  %Q[<div id="dc-document-info">#{fa_icon('info-circle lg')}</div> <div id="dc-document-info-popup" class="div-hidden"> ]
#
  u = _get_user_for('created_by')
  html << %Q[<div><span>#{t('drgcms.created_by', 'Created by')}: </span><span>#{u}</span></div>] if u
  u = _get_user_for('updated_by')
  html << %Q[<div><span>#{t('drgcms.updated_by', 'Updated by')}: </span><span>#{u}</span></div>] if u
  html << %Q[<div><span>#{t('drgcms.created_at', 'Created at')}: </span><span>#{dc_format_value(@record.created_at)}</span></div>] if @record['created_at']
  html << %Q[<div><span>#{t('drgcms.updated_at', 'Updated at')}: </span><span>#{dc_format_value(@record.updated_at)}</span></div>] if @record['updated_at']
# copy to clipboard icon
  parms = params.clone
  parms[:controller] = 'dc_common'
  parms[:action]     = 'copy_clipboard'
  url = url_for(parms.permit!)
  html << fa_icon('copy 2x', class: 'dc-link-img dc-link-ajax dc-animate', 
                  'data-url' => url, 'data-request' => 'get', title: t('drgcms.doc_copy_clipboard') )
  (html << '</div></div>').html_safe
end

end
