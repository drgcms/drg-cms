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
module CmseditEditHelper

############################################################################
# Will return value when internal or additional parameters are defined in action
# Subroutine of dc_actions_for_form.
############################################################################
def dc_value_for_parameter(param)#:nodoc:
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
def dc_actions_for_form(position)
# create standard actions  
  std_actions = {1 => 'back', 2 => {'type' => 'submit', 'caption' => 'drgcms.save'},
                 3 => {'type' => 'submit', 'caption' => 'drgcms.save&back'} }
# when edit only  
  unless @record.try(:id).nil?
    std_actions.merge!({6 => 'new'} )
    std_actions.merge!(@record.active ? {5 => 'disable'} : {5 => 'enable'} ) if @record.respond_to?('active')
    std_actions.merge!({7 => 'refresh'} )
  end
  actions = @form['form']['actions']
# shortcut for actions: standard 
  actions = nil if actions.class == String && actions == 'standard'
# standard actions
  actions = std_actions if actions.nil?
# readonly 
  actions = {1 => 'back'} if @form['readonly']
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
# remove standard option and sort so that standard actions come first
  actions.delete('standard')
  actions = actions.to_a.sort {|x,y| x[0] <=> y[0]} 
# Add spinner to the beginning
  html = %Q[<span class="dc-spinner">#{fa_icon('spinner lg spin')}</span><ul class="dc-menu #{position}">]
  
  actions.each do |key, options|
    session[:form_processing] = "form:actions: #{key} #{options}"
    next if options.nil?  # yes it happends
    action_active = !(dc_dont?(options['when_new']) and @record.new_record?)
    parms = @parms.clone
    if options.class == String
      next if params[:readonly] and !(options == 'back')
      
      html << '<li class="dc-link dc-animate">'
      html << case 
        when (options == 'back' or options == 'cancle') then
# If return_to is present link directly to URL        
          if parms['xreturn_to'] # disabled for now
            dc_link_to( 'drgcms.back','arrow-left', parms['return_to'] )
          else
            parms['action'] = 'index'
            parms['readonly'] = parms['readonly'].to_s.to_i < 2 ? nil : 1  
            dc_link_to( 'drgcms.back','arrow-left', parms )
          end
          
        when options == 'delete' then
          parms['operation'] = options
          parms['id']   = @record.id
          dc_link_to( 'drgcms.delete','remove', parms, data: { confirm: t('drgcms.confirm_delete') }, method: :delete )
          
        when options == 'new' then
          parms['action'] = options
          dc_link_to( 'drgcms.new', 'plus', parms)
          
        when (options == 'enable' or options == 'disable') then
          parms['operation'] = options
          parms['id']        = @record.id
          icon = (options == 'enable' ? 'thumbs-o-up' : 'thumbs-o-down')
          dc_link_to( "drgcms.#{options}",icon, parms, method: :delete )
          
        when options == 'edit' then
          parms['operation'] = options
          parms['id']        = @record.id
          dc_link_to( "drgcms.#{options}",options, parms )
          
        when options == 'refresh' then
          "<div onclick='window.location.href=window.location.href;'>#{fa_icon('refresh')} #{t('drgcms.refresh')}</div></li>"
      else 
        "err1 #{key}=>#{options}"
      end
      html << '</td>'
    # non standard actions      
    else
      options['title'] = t("#{options['title'].downcase}", options['title']) if options['title']
      html << case 
      # submit button
      when options['type'] == 'submit'
        caption = options['caption'] || 'drgcms.save'
        icon    = options['icon'] || 'save'
        prms = {}
        options['params'].each { |k,v| prms[k] = dc_value_for_parameter(v) } if options['params']
        if action_active 
          '<li class="dc-link-submit dc-animate">' + 
             dc_submit_tag(caption, icon, {:data => prms, :title => options['title'] }) +
          '</li>'
        else
          "<li class=\"dc-link-no\">#{fa_icon(icon)} #{caption}</li>"
        end
      
      # delete with some sugar added
      when options['type'] == 'delete'
        parms['id']   = @record.id
        parms.merge!(options['params'])
        caption = options['caption'] || 'drgcms.delete'
        icon = options['icon'] || 'remove'
        '<li class="dc-link dc-animate">' + 
          dc_link_to( caption, icon, parms, data: t('drgcms.confirm_delete'), method: :delete ) +
        '</li>'
      
      # ajax or link button
      when %w(ajax link window).include?(options['type'])
        dc_link_ajax_window_submit_action(options, @record, action_active)
        
# Javascript action        
      when options['type'] == 'script'
        dc_script_action(options)
      else
        '<li>err2</li>'
      end
    end
  end
  (html << '</ul>').html_safe
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
def dc_top_bottom_line(options)
  '<div class="dc-separator"></div>'
end    

############################################################################
# Creates input fields for one tab. Subroutine of dc_fields_for_form.
############################################################################
def dc_fields_for_tab(fields_on_tab) #:nodoc:
  html   = '<div class="dc-form">'
  labels_pos = dc_check_and_default(@form['form']['labels_pos'], 'right', ['top','left','right'])
  hidden_fields  = ''
  odd_even       = nil
  group_option, group_count = 0, 0
  reset_cycle()
  # Select form fields and sort them by key
  form_fields  = fields_on_tab.select {|field| field.class == Integer }
  form_fields.to_a.sort.each do |number, options|
    session[:form_processing] = "form:fields: #{number}=#{options}"
    # ignore if edit_only singe field is required
    next if params[:edit_only] and params[:edit_only] != options['name'] 
    # hidden_fields. Add them at the end
    if options['type'] == 'hidden_field'
      hidden_fields << DrgcmsFormFields::HiddenField.new(self, @record, options).render
      next
    end
    # label
    field_html,label,help = dc_field_label_help(options)
    # Line separator
    html << dc_top_bottom_line(options['top-line']) if options['top-line']
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
  <label for="record_#{options['name']}">#{label} </label>
  <div id="td_record_#{options['name']}">#{field_html}</div>
</div> ]
    else
      # no label
      if dc_dont?(options['caption'])
        label = ''
        label_width = 0
        data_width  = 100
      elsif group_option > 1 
        label_width = group_option != group_count ? 10 : 14        
        data_width  = 21
      else
        label_width = 14
        data_width  = 85      
      end      
%Q[
<div class="dc-form-label dc-color-#{odd_even} dc-align-#{labels_pos} dc-width-#{label_width}" title="#{help}">
  <label for="record_#{options['name']}">#{label} </label>
</div>
<div id="td_record_#{options['name']}" class="dc-form-field dc-color-#{odd_even} dc-width-#{data_width}">#{field_html}</div>
]
    end
    # check if group end
    if (group_count -= 1) == 0
      html << '</div>'
      # insert dummy div when only two fields in group
      html << '<div></div>' if group_option == 2
    end
    
    html << dc_top_bottom_line(options['bottom-line']) if options['bottom-line']
  end
  html << '</div>' << hidden_fields
end

############################################################################
# Creates edit form div. 
############################################################################
def dc_fields_for_form()
  html, tabs, tab_data = '',[], ''
  @js  ||= ''
  @css ||= ''
# Only fields defined  
  if (form_fields = @form['form']['fields'])
    html << "<div id='data_fields' " + (@form['form']['height'] ? "style=\"height: #{@form['form']['height']}px;\">" : '>')  
    html << dc_fields_for_tab(form_fields) + '</div>'
  else
# there are multiple tabs on form 
    first = true # first tab 
    @form['form']['tabs'].keys.sort.each do |tab_name|
      next if tab_name.match('actions')
# Tricky. If field name is not on the tab skip to next tab
      if params[:edit_only]
        is_on_tab = false
        @form['form']['tabs'][tab_name].each {|k,v| is_on_tab = true if params[:edit_only] == v['name'] }
        next unless is_on_tab
      end
# first div is displayed, all others are hidden      
      tab_data << "<div id=\"data_#{tab_name.delete("\s\n")}\""
      tab_data << ' class="div-hidden"' unless first
      tab_data << " style=\"height: #{@form['form']['height']}px;\"" if @form['form']['height']
      tab_data << ">#{dc_fields_for_tab(@form['form']['tabs'][tab_name])}</div>"
      tab_label = @form['form']['tabs'][tab_name]['caption'] || tab_name 
      tabs << [tab_name, tab_label]
      first = false      
    end
# make it all work together
    html << '<ul class="dc-form-ul" >'
    first = true # first tab must be selected
    tabs.each do |tab_name, tab_label| 
      html << "<li id=\"li_#{tab_name}\" data-div=\"#{tab_name.delete("\s\n")}\" class=\"dc-form-li"
      html << ' dc-form-li-selected' if first 
      html << "\">#{t(tab_label, t_name(tab_label,tab_label))}</li>" 
      first = false
    end
    html << '</ul>'
    html << tab_data
  end
  # add last_updated_at hidden field so controller can check if record was updated in db during editing
  html << hidden_field(nil, :last_updated_at, value: @record.updated_at.to_i) if @record.respond_to?(:updated_at)
  # add form time stamp to prevent double form submit
  html << hidden_field(nil, :form_time_stamp, value: Time.now.to_i)
  # add javascript code if defined by form
  @js << "\n#{@form['script']}"
  @css << "\n#{@form['css']}" 
  html.html_safe
end


############################################################################
# Creates head form div. Head form div is used to display header datausefull
# to be seen even when tabs are switched.
############################################################################
def dc_head_for_form()
  @css ||= ''
  head = @form['form']['head']
  return '' if head.nil?
  html    = %Q[<div class="dc-head #{head['class']}">\n<div class="dc-row">]
  split   = head['split'] || 4
  percent = 100/split
  current = 0
  head_fields = head.select {|field| field.class == Integer }
  head_fields.to_a.sort.each do |number, options|
    session[:form_processing] = "form: head: #{number}=#{options}"
    # Label
    caption = options['caption']
    span    = options['span'] || 1
    @css << "\n#{options['css']}" unless options['css'].blank?
    label   = if caption.blank?
      ''
    elsif options['name'] == caption
      t_name(options['name'], options['name'].capitalize.gsub('_',' ') )
    else
      t(caption, caption) 
    end
    # Field value
    begin
      field = if options['eval']
        dc_process_column_eval(options, @record)
      else
        @record.send(options['name'])
      end
    rescue Exception => e
      dc_log_exception(e)
      field = '!!!Error'
    end
    #
    klass = dc_style_or_class(nil, options['class'], field, @record)
    style = dc_style_or_class(nil, options['style'], field, @record)
    html << %Q[<div class="dc-column #{klass}" style="width:#{percent*span}%;#{style}">
  #{label.blank? ? '' : "<span class=\"label\">#{label}</span>"}
  <span class="field">#{field}</span>
</div>]
    current += span
    if current == split
      html << %Q[</div>\n<div class="dc-row">]
      current = 0
    end
  end
  html << '</div></div>'
  html.html_safe
end

############################################################################
# Returns username for id. Subroutine of dc_document_statistics
###########################################################################
def dc_document_user_for(field_name) #:nodoc:
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
  u = dc_document_user_for('created_by')
  html << %Q[<div><span>#{t('drgcms.created_by', 'Created by')}: </span><span>#{u}</span></div>] if u
  u = dc_document_user_for('updated_by')
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
