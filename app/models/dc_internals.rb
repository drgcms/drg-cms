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

##########################################################################
# Internals model represents bridge to action's internal variables like 
# session, params, record ... They are used for interacting with user in terms
# they understand and provides internal values behind the scene. 
##########################################################################
module DcInternals
  INTERNALS = {
    'current_user' => 'session[:user_id]',
    'current_user_name' => 'session[:user_name]',
    'current_site' => 'dc_get_site.id'
  }
#
  @additions = {}
  
##########################################################################
# Add additional internal. This method allows application specific internals 
# to be added to structure and be used together with predefined values.
##########################################################################
def self.add_internal(hash)
  hash.each {|key,value| additions[key] = value} 
end

##########################################################################
# Add additional internal. This method allows application specific internals 
# to be added to structure and be used together with predefined values.
##########################################################################
def self.get(key)
  key = key.sub('@','')

  value = INTERNALS[key]
  value = @additions[key] if value.nil?
  value
end

end
