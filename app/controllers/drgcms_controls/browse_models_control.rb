#encoding: utf-8
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

######################################################################
# 
######################################################################
module DrgcmsControls::BrowseModelsControl
include DcApplicationHelper

#########################################################################
# Determine model class from filename.
#########################################################################
def determine_model(path)
  path =~ /(.*)\/(.*).rb/
  begin
    $2.camelize.constantize 
  rescue Exception # it happends
    nil
  end
end

#########################################################################
# Return array of all models found in application.
#########################################################################
def all_models()
  models = []
  DrgCms.paths(:forms).each do |path|
    models_dir = File.expand_path("../models", path)
    Dir["#{models_dir}/*.rb"].each do |model_file| 
      model = determine_model(model_file)
      models << model if !model.nil? and model.respond_to?(:index_specifications)
    end
  end
  models
end

######################################################################
# List all models
######################################################################
def models()
  @records = []
  models = dc_choices4_all_collections
  models.each do |model|
    @records << {'id' =>  model.last, 'description' => model.first} 
  end
  @records
end

######################################################################
# List field definition for single model
######################################################################
def fields()
  @records = []
  model = params[:id].classify.constantize
  document = model.new
  document.attribute_names.each do |attr_name|
    @records << {'collection' =>  params[:id], 'field' => attr_name, 'type' => document['attr_name'].class } 
  end
  @records
end

end 
