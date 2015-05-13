require 'test_helper'
require 'generators/new_drg_form/new_drg_form_generator'

class NewDrgFormGeneratorTest < Rails::Generators::TestCase
  tests NewDrgFormGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
