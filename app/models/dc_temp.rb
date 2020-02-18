#--
# Copyright (c) 2020+ Damjan Rems
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
# Collection name: dc_temp : Collection used for temporary saving of any models data
# 
# dc_temp collection has only two fields. Key and Data hash. Data must be populated 
# prior to for display best in dc_new_record callback.
# 
########################################################################
class DcTemp
  include Mongoid::Document
  include Mongoid::Timestamps
  field :key,     type: String
  field :data,    type: Hash,     default: {}
  field :active,  type: Time,     default: Time.now
  
  index key: 1
  
########################################################################
# Initilize object
########################################################################
def initialize(parms = {})
  super()
  parms.stringify_keys!
  self.key = parms.delete('key')  if parms['key']
  self.key = parms.delete('active') if parms['active']
  parms.each { |k, value| self.data[k] = value }
end

########################################################################
# 
########################################################################
def __id()
  self.data['id']
end

########################################################################
# Respond_to should always return true.
########################################################################
def respond_to?(a=nil,b=nil)
  true
end

########################################################################
# Redefine send method. Send is used to assign or access value by cmsedit controller.
########################################################################
def send(field,value=nil)
  return super(field) if field.is_a? Symbol
  field = field.to_s
  if field.match('=')
    field.chomp!('=')
    self.data[field] = value
  else
    self.data[field]
  end
end

########################################################################
# Redefine [] method to act similar as send method
########################################################################
def [](field)
  self.data[field.to_s]
end

########################################################################
# Redefine [] method to act similar as send method
########################################################################
def []=(field, value)
  self.data[field.to_s] = value
end

########################################################################
# For debugging purposes
########################################################################
def to_s
  "DcTemp: @key=#{self.key} @data=#{self.data.inspect}"
end
  
########################################################################
# Method missing will return value if value defined by m parameter is saved to
# @internals array or will save field value to @internals hash if m matches '='.
########################################################################
def method_missing(m, *args, &block) #:nodoc:
  m = m.to_s
  if m.match('=')
    m.chomp!('=')
    self.data[m] = args.first
  else
    self.data[m]
  end   
end

########################################################################
# Remove all documents with specified key from dc_temp collection
########################################################################
def self.clear(key)
  self.where(key: key).delete
end

########################################################################
# Prepare dc_temp for data. It first checks if data associated with the key is to
# be deleted and then yields block code. 
# 
# Returns: Query for the data associated with the key
########################################################################
def self.prepare(key:, clear: nil)
  unless %w(no false 0).include?(clear.to_s.strip.downcase)
    self.clear(key)
    yield
  end
  self.where(key: key) 
end

end
