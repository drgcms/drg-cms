class ConvertToArGenerator < Rails::Generators::NamedBase
  
source_root File.expand_path('../templates', __FILE__)
desc "This generator converts mongoid model to active_record migration"
argument :model_name, :type => :string, :default => 'dc_*'
argument :migration_name, :type => :string, :default => 'initial_migration'

TYPES = {
  String => :string,
  Time => :datetime,
  DateTime => :datetime,
  Object => :integer,
  Integer => :integer,
  BSON::ObjectId => :integer,
  Mongoid::Boolean => :boolean,
  BigDecimal => [:decimal, :precision => 8, :scale => 2, :default => 0.00],
  Date => :date,
  Hash => :text,
  Array => :text
}

###########################################################################
#
###########################################################################
def create_migration
  p model_name, migration_name

  code = model_name.match(/\*/) ? migrate_many(model_name) : migrate_one(model_name)
  code = top(migration_name) + code + bottom
  create_file "db/#{source_file_name(migration_name).underscore}.rb", code
end

private

###########################################################################
#
###########################################################################
def source_file_name(migration)
  "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{migration}"
end

###########################################################################
#
###########################################################################
def migrate_one(model_name)
  mongo_model = model_name.classify.constantize
  new_model_name = model_name.start_with?('dc_') ? model_name.sub('dc_', 'ar_') : model_name
  code = %(    create_table :#{new_model_name.pluralize} do |t|\n)
  left = '      t.'
  timestamps = false
  # fields
  document = mongo_model.new
  document.attribute_names.each do |attribute_name|
    next if attribute_name == '_id'
    if %w[created_at updated_at].include?(attribute_name)
      timestamps = true
      next
    end

    options = mongo_model.fields[attribute_name].options
    pp "Undefined type #{options[:type]} for #{mongo_model}.#{attribute_name}" unless TYPES[options[:type]]
    att_name = attribute_name.sub(/^dc_/,'ar_')
    code << %(#{left}#{TYPES[options[:type]]} :#{att_name})
    code << %(, default: #{get_default(options[:default], options[:type])}) if options[:default]
    code << "\n"
  end
  code << %(\n#{left}timestamps\n) if timestamps

  # indexes
  if document.index_specifications.any?
    code << "\n"
    document.index_specifications.each do |index|
      code << "#{left}index "
      code << (index.fields.size > 1 ? "[:#{index.fields.join(', :')}]" : ":#{index.fields.first}")
      code << ", #{index.options.to_s.gsub(/\{|\}/, '')}" if index.options.size > 0
      code << "\n"
    end
  end

  # export some test data
  data = []
  mongo_model.all.limit(5).each do |doc|
    #data << doc.as_document.inject([]) { |r, e| [e.first.sub(/^dc_/,'ar_'), e.last] }
    data << doc.as_document.map { |e| [e.first.sub(/^dc_/,'ar_'), e.last] }
  end
  File.write("db/#{new_model_name}.json", data.to_json)

  code << "    end\n\n"
end

###########################################################################
#
###########################################################################
def get_default(default, type)
  case type.to_s
  when 'String' then "'#{default}'"
  else default
  end
end

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

###########################################################################
#
###########################################################################
def migrate_many(model_name)
  selector = model_name[0, model_name.index('*') - 1].downcase
  p selector

  list = all_collections.select { |name| name.starts_with?(selector) }
  list.inject('') { |r, e| r << migrate_one(e) }
end

###########################################################################
#class #{migration_name} < ActiveRecord::Migration[7.0]
#   def change
#     create_table :products do |t|
#       t.string :name
#       t.text :description
#
#       t.timestamps = true
#     end
#   end
# end
###########################################################################
def top(migration_name)
  <<EOT
class #{migration_name.classify} < ActiveRecord::Migration[7.0]
  def change
EOT
end

###########################################################################
#
###########################################################################
def bottom
  <<EOT
  end
end
EOT
end

end
