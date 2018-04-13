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
# ActiveSupport::Concern definition for DcUser class. 
#########################################################################
module DcUserConcern
extend ActiveSupport::Concern
included do
@@countries = nil

include Mongoid::Document
include Mongoid::Timestamps
include ActiveModel::SecurePassword

field :username,    type: String, default: ''
field :title,       type: String, default: ''
field :first_name,  type: String, default: ''
field :middle_name, type: String, default: ''
field :last_name,   type: String, default: ''
field :name,        type: String
field :company,     type: String, default: ''
field :address,     type: String
field :post,        type: String
field :country,     type: String
field :phone,       type: String
field :email,       type: String
field :www,         type: String
field :picture,     type: String
field :birthdate,   type: Date
field :about,       type: String
field :last_visit,  type: Time
field :active,      type: Boolean, default: true
field :valid_from,  type: Date
field :valid_to,    type: Date
field :created_by,  type: BSON::ObjectId
field :updated_by,  type: BSON::ObjectId

field :type,        type: Integer, default: 0 # 0 => User, 1 => Group
field :members,     type: Array

embeds_many :dc_user_roles

# for forum
field :signature,   type: String
field :interests,   type: String
field :job_occup,   type: String
field :description, type: String  
field :reg_date,    type: Date

field :password_digest,  type: String
has_secure_password

index( { username: 1 }, { unique: true } )
index( { email: 1 }, { unique: true } )
index 'dc_user_roles.dc_policy_role_id' => 1  

index 'members' => 1  

validates_length_of :username, minimum: 4
before_save :do_before_save

##########################################################################
# before_save callback takes care of name field and ensures that e-mail is unique 
# when entry is left empty. 
##########################################################################
def do_before_save
  self.name  = "#{self.title} #{self.first_name} #{self.middle_name + ' ' unless self.middle_name.blank?}#{self.last_name}".strip
# to ensure unique e-mail            
  self.email = "unknown@#{self.id}" if self.email.to_s.strip.size < 5
end

##########################################################################
# Checks if user has role 'role_id' defined in his roles
##########################################################################
def has_role?(role_id)
  return false unless role_id
#
  unless BSON::ObjectId.legal?(role_id)
    role    = DcPolicyRole.get_role(role_id)
    role_id = role.id if role
  end
  role = self.dc_user_roles.where(dc_policy_role_id: role_id)
  (role && role.active?)
end

##########################################################################
# Will return all possible values for country field ready for input in select field. 
# Values are loaded from github when method is first called.
##########################################################################
def self.choices4_country()
  if @@countries.nil?
    uri = URI.parse("https://raw.githubusercontent.com/umpirsky/country-list/master/country/cldr/en/country.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)    
    @@countries = JSON.parse(response.body).to_a.inject([]) {|result, e| result << [e[1], e[0]] }
  end
  @@countries
end

##########################################################################
# Performs ligically test on passed email parameter.
# 
# Parameters:
# [email] String: e-mail address
# 
# Returns:
# Boolean: True if parameter is logically valid email address.
# 
# Example:
#    if !DcUser.is_email?(params[:email])
#      flash[:error] = 'e-Mail address is not valid!'
#    end
# 
##########################################################################
def self.is_email?(email)
  email.to_s =~ /^[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
end

end
end
