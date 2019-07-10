require_relative "base_attribute"

class Bluepine::Attributes::IPAddressAttributeTest < BaseAttribute
  let(:attribute_type) { :ip_address }

  test_attribute_type { "ip_address" }
  test_native_type { "string" }
  test_default_format { nil }

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
