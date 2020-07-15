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
#  data = {'request' => 'script', 'script' => yaml['js'] || yaml['script'] }
#  %Q[<li class="dc-link-ajax with-link dc-animate">#{ dc_link_to(yaml['caption'], yaml['icon'], '#', data: data ) }</li>]
  icon = dc_icon_for_link yaml['icon']
  data = %Q[data-request="script" data-script="#{yaml['js'] || yaml['script']}"]
  %Q[<li class="dc-link-ajax dc-animate" #{data}>#{icon} #{ t(yaml['caption'],yaml['caption']) }</li>]
end

############################################################################
# Will return field form definition if field is defined on form. 
# Field definition will be used for input field on the form.
############################################################################
def dc_get_field_form_definition(name) #:nodoc:
  return nil if @form['form'].nil?
  
  @form['form']['tabs'].each do |tab|
# Array with 2 elements. First is tabname, second is data      
    my_fields = tab.last
    my_fields.each {|k,v| return v if (k.class == Integer and v['name'] == name) }
  end if @form['form']['tabs'] #  I know. But nice. 
#
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
# Returns: 
#   field_html : String : HTML code for field definition
#   label : String : Label text
#   help : String : Help text
############################################################################
def dc_field_label_help(options)
  # no label or help in comments
  unless %w(comment action).include?(options['type'])
    caption = options['caption'] || options['text']
    label = if caption.blank?    
      t_name(options['name'], options['name'].capitalize.gsub('_',' ') )
    elsif options['name']
      t(caption, caption) 
    end
    # help text can be defined in form or in translations starting with helpers. or as helpers.help.collection.field
    help = if options['help'] 
      options['help'].match('helpers.') ? t(options['help']) : options['help']
    end
    help ||= t('helpers.help.' + @form['table'] + '.' + options['name'],' ') if options['name'] 
  end
  # create field object from class and call its render method
  klass_string = options['type'].camelize
  field_html = if DrgcmsFormFields.const_defined?(klass_string) # when field type defined
    klass = DrgcmsFormFields.const_get(klass_string)
    field = klass.new(self, @record, options).render
    @js  << field.js
    @css << field.css
    field.html 
  else # litle error string
    "Error: Field type #{options['type']} not defined!"
  end
  [field_html, label, help]
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
  #
  if ( field_definition = dc_get_field_form_definition(yaml['name']) )
     field, label, help = dc_field_label_help(field_definition)
  else
    yaml['type'] = yaml['field_type']
    field, label, help = dc_field_label_help(yaml)
  end
   # input field will have label as placeholder
   field = field.sub('input',"input placeholder=\"#{label}\"")
   %Q[<li class="no-background">#{field}</li>]
  
end

############################################################################
#
############################################################################
def dc_html_data(yaml)
  return '' if yaml.blank?
  yaml.inject(' ') {|result, e| result << "#{e.first}=\"#{e.last}\" "}
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
def dc_link_ajax_window_submit_action(yaml, record=nil, action_active=true)
  parms = {}
  caption = yaml['caption'] ? t("#{yaml['caption'].downcase}", yaml['caption']) : nil
  icon    = yaml['icon'] ? "#{fa_icon(yaml['icon'])}" : ''
  # action is not active
  unless dc_is_action_active?(yaml)
    return "<li class=\"dc-link-no\">#{icon} #{caption}</li>" 
  end
  # set data-confirm when confirm 
  yaml['html'] ||= {}
  confirm = yaml['html']['data-confirm'] || yaml['confirm']
  yaml['html']['data-confirm'] = t(confirm) unless confirm.blank?
  # direct url
  if yaml['url']
    parms['controller'] = yaml['url'] 
    parms['idr']        = dc_document_path(record) if record
  # make url from action controller
  else
    parms['controller'] = yaml['controller'] || 'cmsedit'
    parms['action']     = yaml['action'] 
    parms['table']      = yaml['table'] 
    parms['form_name']  = yaml['form_name']
    parms['control']    = yaml['control'] if yaml['control']
    parms['id']         = record.id if record
  end
  # add current id to parameters
  parms['id'] = dc_document_path(record) if record
  # overwrite with or add additional parameters from environment or record
  yaml['params'].each { |k,v| parms[k] = dc_value_for_parameter(v) } if yaml['params']
  parms['table'] = parms['table'].underscore if parms['table'] # might be CamelCase
  # error if controller parameter is missing
  if parms['controller'].nil? && parms['url'].nil?
    "<li>#{'Controller not defined'}</li>"
  else
    yaml['caption'] ||= yaml['text'] 
    
    html_data = dc_html_data(yaml['html'])
    #
    url = url_for(parms) rescue 'URL error'
    request = yaml['request'] || yaml['method'] || 'get'
    if yaml['type'] == 'ajax' # ajax button
      clas = "dc-link-ajax dc-animate"
      %Q[<li class="#{clas}" data-url="#{action_active ? url : ''}"  #{html_data}
         data-request="#{request}" title="#{yaml['title']}">#{icon}#{caption}</li>]

    elsif yaml['type'] == 'submit'  # submit button
      # It's dirty hack, but will prevent not authorized message and render index action correctly
      parms[:filter] = 'on' 
      url  = url_for(parms) rescue 'URL error'
      clas = "dc-action-submit"
      %Q[<li class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}
         data-request="#{request}" title="#{yaml['title']}">#{icon}#{caption}</li>]

    elsif yaml['type'] == 'link'  # link button
      clas = "dc-link dc-animate"
      link = dc_link_to(yaml['caption'],yaml['icon'], parms, {target: yaml['target'], html: yaml['html']} )
      %Q[<li class="#{clas}">#{action_active ? link : caption}</li>]

    elsif yaml['type'] == 'window'
      clas = "dc-link dc-animate dc-window-open"
      %Q[<li class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}>#{icon}#{caption}</li>]

    else
      '<li>Action Type error</li>'
    end
  end
end

############################################################################
#
############################################################################
def dc_log_exception(exception)
  log = exception ? "\n!!!Error: #{exception.message}\n#{exception.backtrace.first.inspect}\n" : ''
  log << "DRG Form processing line: #{session[:form_processing]}\n"
  
  logger.error log
end
  
end
