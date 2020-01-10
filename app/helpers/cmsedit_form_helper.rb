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
module CmseditFormHelper

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
  html = %Q[<span class="dc-spinner div-hidden">#{fa_icon('spinner lg spin')}</span><ul class="dc-menu">]
  
  actions.each do |element|
    session[:form_processing] = "form:actions: #{element}"
    v = element[1]
    next if v.nil?  # yes it happends
    action_active = !(dc_dont?(v['when_new']) and @record.new_record?)
    parms = @parms.clone
    if v.class == String
      next if params[:readonly] and !(v == 'back')
      
      html << '<li class="dc-link dc-animate">'
      html << case 
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
      html << '</td>'
    # non standard actions      
    else
      html << case 
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
        # overwrite with or add additional parameters from environment or record
        v['params'].each { |k,v| parms[k] = dc_value_for_parameter(v) } if v['params']
        parms['table'] = parms['table'].underscore if parms['table'] # might be CamelCase
        # error if controller parameter is missing
        if parms['controller'].nil?
          "<li>#{'Controller not defined'}</li>"
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
        dc_script_action(v)
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
  @js      ||= ''
  html       = '<div class="dc-form">'
  labels_pos = dc_check_and_default(@form['form']['labels_pos'], 'right', ['top','left','right'])
  hidden_fields  = ''
  odd_even       = nil
  group_option, group_count = 0, 0
  reset_cycle()
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
    caption = options['caption'] || options['text']
    label = if !caption.blank?    
      t(caption, caption)
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
      label_width = 14
      # less place for label when more then 1 field per row
      label_width = 10 if group_option > 1 and group_option != group_count
      data_width  = (94 - 10*group_option)/group_option
%Q[
<div class="dc-form-label dc-color-#{odd_even} dc-align-#{labels_pos}" style="width:#{label_width}%;" title="#{help}">
  <label for="record_#{options['name']}">#{label} </label>
</div>
<div id="td_record_#{options['name']}" class="dc-form-field dc-color-#{odd_even}" style="width:#{data_width}%;">#{field_html}</div>
]
    end
# check if must go to next row
    group_count -= 1
    html << '</div>' if group_count == 0
    html << dc_top_bottom_line(options['bottom-line']) if options['bottom-line']
  end
  html << '</div>' << hidden_fields
end

############################################################################
# Creates edit form div. 
############################################################################
def dc_fields_for_form()
  html, tabs, tab_data = '',[], ''
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
      html << "\">#{t(tab_label, t_name(tab_label))}</li>" 
      first = false
    end
    html << '</ul>'
    html << tab_data
  end
  # add last_updated_at hidden field so controller can check if record was updated in db during editing
  html << hidden_field(nil, :last_updated_at, value: @record.updated_at.to_i) if @record.respond_to?(:updated_at)
  # add form time stamp to prevent double form submit
  html << hidden_field(nil, :form_time_stamp, value: Time.now.to_i)
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
