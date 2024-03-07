#--
# Copyright (c) 2024+ Damjan Rems
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

##############################################################################
# DcSetup collection is used for settings, that are specific to the application,
# or part of application (gem). It consists of data dafinitions and form for editing data.
# Data is saved internaly in YAML format.
#
# When editing, admin can see and edit form definition (adding new data to application setup), while user
# sees only data entry form.
#
# Usage:
#   my_app_settings = DcSetup.find_by(name: 'my_app')
#   my_app_settings = DcSetup.get('my_app')
#   company = my_app_settings.company_name
#   company, ceo = my_app_settings[:company_name, 'ceo_name']
#
##############################################################################
class DcSetup
include Mongoid::Document
include Mongoid::Timestamps

attr_reader :my_data
attr_reader :my_fields

field :name,      type: String, default: ''
field :data,      type: String, default: ''
field :form,      type: String, default: ''
field :editors,   type: Array,  default: []

field :created_by,  type: BSON::ObjectId
field :updated_by,  type: BSON::ObjectId

index name: 1

validates_length_of :name, minimum: 3

before_save do
  self.data = my_data.to_yaml
end

##############################################################################
# Will return settings record for specified application.
#
# @param [String] app_name The name of the application
# @return [Object, nil] The settings record if found, nil otherwise
##############################################################################
def self.get(app_name)
  DcSetup.find_by(name: app_name.to_s)
end

##############################################################################
# Will return value for single setting if called as method.
##############################################################################
def method_missing(m, *args, &block)
  m = m.to_s
  if m.match('=')
    m.chomp!('=')
    my_data[m] = args.first
  else
    my_data[m]
  end
end

##############################################################################
# Will return value for single setting. Called as parameter in square brackets.
# If more then one parameter is passed it will return them as array.
##############################################################################
def [](*keys)
  return my_data[keys.first.to_s] if keys.size == 1

  keys.inject([]) { |r, k| r << my_data[k.to_s] }
end

##############################################################################
# Will return true if setting is defined on the form
##############################################################################
def respond_to?(field_name)
  return true #if my_fields[field_name.to_s]

  super.respond_to?(field_name)
end

##############################################################################
#
##############################################################################
def my_data
  @my_data ||= (YAML.unsafe_load(data)) || {}
end

end
