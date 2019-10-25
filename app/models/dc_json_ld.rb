#--
# Copyright (c) 2019+ Damjan Rems
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
# Collection name: dc_json_ld : JSON_LD data for site optimization
#
#  _id                  BSON::ObjectId       _id
#  type                 String               Type of structure
#  data                 String               Structure data in YAML
#  dc_json_lds          Object               Can embed substructure
#  created_at           Time                 created_at
#  updated_at           Time                 Last updated at
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       Last updated by
# 
########################################################################
class DcJsonLd 
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type,        type: String
  field :data,        type: String
  field :active,      type: Boolean,      default: true

  embeds_many :dc_json_lds, :cyclic => true

  field :created_by,  type: BSON::ObjectId
  field :updated_by,  type: BSON::ObjectId

  
##########################################################################
# Returns JSON LD data as YAML
##########################################################################
def get_json_ld(parent_data)
  yaml = YAML.load(self.data) rescue {}
  yaml['@type'] = self.type if yaml.size > 0
  if dc_json_lds.size > 0
    dc_json_lds.each do |element|
      yml = element.get_json_ld(parent_data)
      if yml.size > 0
        yaml[element.type] ||= []
        yaml[element.type] << yml 
      end
    end
  end
  yaml
end
  
end