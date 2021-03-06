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
module CmsIndexHelper
  
############################################################################
# Creates action div for cmsedit index action. 
############################################################################
def dc_actions_for_index()
  @js  = @form['script'] || @form['js'] || ''
  @css = @form['css'] || ''
  return '' if @form['index'].nil? or @form['readonly']
  actions = @form['index']['actions']
  return '' if actions.blank?
  
  std_actions = {2 => 'new', 3 => 'sort', 4 => 'filter' }
  if actions.class == String
    actions = dc_define_standard_actions(actions, std_actions)
  elsif actions['standard']
    actions.merge!(std_actions)
    actions['standard'] = nil
  end
  
  # start div with hidden spinner image
  html = %(
<form id="dc-action-menu">
  <span class="dc-spinner">#{fa_icon('spinner lg spin')}</span>
  <ul class="dc-action-menu">)

  # Remove actions settings and sort
  only_actions = []
  actions.each { |key, value| only_actions << [key, value] if key.class == Integer }
  only_actions.sort_by!(&:first)
  only_actions.each do |key, options|
    session[:form_processing] = "index:actions: #{key}=#{options}"
    next if options.nil? # must be
    url = @parms.clone
    yaml = options.class == String ? {'type' => options} : options # if single definition simulate type parameter
    action = yaml['type'].to_s.downcase 
    if action == 'url'
      dc_deprecate "action: url will be deprecated. Use action: link in index: actions! Form #{params['form_name']}"
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
      url['control']    = yaml['control'] if yaml['control']
    end
    # html link options
    yhtml = yaml['html'] || {}
    yhtml['title'] = yaml['title'] if yaml['title']

    code = case
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
              { class: 'drgcms_sort', 'data-table' => @form['table'], 'data-form' => params['form_name']} )

    # filter
    when action == 'filter' then 
      caption = t('drgcms.filter')
      caption << '&nbsp;' + fa_icon('caret-down lg') + DcFilter.menu_filter(self)
      # add filter OFF link
      sess = session[@form['table']]
      if sess and sess[:filter]
        caption << '&nbsp;&nbsp;' + dc_link_to(nil,'remove lg',
                   { controller: 'cmsedit', filter: 'off', table: @form['table'], form_name: params['form_name'] },
                   { title: DcFilter.title4_filter_off(sess[:filter]) })
      end
      caption

    # new
    when action == 'new' then 
      caption = yaml['caption'] || 'drgcms.new'
      dc_link_to(caption,'plus', url, yhtml )

    # menu
    when action == 'menu' then  
      caption = t(options['caption'], options['caption']) + '&nbsp;' + fa_icon('caret-down lg')
      caption + eval(options['eval'])      
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
    when action == 'script'
      html << dc_script_action(options)
      next

    when action == 'field'
      html << dc_field_action(yaml) 
      next 

    when %w(ajax link window submit).include?(action)
      html << dc_link_ajax_window_submit_action(options, nil)
      next

    else
      caption = yaml['caption'] || yaml['text']
      icon    = yaml['icon'] ? yaml['icon'] : action
      dc_link_to(caption, icon, url, yhtml)
    end
    html << "<li class=\"dc-link dc-animate\">#{code}</li>"
    html << DcFilter.get_filter_field(self) if action == 'filter'
  end
  html << '</ul></form>'
  html.html_safe
end

############################################################################
# Creates filter div for cmsedit index/filter action.
############################################################################
def dc_div_filter
  choices = []
  filter = (@form['index'] and @form['index']['filter']) ? @form['index']['filter'] + ',' : ''
  filter << 'id as text_field' # filter id is added by default
  filter.split(',').each do |f| 
    f.strip!
    name = f.match(' as ') ? f.split(' ').first : f
    # like another field on the form
    if f.match(' like ')
      a    = f.split(' ')
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
# Creates popup div for setting filter on result set header.
############################################################################
def dc_filter_popup
  html = %Q[<div class="filter-popup" style="display: none;">
  <div>#{t('drgcms.filter_set')}</div>
  <ul>]
  url = url_for(table: @form['table'],form_name: params['form_name'], filter: :on, filter_input: 1, action: :index, controller: :cmsedit)
  t('drgcms.choices4_filter_operators').chomp.split(',').each do |operator_choice|
    caption,choice = operator_choice.split(':') 
    html << %Q[<li data-operator="#{choice}" data-url="#{url}">#{caption}</li>]
  end 
  html << "</ul></div>"
  html.html_safe
end

############################################################################
# Creates title div for cmsedit index result set records. Title div also includes paging 
# options.
############################################################################
def dc_table_title_for_result(result=nil)
  title = if @form['title'] # form has title section
    if @form['title'].class == Hash
      dc_process_eval(@form['title']['eval'], [@form['title']['caption'] || @form['title']['text'], params])
    else
      t(@form['title'], @form['title'])
    end
  else # get name from translations
    t("helpers.label.#{@form['table']}.tabletitle", @form['table'])
  end
  dc_table_title(title, result)
end

############################################################################
# Determines actions and width of actions column
############################################################################
def dc_actions_column
  actions = @form['result_set']['actions']
  return [{}, 0] if actions.nil? || dc_dont?(actions)

  # standard actions
  actions = {'standard' => true} if actions.class == String && actions == 'standard'
  std_actions = { 2 => 'edit', 5 => 'delete' }
  if actions['standard']
    actions.merge!(std_actions) 
    actions.delete('standard')
  end

  width = @form['result_set']['actions_width'] || 18*actions.size
  [actions, width]
end

############################################################################
# Calculates (blank) space required for actions when @record_footer is rendered 
############################################################################
def dc_actions_column_for_footer
  return '' unless @form['result_set']['actions']

  ignore, width = dc_actions_column
  %Q[<div class="actions" style="width: #{width}px;"></div>].html_safe
end

############################################################################
# Creates actions that could be performed on single row of result set.
############################################################################
def dc_actions_for_result(document)
  actions = @form['result_set']['actions']
  return '' if actions.nil? or @form['readonly']

  actions, width = dc_actions_column()
  html = %Q[<ul class="actions" style="width: #{width}px;">]
  actions.sort_by(&:first).each do |k, v|
    session[:form_processing] = "result_set:actions: #{k}=#{v}"
    parms = @parms.clone
    # if single definition simulate type parameter
    yaml = v.class == String ? { 'type' => v } : v
    # code already includes li tag
    if %w(ajax link window submit).include?(yaml['type']) then
      @record = document # otherwise document fields can't be used as parameters
      html << dc_link_ajax_window_submit_action(yaml, document)
    else
      html << '<li class="dc-link">'
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
        parms['return_to'] = request.url
        dc_link_to( nil, 'remove lg', parms, data: { confirm: t('drgcms.confirm_delete') }, method: :delete )
      # undocumented so far
      when yaml['type'] == 'edit_embedded'
        parms['controller'] = 'cmsedit'
        parms['table'] +=  ";#{yaml['table']}"
        parms['ids']   ||= ''
        parms['ids']   +=  "#{document.id};"
        dc_link_to( nil, 'table lg', parms, method: :get )
    
      else # error. 
        yaml['type'].to_s
      end
      html << '</li>'
    end
  end
  html << '</ul>'
  html.html_safe
end

############################################################################
# Creates header div for result set.
############################################################################
def dc_header_for_result()
  html = '<div class="dc-result-header">'
  if @form['result_set']['actions'] and !@form['readonly']
    ignore, width = dc_actions_column()
    html << %Q[<div class="actions" style="width:#{width}px;"></div>]
  end
  # preparation for sort icon  
  sort_field, sort_direction = nil, nil
  if session[@form['table']]
    sort_field, sort_direction = session[@form['table']][:sort].to_s.split(' ')
  end

  if (columns = @form['result_set']['columns'])
    columns.sort.each do |k, v|
      session[:form_processing] = "result_set:columns: #{k}=#{v}"
      next if v['width'].to_s.match(/hidden|none/i)

      th = %Q[<div class="th" style="width:#{v['width'] || '15%'};text-align:#{v['align'] || 'left'};" data-name="#{v['name']}"]
      label = v['caption'] || v['label']
      label = (v['name'] ? "helpers.label.#{@form['table']}.#{v['name']}" : '') if label.nil?
      label = t(label) if label.match(/helpers\./)
      # no sorting when embedded documents or custom filter is active 
      sort_ok = @form['result_set'].nil? || (@form['result_set'] && @form['result_set']['filter'].nil?)
      sort_ok = sort_ok || (@form['index'] && @form['index']['sort'])
      sort_ok = sort_ok && !dc_dont?(v['sort'], false)
      if @tables.size == 1 and sort_ok
        icon = 'sort lg'
        if v['name'] == sort_field
          icon = sort_direction == '1' ? 'sort-alpha-asc lg' : 'sort-alpha-desc lg'
        end        
        th << ">#{dc_link_to(label, icon, sort: v['name'], table: params[:table], form_name: params[:form_name], action: :index, icon_pos: :last )}</div>"
      else
        th << ">#{label}</div>"
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
    opts[:readonly]   = yaml['readonly'] if yaml['readonly']
    opts[:window_close] = yaml['window_close'] if yaml['window_close']
    html << ' data-dblclick=' + url_for(opts) 
  else
     html << (' data-dblclick=' +
                url_for(action: 'show', controller: 'cmsedit', id: document.id, ids: params[:ids],
                        readonly: (params[:readonly] ? 2 : 1), table: params[:table],
                        form_name: params[:form_name]) ) if @form['form']
  end
  html
end

############################################################################
# Formats value according to format supplied or data type. There is lots of things missing here.
############################################################################
def dc_format_value(value, format=nil)
  return '' if value.nil?

  klass = value.class.to_s
  if klass.match(/time|date/i)
    CmsCommonHelper.dc_format_date_time(value, format)
  elsif format.to_s[0] == 'N'
    return '' if value == 0 and format.match('z')

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
# Creates tr code for each row of result set.
############################################################################
def dc_row_for_result(document)
  clas  = "dc-#{cycle('odd','even')} " + dc_style_or_class(nil, @form['result_set']['tr_class'], nil, document)
  style = dc_style_or_class('style', @form['result_set']['tr_style'], nil, document)
  "<div  id=\"#{document.id}\" class=\"dc-result-data #{clas}\" #{dc_clicks_for_result(document)} #{style}>".html_safe
end

############################################################################
# Creates column for each field of result set document.
############################################################################
def dc_columns_for_result(document)
  return '' unless @form['result_set']['columns']
  html = ''  
  @form['result_set']['columns'].sort.each do |k,v|
    session[:form_processing] = "result_set:columns: #{k}=#{v}"
    next if v['width'].to_s.match(/hidden|none/i)

    # convert shortcut to hash 
    v = {'name' => v} if v.class == String    
    begin
      # eval
      value = if v['eval']
        dc_process_column_eval(v, document)
      # as field        
      elsif document.respond_to?(v['name'])
        dc_format_value(document.send( v['name'] ), v['format']) 
      # as hash (dc_memory)
      elsif document.class == Hash 
        dc_format_value(document[ v['name'] ], v['format'])
      # error
      else
        "??? #{v['name']}"
      end
    rescue Exception => e
      dc_log_exception(e)
      value = '!!!Error'
    end
    html << '<div class="spacer"></div>'
    # set class
    clas = dc_style_or_class(nil, v['td_class'], value, document)
    # set width and align an additional style
    style = dc_style_or_class(nil, v['td_style'] || v['style'], value, document)
    flex_align  = v['align'].to_s == 'right' ? 'flex-direction:row-reverse;' : ''
    width_align = %Q[width:#{v['width'] || '15%'};#{flex_align}]
    style = "style=\"#{width_align}#{style}\" "

    html << "<div class=\"td #{clas}\" #{style}>#{value}</div>"
  end
  html.html_safe
end

private

############################################################################
# Process eval. Breaks eval option and calls with send method.
# Parameters:
#   evaluate : String : Expression to be evaluated
#   parameters : Array : array of parameters which will be send to method
############################################################################
def dc_process_eval(evaluate, parameters)
  # evaluate by calling send method 
  clas, method = evaluate.split('.')
  if method.nil?
    send(clas, *parameters)
  else
    klass = clas.camelize.constantize
    klass.send(method, *parameters)
  end  
end

############################################################################
# Split eval expression to array by parameters.
# Will split dc_name4_value(one ,"two") => ['dc_name4_value', 'one', 'two']
############################################################################
def dc_eval_to_array(expression)
  expression.split(/\ |\,|\(|\)/).delete_if {|e| e.blank? }.map {|e| e.gsub(/\'|\"/,'').strip }
end

############################################################################
# Process eval option for field value. 
# Used for processing single field column on result_set or form head.
############################################################################
def dc_process_column_eval(yaml, document)
  # dc_name_for_id
  if yaml['eval'].match(/dc_name4_id|dc_name_for_id/)
    parms = dc_eval_to_array(yaml['eval'])
    if parms.size == 3
      dc_name_for_id(parms[1], parms[2], nil, document[ yaml['name'] ])
    else
      dc_name_for_id(parms[1], parms[2], parms[3], document[ yaml['name'] ])
    end

  # dc_name_for_value from locale definition
  elsif yaml['eval'].match(/dc_name4_value|dc_name_for_value/)
    parms = dc_eval_to_array(yaml['eval'])
    if parms.size == 1
      dc_name_for_value( @form['table'], yaml['name'], document[ yaml['name'] ] )
    else
      dc_name_for_value( parms[1], parms[2], document[ yaml['name'] ] )
    end

  # defined in helpers. For example dc_icon_for_boolean
  elsif respond_to?(yaml['eval'])
    send(yaml['eval'], document[yaml['name']])

  # defined in model
  elsif document.respond_to?(yaml['eval'])
    document.send(yaml['eval'])

  # special eval  
  elsif yaml['eval'].match('eval ')
  # TO DO evaluate with specified parameters

  # eval with params
  else
    parms = {}
    if yaml['params'].class == String
      parms = dc_value_for_parameter(yaml['params'], document)
    elsif yaml['params'].class == Hash
      yaml['params'].each { |k, v| parms[k] = dc_value_for_parameter(v) }
    else
      parms = document[ yaml['name'] ]
    end
    dc_process_eval(yaml['eval'], parms)
  end
end

############################################################################
# Defines style or class for row (tr) or column (td)
############################################################################
def dc_style_or_class(selector, yaml, value, record)
  return '' if yaml.nil?

  # alias record and value so both names can be used in eval
  field, document = value, record
  html = selector ? "#{selector}=\"" : ''
  html << if yaml.class == String
    yaml
  # direct evaluate expression
  elsif yaml['eval']
    eval(yaml['eval']) rescue 'background-color:red;'
  elsif yaml['method']
    dc_process_eval(yaml['method'], record)
  end
  html << '"' if selector 
  html
end 

############################################################################
# Get standard actions when actions directive contains single line.
# Subroutine of dc_actions_for_index
# 
# Allows for actions: new, filter, standard syntax
############################################################################
def dc_define_standard_actions(actions_params, standard)
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

end
