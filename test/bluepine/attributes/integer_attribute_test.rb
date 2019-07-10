require_relative "base_attribute"

class Bluepine::Attributes::IntegerAttributeTest < BaseAttribute
  let(:attribute_type) { :integer }

  test_attribute_type { "integer" }
  test_native_type { "integer" }
  test_default_format { nil }

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
