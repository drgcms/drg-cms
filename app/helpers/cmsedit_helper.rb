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
# Creates action div for cmsedit index action. 
############################################################################
def dc_actions_for_index()
  return '' if @form['index'].nil? or @form['readonly']
  actions = @form['index']['actions']
  return '' if actions.nil? or actions.size == 0
# Simulate standard actions  
  actions = {'standard' => true} if actions.class == String && actions == 'standard'
  std_actions = {' 2' => 'new', ' 3' => 'sort', ' 4' => 'filter' }
  if actions['standard']
    actions.merge!(std_actions)
    actions['standard'] = nil
  end
# start div with hidden spinner image 
  html = <<EOT
<div id="dc-action-menu">
  <span id="dc-spinner" class="div-hidden">#{fa_icon('spinner lg spin')}</span>
  <ul class="dc-action-menu">
EOT
#
  actions.each do |k,v|
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
      url['formname']   = yaml['formname'] if yaml['formname']
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
# add check image, so user will know that filter is active
      s = session[@form['table']]
      caption << ('&nbsp;' << fa_icon('check')) if s and s[:filter]
      caption
# new
    when action == 'new' then 
      caption = yaml['caption'] || 'drgcms.new'
      dc_link_to(caption,'plus', url, yhtml )
# menu      
    when action == 'menu' then  
      caption = t(v['caption'], v['caption']) + '&nbsp;' + fa_icon('caret-down lg')
      caption + eval(v['eval'])      
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
  url = url_for(:table => @form['table'], filter: :on, filter_input: 1, action: :index, controller: :cmsedit)  
  html =<<EOT
  <div id="drgcms_filter" class="div-hidden">
    <table class="dc-menu"><td>
    #{ select(nil, 'filter_field', options_for_select(choices, field_name), { include_blank: true }) }
    #{ select(nil, 'filter_oper', options_for_select(choices4_operators, operators_value)) }

      </td>
      <td class="dc-link dc-animate drgcms_popup_submit" data-url="#{url}">#{fa_icon('check-square-o')} #{t('drgcms.filter_on')}</td>
      <td class="dc-link dc-animate">#{dc_link_to('drgcms.filter_off','close', {action: 'index', filter: 'off', :table => @form['table']}) }</td>
    </table>
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
  rest['class']   =  rest['class'].to_s + ' dc-animate'
  rest['title']   = yaml['title']
  
  dc_deprecate "Form: result_set:action:text directive will be deprecated. Use caption instead of text." if yaml['text']
  if yaml['type'] == 'link'
    dc_link_to(yaml['caption'], yaml['icon'], parms, rest ) 
  else
    ''
  end
end

############################################################################
# Creates actions that could be performed on single row of result set.
############################################################################
def dc_actions_for_result(document)
  actions = @form['result_set']['actions']
  return '' if actions.nil? or @form['readonly']
# standard actions  
  actions = {'standard' => true} if actions.class == String && actions == 'standard'
  std_actions = {' 2' => 'edit', ' 3' => 'delete'}
  actions.merge!(std_actions) if actions['standard']
#  
  width = @form['result_set']['actions_width'] || 20*actions.size
  html = "<td style=\"width: #{width}px;\">"
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
      parms['formname']   = yaml['formname']   if yaml['formname']
      parms['target']     = yaml['target']     if yaml['target']
      dc_link_or_ajax(yaml, parms)
    else # error. 
      yaml['type'].to_s
    end
  end
  html << '</td>'
  html.html_safe
end

############################################################################
# Creates header div for result set.
############################################################################
def dc_header_for_result()
  c = ''
  actions = @form['result_set']['actions']
  c = '<th>&nbsp;</th>' unless actions.nil?  or @form['readonly']
# preparation for sort icon  
  sort_field, sort_direction = nil, nil
  if session[@form['table']]
    sort_field, sort_direction = session[@form['table']][:sort].to_s.split(' ')
  end
#  
  if (columns = @form['result_set']['columns'])
    columns.each do |k,v|
      session[:form_processing] = "result_set:columns: #{k}=#{v}"
      th = '<th '
      v = {'name' => v} if v.class == String      
      caption = v['caption'] || t("helpers.label.#{@form['table']}.#{v['name']}")
# no sorting when embedded field or custom filter is active
      if @tables.size == 1 and @form['result_set']['filter'].nil?
        icon = 'sort lg'
        if v['name'] == sort_field
          icon = sort_direction == '1' ? 'sort-alpha-asc lg' : 'sort-alpha-desc lg'
        end        
        th << ">#{dc_link_to(caption, icon, sort: v['name'], table: @tables[0][1], action: :index )}</th>"
      else
        th << ">#{caption}</th>"
      end
      c << th
    end
  end
  c.html_safe
end

############################################################################
# Creates div with documents of current result set.
############################################################################
def dc_clicks_for_result(document)
  html = ''
  if @form['result_set']['dblclick']
    yaml = @form['result_set']['dblclick']
    opts = {}
    opts[:controller] = yaml['controller'] || 'cmsedit'
    opts[:action]     = yaml['action']
    opts[:table]      = yaml['table']
    opts[:formname]   = yaml['formname']
    opts[:method]     = yaml['method'] || 'get'
    opts[:id]         = document['id']
    html << ' data-dblclick=' + url_for(opts) 
  else
     html << (' data-dblclick=' +
       url_for(action: 'show', controller: 'cmsedit', id: document, 
       readonly: (params[:readonly] ? 2 : 1), table: params[:table],
       formname: params[:formname], ids: params[:ids])  ) if @form['form'] 
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
  if klass.match('Time')
    format ||= t('time.formats.default')
    value.strftime(format)  
  elsif klass.match('Date')
    format ||= t('date.formats.default')
    value.strftime(format)  
  else
    value.to_s
  end
end      

############################################################################
# Defines style or class for row (tr) or column (td)
############################################################################
def dc_style_or_class(selector, yaml, value, record)
  return '' if yaml.nil?
# alias record and value so both names can be used  
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
  clas  = "dc-#{cycle('odd','even')} " + dc_style_or_class(nil,@form['result_set']['tr_class'],nil,document)
  style = dc_style_or_class('style',@form['result_set']['tr_style'],nil,document)
  "<tr class=\"#{clas}\" #{dc_clicks_for_result(document)} #{style}>".html_safe
end

############################################################################
# Creates column for each field of result set document.
############################################################################
def dc_columns_for_result(document)
  html = ''  
  if (columns = @form['result_set']['columns'])
    columns.each do |k,v|
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
# as hash (dc_dummy)
      elsif document.class == Hash 
        document[ v['name'] ]
# error
      else
        "!!! #{v['name']}"
      end
#
      td = '<td '
      td << dc_style_or_class('class',v['td_class'],value,document)
      td << dc_style_or_class('style',v['td_style'] || v['style'],value,document)
      html << "#{td}>#{value}</td>"
    end
  end
  html.html_safe
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
  c = %Q[<td id="dc-spinner" class="div-hidden">#{fa_icon('spinner lg spin')}</td>]
  
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
    parms = @parms.clone
    if v.class == String
      next if params[:readonly] and !(v == 'back')
      
      c << '<td class="dc-link dc-animate">'
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
        '<td class="dc-link-submit dc-animate">' + 
          dc_submit_tag(caption, icon, {:data => v['params'], :title => v['title']}) + 
        '</td>'
# delete with some sugar added
      when v['type'] == 'delete'
        parms['id']   = @record.id
        parms.merge!(v['params'])
        caption = v['caption'] || 'drgcms.delete'
        icon = v['icon'] || 'remove'
        '<td class="dc-link dc-animate">' + 
          dc_link_to( caption, icon, parms, data: t('drgcms.confirm_delete'), method: :delete ) +
        '</td>'
# ajax or link button
      when v['type'] == 'ajax' || v['type'] == 'link'
        parms = {}
  # direct url        
        if v['url']
          parms['controller'] = v['url'] 
          parms['idr']        = @record.id
  # make url          
        else
          parms['controller'] = v['controller'] 
          parms['action']     = v['action'] 
          parms['table']      = v['table'] 
          parms['formname']   = v['formname'] 
          parms['id']         = @record.id
  # additional parameters          
          v['params'].each { |k,v| parms[k] = v } if v['params']
        end
  # Error if controller param is missing
        if parms['controller'].nil?
          "<td>#{t('drgcms.error')}</td>"
        else
          v['caption'] ||= v['text'] 
          caption = t("#{v['caption'].downcase}", v['caption'])
          url     = url_for(parms)
          p url
          request = v['request'] || v['method'] || 'get'
          icon    = v['icon'] ? "#{fa_icon(v['icon'])} " : ''
          if v['type'] == 'ajax' # ajax button
            %Q[<td class="dc-link-ajax dc-animate" id="dc-submit-ajax" data-url="#{url}" 
               data-request="#{request}" title="#{v['title']}">#{icon}#{caption}</td>]
          else                   # link button
#            %Q[<td class="dc-link dc-animate" title="#{v['title']}><a href="#{url}">#{icon}#{caption}</a></td>]
            %Q[<td class="dc-link dc-animate">#{dc_link_to(v['caption'],v['icon'], parms)}</td>]
          end
        end
# Javascript action        
      when v['type'] == 'script'
#          v['caption'] ||= 'Caption missing!'
#          caption = t("#{v['caption'].downcase}", v['caption'])
          data = {'request' => 'script', 'script' => v['js']}
         %Q[<td class="dc-link-ajax dc-animate">#{ dc_link_to(v['caption'],v['icon'], '#', data: data ) }</td>]
      else
        '<td>err2</td>'
      end
    end
  end
  c.html_safe
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
def top_bottom_line(yaml)
  if  yaml.class == Hash 
    clas  = yaml['class'] 
    style = yaml['style'] 
  end
  clas ||= 'dc-separator'
  "<tr><td colspan=\"4\" class=\"#{clas}\" style=\"#{style}\"></td></tr>"
end    

############################################################################
# Creates input field for one tab. Subroutine of dc_fields_for_form.
############################################################################
def dc_fields_for_tab(fields) #:nodoc:
  @js ||= ''
  double_field = 0
  html = '<table class="dc-form-table">'
  labels_pos = dc_check_and_default(@form['form']['labels_pos'], 'right', ['top','left','right'])
  reset_cycle()
# sort fields by name  
  fields.to_a.sort.each do |element|
    options = element.last
    session[:form_processing] = "form:fields: #{element.first}=#{options}"
# ignore if edit_only singe field is required
    next if params[:edit_only] and params[:edit_only] != options['name'] 
# hidden_fields. Ignore description text, otherwise it will be seen on screen
    if options['type'] == 'hidden_field'
      html << DrgcmsFormFields::HiddenField.new(self, @record, options).render
      next
    end
# label
    text = if options['text']
      t(options['text'], options['text'])
    else
      t_name(options['name'], options['name'].capitalize.gsub('_',' ') )
    end
#    options['text'] ||= options['name'].capitalize.gsub('_',' ')
#    text = options['text'].match('helpers.') ? t(options['text']) : t_name(options['name'], options['text']) 
# help text can be defined in form or in translations starting with helpers. or as helpers.help.collection.field
    help = if options['help'] 
      options['help'].match('helpers.') ? t(options['help']) : options['help']
    end
    help ||= t('helpers.help.' + @form['table'] + '.' + options['name'],' ')    
    odd_even = cycle('odd','even')
    odd_even = cycle('odd','even') if double_field == 2 # it should be same style as first
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
# Separator
    html << top_bottom_line(options['top-line']) if options['top-line']
# Double entry fields in one row
    double_field = 1 if options['double']
    html << '<tr>' if double_field < 2
#    
    html << if labels_pos == 'top' 
      %Q[<td class="dc-form-label dc-color-#{odd_even} dc-align-left" title="#{help}" 
      #{double_field == 0 ? 'colspan="2"' : 'style="width:50%;"'}>
      <div><label for="record_#{options['name']}">#{text} </label></div>
      <div id="td_record_#{options['name']}">#{field_html}</div></td>]
    else  
      %Q[<td class="dc-form-label dc-color-#{odd_even} dc-align-#{labels_pos}" title="#{help}">
      <label for="record_#{options['name']}">#{text} </label></td>
      <td id=\"td_record_#{options['name']}\" class=\"dc-form-field dc-color-#{odd_even}\" #{'colspan="3"' if double_field == 0 }>#{field_html}
      </td>
      ]
    end
    html << '</tr>' if double_field != 1
    double_field = 0 if double_field == 2
    double_field = 2 if double_field == 1    
    html << top_bottom_line(options['bottom-line']) if options['bottom-line']
  end
  html << '</table></table>'
end

############################################################################
# Creates edit form div. 
############################################################################
def dc_fields_for_form()
  html, tabs, tdata = '',[], ''
# Only fields defined  
  if (fields = @form['form']['fields'])
    html << "<div id='data_fields' " + (@form['form']['height'] ? "style=\"height: #{@form['form']['height']}px;\">" : '>')  
    html << dc_fields_for_tab(fields) + '</div>'
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
      tdata << "<div id='data_#{tabname}'"
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
      html << "<li id='li_#{tab}' data-div='#{tab}' class='dc-form-li #{'dc-form-li-selected' if first }'>#{t_name(tab, tab)}</li>" 
      first = false
    end
    html << '</ul>'
    html << tdata
  end
  # add last_updated_at hidden field so controller can check if record was updated in during editing
  html << hidden_field(nil, :last_updated_at, :value => @record.updated_at.to_i) if @record.respond_to?(:updated_at)
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
  html =  "<div id='dc-document-info'>#{t('drgcms.doc_info')}</div>"
#  html =  "<div id='dc-document-info'>#{fa_icon 'info-circle 2x'}</div>"
  html =  '<div id="dc-document-info">' + fa_icon('info-circle lg') + '</div>'
#
  html << "<div id='dc-document-info-popup' class='div-hidden'><table>"
  u = _get_user_for('created_by')
  html << "<tr><td>#{t('drgcms.created_by', 'Created by')}: </td><td><b>#{u}</td></tr>" if u
  u = _get_user_for('updated_by')
  html << "<tr><td>#{t('drgcms.updated_by', 'Updated by')}: </td><td><b>#{u}</td></tr>" if u
  html << "<tr><td>#{t('drgcms.created_at', 'Created at')}: </td><td><b>#{dc_format_value(@record.created_at)}</td></tr>" if @record['created_at']
  html << "<tr><td>#{t('drgcms.updated_at', 'Updated at')}: </td><td><b>#{dc_format_value(@record.updated_at)}</td></tr>" if @record['updated_at']
  html << '</table>'
# Copy to clipboard icon
  parms = params.clone
  parms[:controller] = 'dc_common'
  parms[:action]     = 'copy_clipboard'
  url = url_for(parms)
#  caption = image_tag('drg_cms/copy.png', title: t('drgcms.doc_copy_clipboard'))
#  html << %Q[<hr><img class="dc-link-img dc-link-ajax dc-animate" data-url="#{url}" data-request="get" #{caption}]
  html << fa_icon('copy 2x', class: 'dc-link-img dc-link-ajax dc-animate', 
                  'data-url' => url, 'data-request' => 'get', title: t('drgcms.doc_copy_clipboard') )
  (html << '</div>').html_safe
#  html.html_safe
end

end
