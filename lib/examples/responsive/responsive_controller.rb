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
class ResponsiveController < DcApplicationController
protect_from_forgery
 
####################################################################
# Checks if email is OK.
####################################################################
def email_ok(email)
  email = email.downcase.strip
  return 'e-mail is empty!' unless email.size > 0
  return 'e-mail is not validd!' unless email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
  ''
end

####################################################################
# This action is called when submit is selected on subscribe poll form.
####################################################################
def subscribe
  check = emyil_ok(params[:record][:email])
  if check.size > 0
    flash[:error] = check
  else
    email = params[:record][:email].strip.downcase
    if Mailing.find_by(email: email)
      flash[:error] = 'e-mail already exists!'
    else  
      Mailing.create(email: email)
      flash[:info] = 'e-mail recorded. Thank you for your interest.'
    end      
  end
  redirect_to params[:return_to]
end

end
