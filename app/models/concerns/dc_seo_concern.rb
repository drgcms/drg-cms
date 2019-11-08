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

##########################################################################
# == Schema information
#
# dc_seo_concern
#
# title                String               Browser title. Optimization for SEO.
# meta_description     String               SEO optimised page description
# meta_additional      String               Additional meta page data. Enter as meta_name=meta data
# dc_json_lds          Embedded:DcJsonLd    Page structure data
# 
# Ads SEO optimization fields to any model. If you want to add SEO optimization
# data to your document add:
# 
# "include DcSeoConcern" to your model definition
# 
# and
# 
# "include: dc_seo" option to top of DRGCMS edit form for your document.
##########################################################################
module DcSeoConcern
extend ActiveSupport::Concern

included do  
  field :title,            type: String
  field :meta_description, type: String
  field :canonical_link,   type: String
  embeds_many :dc_json_lds # JSON-LD structure
end

end
