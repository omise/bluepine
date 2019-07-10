require_relative "base_attribute"

class Bluepine::Attributes::UriAttributeTest < BaseAttribute
  let(:attribute_type) { :uri }

  test_attribute_type { "uri" }
  test_native_type { "string" }
  test_default_format { "uri" }

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
