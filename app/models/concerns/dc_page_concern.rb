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

#########################################################################
# ActiveSupport::Concern definition for DcPage class. 
#########################################################################
module DcPageConcern
extend ActiveSupport::Concern
included do
  
include Mongoid::Document
include Mongoid::Timestamps

field :subject,      type: String,  default: ''
field :subject_link, type: String,  default: ''
field :alt_link,     type: String,  default: ''
field :sub_subject,  type: String,  default: ''
field :picture,      type: String   
field :gallery,      type: Boolean, default: false   
field :body,         type: String,  default: ''
field :css,          type: String,  default: ''
field :script,       type: String,  default: ''
field :params,       type: String
field :menu_id,      type: String
field :author_id,    type: BSON::ObjectId
field :dc_poll_id,   type: BSON::ObjectId
field :author_name,  type: String
field :publish_date, type: DateTime
field :user_name,    type: String
field :valid_from,   type: DateTime
field :valid_to,     type: DateTime
field :comments,     type: Integer, default: 1  # 0 => not allowed, 1 => allowed
field :active,       type: Boolean, default: true 
field :created_by,   type: BSON::ObjectId
field :updated_by,   type: BSON::ObjectId
field :kats,         type: Array         # Categories
# IFRAME
field :if_url,       type: String
field :if_border,    type: Integer, default: 0
field :if_width,     type: Integer
field :if_height,    type: Integer
field :if_scroll,    type: String
field :if_id,        type: String
field :if_class,     type: String
field :if_params,    type: String

# SEO
include DcSeoConcern

field :policy_id,    type: BSON::ObjectId

embeds_many :dc_parts

belongs_to  :dc_site,   optional: true
belongs_to  :dc_design, optional: true

index  ({ dc_site_id: 1, subject_link: 1 })
index  kats: 1
index  alt_link:  1

before_save :do_before_save

validates :publish_date, presence: true
validate  :validate_images_alt_present

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  DrgCms.cache_clear(:dc_page)
end
  
######################################################################
# Will return subject_link. Field name link should be common for all documents
# which can be found with links.
######################################################################
def link
  subject_link
end
   
######################################################################
# Will return validation error if all images in body field do not have 
# alt attribute present.
######################################################################
def validate_images_alt_present
  errors.add('body', I18n.t('drgcms.img_alt_not_present')) unless DcPage.images_alt_present?(self.body)
end

protected

######################################################################
# Implementation of before_save callback.
######################################################################
def do_before_save
  if self.subject_link.empty?
    self.subject_link = DcPage.clear_link(self.subject.downcase.strip) 
    # add id to link, but only if something is written in subject   
    self.subject_link << "-#{self.id.to_s}" if self.subject_link.size > 1 
  end
# menu_id is returned as string Array class if entered on form as tree_select object.
  self.menu_id = self.menu_id.scan(/"([^"]*)"/)[0][0] if self.menu_id.to_s.match('"')
end

######################################################################
# Clears subject link of chars that shouldn't be there and also takes care 
# than link size is not larger than 100 chars.
######################################################################
def self.clear_link(link)
  link.gsub!(/\.|\?|\!\&|\||»|«|\,|\"|\'|\:/,'')
  link.gsub!('<br>','')
  link.gsub!('–','-')
  link.gsub!(' ','-')
  link.gsub!('---','-')
  link.gsub!('--','-')
# it shall not be greater than 100 chars. Don't break in the middle of words  
  if link.size > 100
    link = link[0,100]
    link.chop! until link[-1,1] == '-' or link.size < 10 # delete until -
  end
  link.chop! if link[-1,1] == '-' # remove - at the end
  link
end

######################################################################
# Return all pages belonging to site ready for select input field. Used
# by dc_menu* forms, for selecting page which will be linked by menu option.
# 
# Parameters:
# [site] Site document.
######################################################################
def self.all_pages_for_site(site)
  only(:subject, :subject_link).where(dc_site_id: site._id, active: true).order(subject: 1).
    inject([]) { |r,page| r << [ page.subject, page.subject_link] }
end

########################################################################
# Return filter options
########################################################################
def self.dc_filters
  {'title' => 'drgcms.filters.this_site_only', 'operation' => 'eq', 
   'field' => 'dc_site_id', 'value' => '@current_site'}
end

######################################################################
# Clears subject link of chars that shouldn't be there and also takes care 
# than link size is not larger than 100 chars.
######################################################################
def self.images_alt_present?(text)
  return true if text.blank?
#  
  document = Nokogiri::HTML.parse(text)
  document.xpath('//img').each do |image|
    return false if !image.attributes['alt'] or image.attributes['alt'].text.blank?
  end
  true
end

end

end
