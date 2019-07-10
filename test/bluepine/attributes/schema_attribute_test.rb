require_relative "base_attribute"

class Bluepine::Attributes::SchemaAttributeTest < BaseAttribute
  let(:attribute_type) { :schema }

  test_attribute_type { "schema" }
  test_native_type { "object" }
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

  describe ":options" do
    context "when of: option is not given" do
      it "should automatically add #name to options[:of]" do
        attr = create(name: :user)

        assert_equal :user, attr.name
        assert_equal :user, attr.options[:of]
      end
    end
  end
end
