#coding: utf-8
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
# == Schema information
#
# Collection name: dc_page : Pages
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 Updated
#  subject              String               Articles subject
#  title                String               Browser title. Optimization for SEO.
#  subject_link         String               Friendly link defined
#  alt_link             String               Alternative link, by which page could be found
#  sub_subject          String               Sub subject, short description of text
#  picture              String               Picture used in conjunction with page
#  gallery              String               Gallery pictures are defined in parts of page. Value defines name of parts which hold data about pictures in gallary.
#  body                 String               Content of this page
#  css                  String               CSS only for this menu page
#  script               String               Javascript only for this page
#  params               String               Special parameters which may come handy when displaying page
#  menu_id              BSON::ObjectId       Top menu under where this page is displayed
#  author_id            BSON::ObjectId       Author of the article
#  dc_poll_id           BSON::ObjectId       Select poll, if poll is to be used with page
#  author_name          String               Author of the article
#  publish_date         DateTime             Publish date
#  user_name            String               user_name
#  valid_from           DateTime             Article is valid from date
#  valid_to             DateTime             Article is valid to date
#  comments             Integer              Comments on this article are allowed
#  active               Mongoid::Boolean     Page is active
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       updated_by
#  kats                 Array                Categories for this article
#  policy_id            BSON::ObjectId       Access policy for the page
#  dc_site_id           Object               dc_site_id
#  dc_design_id         Object               Design used for rendering page
#  dc_parts             Embedded:DcPart      Parts of the article
# 
# DcPage documents are anchors for urls. Default DcApplicationController::dc_process_default_request() 
# method searches for DcPage document by subject_link, id or alt_link. When found it loads 
# design document defined by design_id and renders view code defined by design. 
# 
# Site owner has all control of how DcPage data is rendered by providing its own page renderer methods.
# 
# Every DcPage document may embed many DcPart documents. DcPart documents mostly contain fields
# with same names and functionality as DcPage fields. And may therefore represent whole subpage data
# system within single document. Clever programmer may provide data for whole web site in just 
# one DcSite, one DcMenu, one DcDesign and one DcPage document (with some embedded documents). And since 
# DRG runs multiple sites on single Rails instance by default, may run hundreds of small sites
# on single Rails instance.
#########################################################################
class DcPage
  include DcPageConcern
end
