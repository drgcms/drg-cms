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
# == Schema information
#
# Collection name: dc_memory : Collection name used when form does not belong to database model.
# 
# Which is not collection at all. DcMemory model is used for entering data on forms 
# where data will not be saved to database but will instead be saved only to memory as 
# temporary variable and processed by custom made methods. 
# For example, define start and end date when making a timeline report.
# 
# Example (as used in forms):
# 
#    table: dc_memory
#    title: Enter time period
#
#      form:
#        actions:
#          1:
#            type: ajax
#            method: post
#            controller: reports
#            action: do_some_report
#            caption: Run report
#
#        fields:
#          10:
#            name: date_start
#            type: date_picker
#            caption: Start date
#          20:
#            name: date_end
#            type: date_picker
#            caption: End date
#            
# And suppose your report saved data to file named public/report.pdf. 
# Put this line at the end of do_some_report method:
# 
#    render inline: { :window_report => '/report.pdf' }.to_json, formats: 'js'
#    
# As result report.pdf file will be opened in new browser window.
########################################################################
class DcMemory
include Mongoid::Document

########################################################################
# Initilize object
########################################################################
def initialize(parms = {})
  @internals = {}
  parms.each { |key, value| @internals[key.to_s] = value } if parms
end

########################################################################
# Return id field
########################################################################
def id()
  @internals['id']
end

########################################################################
# Respond_to should always return true.
########################################################################
def id=(value)
  @internals['id'] = value
end

########################################################################
# Respond_to should always return true.
########################################################################
def respond_to?(m)
  true
end

########################################################################
# Redefine send method. Send is used to assign or access value by cmsedit controller.
########################################################################
def send(field,value=nil)
  field = field.to_s
  if field.match('=')
    field.chomp!('=')
    @internals ||= {}
    @internals[field] = value
  else
    @internals[field]
  end
end

########################################################################
# Redefine [] method to act similar as send method
########################################################################
def [](field)
  return nil unless @internals
  @internals[field.to_s]
end

########################################################################
# Redefine [] method to act similar as send method
########################################################################
def []=(field, value)
  @internals ||= {}
  @internals[field.to_s] = value
end

########################################################################
# For debugging purposes
########################################################################
def to_s
  "DcMemory: @internals=#{@internals.size} #{@internals}"
end
  
########################################################################
# Method missing will return value if value defined by m parameter is saved to
# @internals array or will save field value to @internals hash if m matches '='.
########################################################################
def method_missing(m, *args, &block) #:nodoc:
  @internals ||= {}
  m = m.to_s
  if m.match('=')
    m.chomp!('=')
    @internals[m] = args.first
  else
    @internals[m]
  end   
end

end
