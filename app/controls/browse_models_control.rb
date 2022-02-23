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
module BrowseModelsControl

#########################################################################
# Return array of all models found in application.
#########################################################################
def all_collections
  collections = []
  DrgCms.paths(:forms).each do |path|
    models_dir = File.expand_path("../models", path)
    Dir["#{models_dir}/*.rb"].each do |model_file|
      model_file =~ /(.*)\/(.*).rb/
      # check if model exists
      collection = $2.camelize.constantize.new rescue nil
      collections << collection.class.to_s.underscore if collection&.respond_to?(:_id)
    end
  end
  collections.sort
end

######################################################################
# List all collections
######################################################################
def collections
  @records = []
  all_collections.each do |collection|
    @records << DcMemory.new({'id' =>  collection, 'description' => t("helpers.label.#{collection}.tabletitle") })
  end
  @records
end

######################################################################
# List field definition for single model
######################################################################
def all_fields
  @records = []
  model = params[:id].classify.constantize
  document = model.new
  document.attribute_names.each do |attribute_name|
    options = model.fields[attribute_name].options
    description = I18n.t("helpers.help.#{params[:id]}.#{attribute_name}")
    description = I18n.t("helpers.label.#{params[:id]}.#{attribute_name}") if description.match('missing:')
    description = attribute_name if description.match('missing:')

    @records << DcMemory.new({id: attribute_name,
                 'collection' =>  params[:id],
                 'field' => attribute_name, 
                 'type' => options[:type],
                 'description' => description, 
                 '_default' => options[:default]
                })
  end
# embedded documents
  document.embedded_relations.each do |a_embedded|
    embedded = a_embedded.last
    description = I18n.t("helpers.help.#{params[:id]}.#{embedded.key}")
    description = I18n.t("helpers.label.#{params[:id]}.#{embedded.key}") if description.match('missing:')
    description = embedded.key if description.match('missing:')

    @records << DcMemory.new({ id: embedded.key,
                 'collection' =>  params[:id],
                 'field' => embedded.key, 
                 'type' => 'Embedded:' + embedded.class_name,
                 'description' => description
                })
  end

  @records
end

end 
