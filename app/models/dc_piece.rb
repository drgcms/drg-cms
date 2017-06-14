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

########################################################################
# == Schema information
#
# Collection name: dc_piece : Pieces of content
#
#  _id                  BSON::ObjectId       _id
#  created_at           Time                 created_at
#  updated_at           Time                 Last updated at
#  name                 String               Unique name for piece
#  description          String               Short description of piece
#  picture              String               Picture contents of piece
#  thumbnail            String               Small version of picture if available
#  body                 String               Content of this piece
#  css                  String               CSS
#  script               String               Script, if script is included in piece
#  script_type          String               Script type
#  params               String               params
#  piece_id             BSON::ObjectId       Piece
#  div_id               String               Div (position name) id on design where this piece is rendered
#  site_id              BSON::ObjectId       Site name where this piece will belong to
#  order                Integer              Order to be used when pieces are positioned in the same div (location)
#  active               Mongoid::Boolean     Piece is active
#  valid_from           DateTime             Piece is valid from
#  valid_to             DateTime             Piece is valid to
#  created_by           BSON::ObjectId       created_by
#  updated_by           BSON::ObjectId       Last updated by
# 
# DcPiece collection is used for documents or pieces of web site which are common to site 
# or perhaps to all sites in database. For example page footer is a good candidate 
# to be saved in a dc_piece collection.
# 
# Documents in dc_pieces collection must have unique name assigned. Default DcPartRenderer
# also looks into dc_pieces collection and collects all documents which belong to
# current site (site_id field) and renders them according to div_id field value.
########################################################################
class DcPiece 
  include DcPieceConcern

  index( { name: 1 }, { unique: true } )  
  index( { site_id: 1 } ) 
  
  validates :name, uniqueness: true  
  
########################################################################
# Return choices for select for selecting documents on dc_part form.
########################################################################
def self.choices4_pieces
  all.inject([]) { |r,piece| r << [ piece.name, piece._id] }
end
  
end