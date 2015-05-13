class NewDrgFormGenerator < Rails::Generators::NamedBase
source_root File.expand_path('../templates', __FILE__)
  
def create_initializer_file
  create_file "app/forms/#{file_name}.rb", "# Add initialization content here"
end
  
end
