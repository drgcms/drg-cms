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
  
include CmsCommonHelper
include DcApplicationHelper
include ActionView::Helpers::FormHelper # for form helpers
include ActionView::Helpers::FormOptionsHelper # for select helper

########################################################################
# Object initialization.
########################################################################
def initialize( parent, opts={} ) #:nodoc:
  @parent   = parent
  @opts     = opts
  @part_css = ''
  @part_js  = ''
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
  # label
  text = yaml['text'].match(/\./) ? t(yaml['text']) : yaml['text'] 
  if yaml['mandatory']
    text << ( poll.display == 'in' ? ' *' : '<span class="required"> *</span>' )
    yaml['html'] ||= {}
    yaml['html']['required'] = true
  else
    text << " &nbsp;" if poll.display == 'lr' and !yaml['type'].match(/submit_tag|link_to/)
  end
  
  # Just add text if comment and go to next one
  if yaml['type'] == 'comment'
    html << if poll.display == 'lr'
      "<div class='row-div'><div class='dc-form-label poll-data-text comment'>#{text}</div></div>"
    else
      "<div class='poll-data-text comment'>#{text}</div>"
    end    
    return html
  end

  # Set default value, if not already set
  if yaml['default'] 
    if yaml['default'].match('eval')
      e = yaml['default'].match(/\((.*?)\)/)[1]
      yaml['default'] = eval e
    elsif yaml['default'].match('params')
      param_name = yaml['default'].split(/\.|\ |\,/)[1]
      yaml['default'] = @parent.params[param_name]
    end
    key = "p_#{yaml['name']}"
    params[key] = yaml['default'] unless params[key]
  end
  # Label as placeholder
  if poll.display == 'in'
    yaml['html'] ||= {}
    yaml['html']['placeholder'] = text
  end
  # create form_field object and retrieve html code
  clas_string = yaml['type'].camelize
  field_html = if DrgcmsFormFields.const_defined?(clas_string) 
    clas = DrgcmsFormFields.const_get(clas_string)
    field = clas.new(@parent, @record, yaml).render
    @part_js << field.js
    field.html
  else # error string
    "Error: Code for field type #{yaml['type']} not defined!"
  end

  if yaml['type'].match(/submit_tag|link_to/)
    # There can be more than one links on form. End the data at first link or submit.
    if !@end_of_data 
      html << (poll.display == 'lr' ? "</div><br>\n" : "</div>\n")
      # captcha
      if poll.captcha_type.to_s.size > 1
        @opts.merge!(:captcha_type => poll.captcha_type)
        captcha = DcCaptchaRenderer.new(@parent, @opts)
        html << captcha.render_html
        @part_css = captcha.render_css
      end
      @end_of_data = true
    end
    # submit and link tag
    clas = yaml['type'].match(/submit_tag/) ? '' : 'dc-link-submit'
    html << "<span class='#{clas} dc-animate'>#{field_html}#{yaml['separator']}</span>"
  # other fields
  else
    html << case
      when poll.display == 'lr' then
      "<div class='row-div'><div class='dc-form-label poll-data-text lr #{yaml['class']}'>#{text}</div><div class='poll-data-field td #{yaml['class']}'>#{field_html}</div></div>\n"
      when poll.display == 'td' then
      "<div class='poll-data-text td #{yaml['class']}'>#{text}</div><div class='poll-data-field td #{yaml['class']}'>#{field_html}#{yaml['separator']}</div>\n"
      else
      "<div class='poll-data-field in #{yaml['class']}'>#{field_html}#{yaml['separator']}</div>\n"
    end    
  end
end

########################################################################
# Call method before poll is displayed. Usefull for filling predefined values into flash[:record][value]
# Method cane be defined as ClassName.method or only method. 
# If only method is defined then method name must exist in helpers.
# 
# Called method must return at least one result if process can continue.
########################################################################
def eval_pre_display(code)
  a = code.strip.split('.')
  if a.size == 1
    continue, message = @parent.send(a.first)
  else
    klass = a.first.classify.constantize
    continue, message = klass.send(a.last,@parent)
  end
  [continue, message]
end

########################################################################
# Default poll renderer method. Renders data for specified pool.
########################################################################
def default
  # poll_id may be defined in params or opts
  poll_id = @opts[:poll_id] || @parent.params[:poll_id]
  return '<br>Poll id is not defined?<br>' if poll_id.nil?

  poll = DcPoll.find(poll_id)
  poll = DcPoll.find_by(name: poll_id) if poll.nil? # name instead of id
  return %(<div class="dc-form-error">Invalid Poll id #{poll_id}</div>) if poll.nil?
  # If parent cant be seen. so cant be polls
  can_view, message = dc_user_can_view(@parent, @parent.page)
  return %(<div class="dc-form-error">#{message}</div>) unless can_view

  html = @opts[:div] ? %(<div id="#{@opts[:div]}"'>) : ''
  html << '<a name="poll-top"></a>'
  unless poll.pre_display.blank?
    begin
      continue, message = eval_pre_display(poll.pre_display)
    rescue Exception => e
      return %(<div class="dc-form-error">Error! Poll pre display. Error: #{e.message}</div>)
    end
    return message unless continue

    html << message if message
  end
  # there might be more than one poll displayed on page. Check if messages and values are for me
  if @parent.flash[:poll_id].nil? || @parent.flash[:poll_id].to_s == poll_id.to_s
    # If flash[:record] is present copy content to params record hash
    @parent.flash[:record].each {|k,v| @parent.params["p_#{k}"] = v } if @parent.flash[:record]  
    # Error during procesing request
    html << %(<div class="dc-form-error">#{@parent.flash[:error]}</div>\n) if @parent.flash[:error].to_s.size > 0
    html << %(<div class="dc-form-info">#{@parent.flash[:info]}</div>\n) if @parent.flash[:info]
  end
  # div and form tag
  html <<  %(<div class="poll-div">\n)
  # edit link
  if @opts[:edit_mode] > 1
    @opts[:editparams].merge!( controller: 'cmsedit', action: 'edit', id: poll._id, table: 'dc_poll', form_name: 'dc_poll' )
    @opts[:editparams].merge!(title: "#{t('drgcms.edit')}: #{poll.name}")
    @opts[:editparams].delete(:ids) # this is from page, but it gets in a way
    html << dc_link_for_edit( @opts[:editparams] )
  end

  html << case
  when poll.operation == 'poll_submit' then
    @parent.form_tag(action: poll.operation, method: :put)
  when poll.operation == 'link' then
    @parent.form_tag( poll.parameters, method: :put)
  end
  # header, - on first position will not display title
  html << %(<div class="poll-title">#{poll.title}</div>) unless poll.title[0] == '-'
  html << %(<div class="poll-text">#{poll.sub_text}</div>)
  html << if poll.display == 'lr'
            %(\n<div class="poll-data-table">)
          else
            %(<div class="poll-data-div">\n)
          end
  # items. Convert each item to yaml
  @end_od_data = false
  if poll.form.to_s.size < 10
    items = poll.dc_poll_items
    items.sort! { |a,b| a.order <=> b.order }
    items.each do |item|
      next unless item.active # disabled items
      # convert options to yaml
      yaml = YAML.load(item.options) || {}
      yaml = {} if yaml.class == String
      yaml['name'] = item.name
      yaml['html'] ||= {}
      yaml['html']['size'] = item.size
      (yaml['html']['class'] ||= 'dc-submit') if item.type == 'submit_tag'
      yaml['text'] = item.text
      yaml['mandatory'] = item.mandatory
      yaml['type'] = item.type

      html << do_one_item(poll, yaml)
    end
  else
    yaml = YAML.load(poll.form.gsub('&nbsp;',' ')) # very annoying. They come with copy&paste ;-)
    # if entered without numbering yaml is returned as Hash otherwise as Array
    yaml.each { |i| html << do_one_item(poll, (i.class == Hash ? i : i.last)) } # 
  end
  # hide some fields usefull as parameters
  html << @parent.hidden_field_tag('return_to', @opts[:return_to] || @parent.params[:return_to] || @parent.request.url)
  html << @parent.hidden_field_tag('return_to_error', @parent.request.url )
  html << @parent.hidden_field_tag('poll_id', poll_id )
  html << @parent.hidden_field_tag('page_id', @parent.page.id )
  # Add javascript code
  html << @parent.javascript_tag(@part_js + poll.js.to_s)
  html << "</form></div>"
  html << '</div>' if @opts[:div]
  
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
