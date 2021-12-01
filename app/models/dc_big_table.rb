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
# == Schema information
#
# Collection name: dc_big_table : Big Table
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  key                  String               Key (ident) used to retrieve key/values
#  description          String               description
#  site_id              BSON::ObjectId       Data will be used only for defined site. If empty, then it is default for all sites in database.
#  active               Mongoid::Boolean     This key is active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  dc_big_table_values  Embedded:DcBigTableValue Values defined by this key
#   
# Big table is meant to be a common space for defining default choices for select fields on forms. 
# Documents are organized as key-value pair with the difference that values for the key can 
# be defined for every site and can also be localized.
# 
# Usage (as used in forms):
# 
# In the example administrator may help user by providing values that can be used 
# on DcAd document position field by defining them in ads-position key of big table.
# Example is from dc_ads.yml form.
# 
#    10:
#      name: position
#      type: text_with_select
#      eval: dc_big_table 'ads-positions'
#      html:
#        size: 20
#        
# dc_big_table collection embeds many DcBigTableValue documents.
##########################################################################
class DcBigTable
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :key,           type: String
  field :description,   type: String
  field :site_id,       type: BSON::ObjectId
  
  field :active,        type: Boolean, default: true
  field :created_by,    type: BSON::ObjectId
  field :updated_by,    type: BSON::ObjectId
  
  embeds_many :dc_big_table_values
  
  index( { key: 1, site_id: 1 } )
  
  validates :key,         presence: true
  validates :description, presence: true
  
########################################################################
# Will return possible choices for specified key prepared for usega in select input field.
########################################################################
def self.choices4(key, site = nil, locale = nil)
  result = []
  choices = find_by(key: key, site: site)
  choices = find_by(key: key, site: nil) if site && choices.nil?
  if choices
    choices.dc_big_table_values.each do |choice| 
      description = choice.description
      if locale
        desc = choice.find_by('dc_big_table_values.locale' => locale)
        description = desc.value if desc
      end             
      result << [description, choice.value]
    end
  end
# Error if empty
  result = [[I18n.t('drgcms.error'),I18n.t('drgcms.error')]] if result.size == 0
  result
end
 
end
