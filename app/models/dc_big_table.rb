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
# Mongoid::Document model for dc_big_table collection.
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
def self.choices4(key, site, locale=nil)
  a = []
  r = find(key: key, site: site)
  if r
    r.dc_big_table_values.each do |v| 
      desc = v.description
      if locale
        d = v.find('dc_big_table_values.locale' => locale)
        desc = d.value if d
      end             
      a << [v.value, desc]
    end
  end
# Error if empty
  a = [[I18n.t('drgcms.error'),I18n.t('drgcms.error')]] if a.size == 0
  a
end
 
end
