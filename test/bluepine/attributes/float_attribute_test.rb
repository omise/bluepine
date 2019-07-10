require_relative "base_attribute"

class Bluepine::Attributes::FloatAttributeTest < BaseAttribute
  let(:attribute_type) { :float }

  test_attribute_type { "float" }
  test_native_type { "number" }
  test_default_format { "float" }

  test_custom_format do
    ["custom-format", create(format: "custom-format")]
  end

  test_validators do
    [
      {
        numericality: {
          allow_blank: true,
          greater_than_or_equal: 1,
          less_than_or_equal: 5,
        },
      },
      create(min: 1, max: 5)
    ]
  end
end
