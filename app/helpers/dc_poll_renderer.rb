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

########################################################################
# Renders code for displaying a poll. Polls may replace forms when user interaction
# is required in browser.
########################################################################
class DcPollRenderer
  
include CmseditHelper
include DcApplicationHelper
include ActionView::Helpers::FormHelper # for form hepers
include ActionView::Helpers::FormOptionsHelper # for select helper

########################################################################
# Object initialization.
########################################################################
def initialize( parent, opts={} ) #:nodoc:
  @parent   = parent
  @opts     = opts
  @part_css = ''
  self
end

########################################################################
# Dummy params method for accesing session params object from form.
########################################################################
def params
  @parent.params
end

########################################################################
# Outputs code required for poll item. Subroutine of default method.
########################################################################
def do_one_item(poll, yaml)
  html = ''
  yaml['separator'] ||= ''
  yaml['text']      ||= ''
# 
  text = yaml['text'].match(/\./) ? t(yaml['text']) : yaml['text'] 
  text << '<font color="red"> *</font>' if yaml['mandatory']
# Just add text if comment and go to next one    
  if yaml['type'] == 'comment'
    html << if poll.display == 'lr'
      "<tr><td colspan='2' class='poll-data-text'>#{text}</td></tr>"
    else
      "<div class='poll-data-text'>#{text}</div>"
    end    
    return html
  end
# Set default value, if not already set
  if yaml['default'] 
    if yaml['default'].match('eval')
      e = yaml['default'].match(/\((.*?)\)/)[1]
      yaml['default'] = eval e
    end
    key = "p_#{yaml['name']}"
    params[key] = yaml['default'] unless params[key]
  end
# create form_field object and retrieve html code
  clas_string = yaml['type'].camelize
  field_html = if DrgcmsFormFields.const_defined?(clas_string) 
    clas = DrgcmsFormFields.const_get(clas_string)
    o = clas.new(@parent, @record, yaml).render
#TODO collect all javascript and add it at the end
    o.html + (o.js.size > 0 ? @parent.javascript_tag(o.js) : '')
  else # litle error string
    "Error: Code for field type #{yaml['type']} not defined!"
  end

#  field = send('dc_' + yaml['type'], yaml) # call dc_xxx method to get field html code
  if yaml['type'].match(/submit_tag|link_to/)
# There can be more than one links on form. End the data at first link or submit.
    if !@end_of_data 
      html << if poll.display == 'lr'
        "</table><br>\n"
      else
        "</div>\n"
      end
      # captcha
      if poll.captcha_type.to_s.size > 1
        @opts.merge!(:captcha_type => poll.captcha_type)
        captcha = DcCaptchaRenderer.new(@parent, @opts)
        html << captcha.render_html
        @part_css = captcha.render_css
      end
      @end_od_data = true
    end
# submit and link tag 
    clas = yaml['type'].match(/submit_tag/) ? '' : 'dc-link-submit'
    html << "<span class='#{clas} dc-animate'>#{field_html}#{yaml['separator']}</span>"
# other elements
  else
    html << if poll.display == 'lr'
      "<tr><td class='poll-data-text'>#{text}</td><td class='poll-data-field'>#{field_html}</td></tr>\n"
    else
      "<div class='poll-data-text'>#{text}</div><div class='poll-data-field'>#{field_html}#{yaml['separator']}</div>\n"
    end    
  end
end

########################################################################
# Default poll renderer method. Renders data for specified pool.
########################################################################
def default
# poll_id may be defined in params or opts
  poll_id = @opts[:poll_id] || @parent.params[:poll_id]
  return '<br>Poll id is not defined?<br>' if poll_id.nil?
#  
  poll = DcPoll.find(poll_id)
  poll = DcPoll.find_by(name: poll_id) if poll.nil? # name instead of id
  return "<div class=\"dc-form-error\">Invalid Poll id #{poll_id}</div>" if poll.nil?
  html = '<a name="poll-top"></a>'

  # Operation called before poll is displayed. Usefull for filling predefined values into flash[:record][value]
  # Called method must return at least one result if process can continue.
  if poll.pre_display.to_s.size > 1
    begin
      continue, message = eval(poll.pre_display.strip + '(@parent)')
    rescue Exception => e
      return "<div class=\"dc-form-error\">Error! Poll pre display. Error: #{e.message}</div>" 
    end
    return message unless continue
    html << message if message
  end

# there might be more than one poll displayed on page. Check if messages and values are for me
  if @parent.flash[:poll_id].nil? or @parent.flash[:poll_id] == poll_id
# If flash[:record] is present copy content to params record hash
    @parent.flash[:record].each {|k,v| @parent.params["p_#{k}"] = v } if @parent.flash[:record]  
# Error during procesing request
    html << "<div class=\"dc-form-error\">#{@parent.flash[:error]}</div>\n" if @parent.flash[:error].to_s.size > 0
    html << "<div class=\"dc-form-info\">#{@parent.flash[:info]}</div>\n" if @parent.flash[:info]
  end
# div and form tag
  html <<  "<div class=\"poll-div\">\n"
# edit link  
  if @opts[:edit_mode] > 1
    @opts[:editparams].merge!( controller: 'cmsedit', action: 'edit', id: poll._id, table: 'dc_poll' )
    @opts[:editparams].merge!(title: "#{t('drgcms.edit')}: #{poll.name}")
    @opts[:editparams].delete(:ids) # this is from page, but it gets in a way
    html << dc_link_for_edit( @opts[:editparams] )
  end
#  
  html << case
  when poll.operation == 'poll_submit' then
    @parent.form_tag(action: poll.operation, method: :put)
  when poll.operation == 'link' then
    @parent.form_tag( poll.parameters, method: :put)
  end
# header 
  html << "<div class='poll-title'>#{poll.title}</div>" unless poll.title[0] == '-' # - on first position will not display title
  html << poll.sub_text.to_s # if poll.sub_text.to_s.size > 5
  html << if poll.display == 'lr'
    "\n" + '<table class="poll-data-table">'
  else
    '<div class="poll-data-div">' + "\n"
  end
# items. Convert each item to yaml
  @end_od_data = false
  if poll.form.to_s.size < 10
    items = poll.dc_poll_items
    items.sort! {|a,b| a.order <=> b.order }
    items.each do |item|
      next unless item.active # disabled items
  # convert options to yaml
      yaml = YAML.load(item.options) || {}
      yaml['name'] = item.name
      yaml['html'] ||= {}
      yaml['html']['size'] = item.size
      (yaml['html']['class'] ||= 'dc-submit') if item.type == 'submit_tag'
      yaml['text'] = item.text
      yaml['mandatory']  = item.mandatory
      yaml['type']       = item.type
      html << do_one_item(poll, yaml)
    end
# Form. Just call do_one_item for each form item
  else
    yaml = YAML.load(poll.form.gsub('&nbsp;',' ')) # very annoying. They come with copy&paste ;-)
# if entered without numbering yaml is returned as Hash otherwise as Array
    yaml.each { |i| html << do_one_item(poll, (i.class == Hash ? i : i.last)) } # 
  end
# hide some fields usefull as parameters  
# was html << @parent.hidden_field_tag('return_to', @opts[:return_to] || @parent.params[:return_to] || '/')
  html << @parent.hidden_field_tag('return_to', @opts[:return_to] || @parent.params[:return_to] || @parent.request.url)
  html << @parent.hidden_field_tag('return_to_error', @parent.request.url )
  html << @parent.hidden_field_tag('poll_id', poll_id )
  html << @parent.hidden_field_tag('page_id', @parent.page.id )
  html << "</form></div>"
  
  @part_css = poll.css
  html
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error DcPoll: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @part_css
end

end
