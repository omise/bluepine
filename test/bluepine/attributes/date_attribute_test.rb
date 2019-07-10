require_relative "base_attribute"

class Bluepine::Attributes::DateAttributeTest < BaseAttribute
  let(:attribute_type) { :date }

  test_attribute_type { "date" }
  test_native_type { "string" }
  test_default_format { "date" }

  test_custom_format do
    ["custom-format", create(format: "custom-format")]
  end

  test_validators do
    [
      { },
      create
    ]
  end
end
