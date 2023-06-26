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
# CmseditHelper module defines common methods used for DRGCMS forms.
#
###########################################################################
module CmsHelper
  # javascript part created by form helpers
  attr_reader :js 
  
############################################################################
# Creates code for script action type.
############################################################################
def dc_script_action(yaml)
  icon = dc_icon_for_link yaml['icon']
  yaml['html'] ||= {}
  yaml['html']['data-url'] = 'script'
  yaml['html']['data-request'] = 'script'
  yaml['html']['data-script'] = "#{yaml['js'] || yaml['script']}"
  yaml['html']['class'] ||= 'dc-link-ajax'
  attributes = yaml['html'].inject('') { |r, e| r << "#{e.first}=\"#{e.last}\"" }

  #  data = %(data-request="script" data-script="#{yaml['js'] || yaml['script']}" data-url="script")
  #%(<li><div class="dc-link-ajax" #{data}>#{icon} #{ t(yaml['caption'], yaml['caption']) }</div></li>)
  %(<li><div #{attributes}>#{icon} #{ t(yaml['caption'], yaml['caption']) }</div></li>)
end

############################################################################
# Will return field form definition if field is defined on form. 
# Field definition will be used for input field on the form.
############################################################################
def dc_get_field_form_definition(name) #:nodoc:
  return if @form['form'].nil?
  
  @form['form']['tabs'].each do |tab|
    # Array with 2 elements. First is tab name, second is data
    my_fields = tab.last
    my_fields.each { |k, v| return v if (k.class == Integer && v['name'] == name) }
  end if @form['form']['tabs'] #  I know. But nice. 

  @form['form']['fields'].each do |field|
    next unless field.first.class == Integer # options
    return field.last if field.last['name'] == name
  end if @form['form']['fields']
  nil
end

############################################################################
# Return field code, label and help text for a field defined on a DRG Form.
# 
# Parameters:
# options : Hash : Field definition
# 
# Returns: Array[3]
#   field_html : String : HTML code for field definition
#   label : String : Label text
#   help : String : Help text
############################################################################
def dc_field_label_help(options)
  label, help = dc_label_help(options)
  # create field object from type and call its render method
  if options['type'].present?
    klass_string = options['type'].camelize
    field_html = if DrgcmsFormFields.const_defined?(klass_string) # when field type defined
      klass = DrgcmsFormFields.const_get(klass_string)
      field = klass.new(self, @record, options).render
      @js  << field.js
      @css << field.css
      field.html
    else
      "Error: Field type #{options['type']} not defined!"
    end
  else
    "Error: Field type missing!"
  end
  [field_html, label, help]
end

############################################################################
# Return label and help text for a field defined on Form.
#
# Parameters:
# options : Hash : Field definition
#
# Returns:
#   label : String : Label text
#   help : String : Help text
############################################################################
def dc_label_help(options)
  # no label or help in comments
  return [nil, nil] if %w[comment action].include?(options['type'])

  label = options['caption'] || options['text'] || options['label']
  if options['name']
    label = if label.blank?
              t_label_for_field(options['name'], options['name'].capitalize.gsub('_',' ') )
            elsif options['name']
              t(label, label)
            end
  end
  # help text can be defined in form or in translations starting with helpers. or as helpers.help.collection.field
  help = options['help']
  if help.blank?
    help = if options['name']
             # if defined as i18n_prefix replace "label" with "help"
             prefix = @form['i18n_prefix'] ? @form['i18n_prefix'].sub('label', 'help') : "helpers.help.#{@form['table']}"
             "#{prefix}.#{options['name']}"
           end
    help = help.to_s
  end
  help = t(help, ' ') if help.to_s.match(/help\./)

  [label, help]
end

############################################################################
# Return label and help for tab on Form.
#
# Parameters:
# options : String : Tab name on form
#
# Returns:
#   label : String : Label text
#   help : String : Help text
############################################################################
def dc_tab_label_help(tab_name)
  label = @form.dig('form', 'tabs', tab_name, 'caption') || tab_name
  label = t(label, t_label_for_field(label, label))

  help = @form.dig('form', 'tabs', tab_name, 'help') || "helpers.help.#{@form['table']}.#{tab_name}"
  help = t(help, t_label_for_field(help, help))
  help = nil if help.match('helpers.') # help not found in translation

  [label, help]
end

############################################################################
# Creates code for including data entry field in index actions.
############################################################################
def dc_field_action(yaml)
  # assign value if value found in parameters
  if params['record']
    value = params['record'][yaml['name']]
    params["p_#{yaml['name']}"] = value
  end
  # find field definition on form
  if ( field_definition = dc_get_field_form_definition(yaml['name']) )
    # some options may be redefined
    field_definition['size'] = yaml['size'] if yaml['size']
    field, label, help = dc_field_label_help(field_definition)
  else
    yaml['type'] = yaml['field_type']
    field, label, help = dc_field_label_help(yaml)
  end
  # input field will have label as placeholder
  field = field.sub('input',"input placeholder=\"#{label}\"")
  %(<li class="no-background">#{field}</li>)
end

############################################################################
# Create ex. class="my-class" html code from html options for action
############################################################################
def dc_html_data(yaml)
  return '' if yaml.blank?

  yaml.inject(' ') { |result, e| result = e.last.nil? ? result : result << "#{e.first}=\"#{e.last}\" " }
end

############################################################################
# There are several options for defining caption (caption,label, text). This method
# will ensure that caption is returned anyhow provided.
############################################################################
def dc_get_caption(yaml)
  yaml['caption'] || yaml['text'] || yaml['label']
end
############################################################################
# Creates code for link, ajax or windows action for index or form actions.
# 
# Parameters:
#   yaml: Hash : Action definition
#   record : Object : Currently selected record if available
#   action_active : Boolean : Is action active or disabled
#   
# Returns:
#   String : HTML code for action
############################################################################
def dc_link_ajax_window_submit_action(yaml, record = nil, action_active = true)
  parms = {}
  caption = dc_get_caption(yaml)
  caption = caption ? t("#{caption.downcase}", caption) : nil
  icon    = yaml['icon'] ? "#{fa_icon(yaml['icon'])}" : ''
  # action is not active
  unless dc_is_action_active?(yaml)
    return %(<li><div class="dc-link-no">#{icon} #{caption}</div></li>)
  end
  # set data-confirm when confirm shortcut present
  yaml['html'] ||= {}
  text = yaml['html']['data-confirm'] || yaml['confirm']
  yaml['html']['data-confirm'] = t(text) if text.present?

  text = yaml['html']['title'] || yaml['title']
  yaml['html']['title'] = t(text) if text.present?

  yaml['html']['target'] ||= yaml['target']
  # direct url
  if yaml['url']
    parms['url'] = yaml['url']
    parms['idr'] = dc_document_path(record) if record
  # make url from action controller
  else
    parms['controller'] = yaml['controller'] || 'cmsedit'
    parms['action']     = yaml['action'] 
    parms['table']      = yaml['table'] || @form['table']
    parms['form_name']  = yaml['form_name']
    parms['control']    = yaml['control'] if yaml['control']
    parms['id']         = record.id if record
  end
  # add current id to parameters
  parms['id'] = dc_document_path(record) if record
  # overwrite with or add additional parameters from environment or record
  yaml['params'].each { |k, v| parms[k] = dc_value_for_parameter(v, record) } if yaml['params']

  parms['table'] = parms['table'].underscore if parms['table'] # might be CamelCase
  # error if controller parameter is missing
  return "<li>#{'Controller not defined'}</li>" if parms['controller'].nil? && parms['url'].nil?

  html_data = dc_html_data(yaml['html'])
  url = url_for(parms) rescue 'URL error'
  url = nil if parms['url'] == '#'
  request = yaml['request'] || yaml['method'] || 'get'

  code = case yaml['type']
  when 'ajax' # ajax button
    clas = 'dc-link-ajax'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}
       data-request="#{request}" title="#{yaml['title']}">#{icon}#{caption}</div>)

  when 'submit'  # submit button
    # It's dirty hack, but will prevent not authorized message and render index action correctly
    parms[:filter] = 'on'
    url  = url_for(parms) rescue 'URL error'
    clas = 'dc-action-submit'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}
       data-request="#{request}" title="#{yaml['title']}">#{icon}#{caption}</div>)

  when 'link'  # link button
    yaml['html'] = dc_yaml_add_option(yaml['html'], class: 'dc-link')
    link = dc_link_to(caption, yaml['icon'], parms, yaml['html'] )
    %(#{action_active ? link : caption})

  when 'window' # open window
    clas = 'dc-link dc-window-open'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}>#{icon}#{caption}</div>)

  when 'popup' # popup dialog
    clas = 'dc-link dc-popup-open'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}>#{icon}#{caption}</div>)

  else
    'Type error!'
  end
  "<li>#{code}</li>"
end

############################################################################
# Add new option to yaml. Subroutine of dc_link_ajax_window_submit_action.
############################################################################
def dc_yaml_add_option(source, options) #nodoc
  options.each do |k, v|
    key = k.to_s
    source[key] ||= ''
    # only if not already present
    source[key] << " #{v}" unless source[key].match(v.to_s)
  end
  source
end

############################################################################
# Log exception to rails log. Usefull for debugging eval errors.
############################################################################
def dc_log_exception(exception, where = '')
  log = exception ? "\n*** Error:#{where + ':'} #{exception.message}\n#{exception.backtrace.first.inspect}\n" : ''
  log << "DRG Form: #{CmsHelper.form_param(params)}, line: #{session[:form_processing]}\n"
  
  logger.error log
end

############################################################################
# Will return form id. id can be used for css selecting of fields on form.
# Form id is by default form_name || table parameter.
############################################################################
def dc_form_id
  %(id="#{CmsHelper.form_param(params) || CmsHelper.table_param(params)}" ).html_safe
end

############################################################################
# Will return class for form. Class can be used for different styling of forms.
############################################################################
def dc_form_class(additional_class = nil)
  %(class="#{additional_class} #{@form['class']}" ).html_safe
end

############################################################################
# Will return form_name from parameter regardless if set as form_name or just f.
############################################################################
def self.form_param(params)
  params[:form_name] || params[:f]
end

############################################################################
# Will return table name from parameter regardless if set as table or just t.
############################################################################
def self.table_param(params)
  params[:table] || params[:t]
end

########################################################################
# Searches forms path for file_name and returns full file name or nil if not found.
#
# @param [String] Form file name. File name can be passed as gem_name.filename. This can
# be useful when you are extending form but want to retain same name as original form
# For example. You are extending dc_user form from drg_cms gem and want to
# retain same dc_user name. This can be done by setting drg_cms.dc_user as extend option.
#
# @return [String] Form file name including path or nil if not found.
########################################################################
def self.form_file_find(form_file)
  form_path = nil
  form_path, form_file = form_file.split(/\.|\//) if form_file.match(/\.|\//)

  DrgCms.paths(:forms).reverse.each do |path|
    f = "#{path}/#{form_file}.yml"
    return f if File.exist?(f) && (form_path.nil? || path.to_s.match(/\/#{form_path}(-|\/)/i))
  end
  raise "Exception: Form file '#{form_file}' not found!"
end

########################################################################
# Merges two forms when current form extends other form. Subroutine of dc_form_read.
# With a little help of https://www.ruby-forum.com/topic/142809
########################################################################
def self.forms_merge(hash1, hash2)
  target = hash1.dup
  hash2.keys.each do |key|
    if hash2[key].is_a?(Hash) && hash1[key].is_a?(Hash)
      target[key] = CmsHelper.forms_merge(hash1[key], hash2[key])
      next
    end
    target[key] = hash2[key] == '/' ? nil :  hash2[key]
  end
  # delete keys with nil value
  target.delete_if { |k, v| v.nil? }
end

end
