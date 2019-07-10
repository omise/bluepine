require_relative "base_attribute"

class Bluepine::Attributes::CurrencyAttributeTest < BaseAttribute
  let(:attribute_type) { :currency }

  test_attribute_type { "currency" }
  test_native_type { "string" }
  test_default_format { "currency" }

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
