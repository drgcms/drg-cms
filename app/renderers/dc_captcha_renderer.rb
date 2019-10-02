#coding: utf-8
#--
# Copyright (c) 2012-2013 Damjan Rems
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
# This is renderer to return captcha code field when required on data entry. It currently
# implements only very basic captcha logic and only in Slovenian language.
########################################################################
class DcCaptchaRenderer  < DcRenderer
  
########################################################################
# Check if result of captcha is OK.
########################################################################
def is_ok?()
  return false unless self.respond_to?(@opts[:type])
  send(@opts[:type], true)
end

########################################################################
# Very simple captcha type. This is Slovenian only version.
########################################################################
def simpl(check=false) #:nodoc:
  a1 = [['enajst', 11], ['dvanajst',12],['petindvajset',25],['triintridest',33],['devetnajst',19]]
  a2 = [['šest', 6], ['sedem',7],['osem',8],['devet',9],['deset',10]]
  op = [['seštejte','+'],['odštejte','-']]
#
  if check
#    Prosimo sestejte dvanajst in sedem    
    ha1, hop,  ha2 = Hash[a1], Hash[op], Hash[a2]
    n1, operacija, prvi, n2, drugi = @opts['vprasanje'].split(' ')
    rezultat = eval("#{ha1[prvi]}#{hop[operacija]}#{ha2[drugi]}")
    return rezultat == @opts['record']['rezultat'].to_i
  else
    txt = "Prosimo #{op[Random.rand(1)][0]} #{a1[Random.rand(4)][0]} in #{a2[Random.rand(4)][0]}"
    y = {}
    y['name'] = 'rezultat'
    y['html'] = {}
    y['html']['size'] = 5

    <<eot    
   <div style="background-color: #fafafa; border: 1px solid #eee; padding: 6px; margin: 5px 5px 25px 5px; font-size: 1.2em; border-radius: 2px;">
     #{txt}&nbsp;<span style="color: red;">*</span>&nbsp;#{@parent.text_field('record','rezultat', size: 5)} #{@parent.hidden_field_tag('vprasanje', txt )}
   </div>
eot
  end
end

########################################################################
# Very simple captcha. Will ask for name of month in a year and check if entered value is valid when
# asked to check.
# 
# Parameters:
# [check] Boolean. Send true if you are checking if entered value is OK. Default is false.
# Method will return HTML code required to render capcha field on form.
# 
# Returns:
# HTML code for displaying captcha field on page. 
# If parameters check is true then method checks if written data is correct and returns true/false.
########################################################################
def simple(check=false)
  if check
    number = @opts['question'].split(' ').last.chomp('?').to_i
    month = I18n.t('date.month_names')[number].downcase
    return month == @opts['record']['captcha_result'].to_i
  else
    number = Random.rand(11) + 1
    txt = I18n.t('drgcms.dc_captcha.simple_message', number)

    <<eot    
   <div style="background-color: #fafafa; border: 1px solid #eee; padding: 6px; margin: 5px 5px 25px 5px; font-size: 1.2em; border-radius: 2px;">
     #{txt}&nbsp;<span style="color: red;">*</span>&nbsp;#{@parent.text_field('record','captcha_result', size: 5)} #{@parent.hidden_field_tag('question', txt )}
   </div>
eot
  end
end

########################################################################
# Return HTML part of code.
########################################################################
def render_html
  captcha_type = @opts[:captcha_type] || @parent.params[:captcha_type]
  return 'DcCaptchaRenderer: Error captcha_type parameter not set!' unless captcha_type

  html = if self.respond_to?(captcha_type)
    send(captcha_type)
  else
    "DcCaptchaRenderer: Error method #{captcha_type} not defined!"
  end

  html
end

end
