require_relative "base_attribute"

class Bluepine::Attributes::TimeAttributeTest < BaseAttribute
  let(:attribute_type) { :time }

  test_attribute_type { "time" }
  test_native_type { "string" }
  test_default_format { "date-time" }

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
