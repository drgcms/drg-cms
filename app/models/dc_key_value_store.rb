#--
# Copyright (c) 2014+ Damjan Rems
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

#########################################################################
# == Schema information
#
# Collection name: dc_key_value_store : Table used for storing all kind of values
#
#  _id                  BSON::ObjectId       _id
#  key                  String               Identification key
#  value                String               Stored value
# 
# This model represents key/value store. Typical usage is for saving last
# used document number on internal document numbering schema.
# 
# Example: 
#    doc_number = DcKeyValueStore.get_next_value('invoices', invoice_date.year)
#########################################################################
class DcKeyValueStore
  include Mongoid::Document
  
  field :key,       type: String
  field :value,     type: String
  
  index( { key: 1 }, { unique: true } )  

###########################################################################
# Will return value incremented by 1 and update document with new value.
# 
# Parameters: 
# [keys] Array. Any number of parameters from which key will be generated.
# 
# Returns:
# String. Last saved value incremented by 1.
###########################################################################
def self.get_next_value(*keys)
  doc   = find_by(key: keys.join('-'))
  value = (doc ? doc.value : '0').next
  if doc
    doc.value = value
    doc.save!
  else
    create(key:  keys.join('-'), value: value)
  end
  value
end

###########################################################################
# Will try to restore to previous value if value is not already incremented.
# 
# Parameters: 
# [value] String. Last value obtained by get_next_value method.
# [keys] Array. Any number of parameters from which key will be generated.
###########################################################################
def self.restore_value(value, *keys)
  doc = find_by(key: keys.join('-'))
  if value == doc.value
    value = (value.to_i - 1).to_s
    doc.value = value
    doc.save!
    return value
  end
  nil
end

###########################################################################
# Will return value incremented by 1 but will not update document with new value.
# Used for presenting user with most possible document number. Real document number must
# of course be obtained by get_next_value before document is saved to collection.
# 
# Parameters: 
# [keys] Array. Any number of parameters from which key will be generated.
# 
# Returns:
# String. Last saved value incremented by 1.
###########################################################################
def self.peep_next_value(*keys)
  doc = find_by(key: keys.join('-'))
  (doc ? doc.value : '0').next  
end

###########################################################################
# Will return current value for the key.
# 
# Parameters: 
# [keys] Array. Any number of parameters from which key will be generated.
# 
# Returns:
# String. Current value for specified key or nil if key is not found.
###########################################################################
def self.get_value(*keys)
  doc = find_by(key: keys.join('-'))
  doc ? doc.value : nil
end

###########################################################################
# Will set value for the key. If document is not found new document will be created.
# 
# Parameters: 
# [value] String. New value to be set.
# [keys] Array. Any number of parameters from which key will be generated.
###########################################################################
def self.set_value(value, *keys)
  doc = find_by(key: keys.join('-'))
  if doc
    doc.value = value
    doc.save!
  else
    create(key:  keys.join('-'), value: value)
  end
  value
end

end
