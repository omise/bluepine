require_relative "base_attribute"

class Bluepine::Attributes::ArrayAttributeTest < BaseAttribute
  let(:attribute_type) { :array }

  test_attribute_type { "array" }
  test_native_type { "array" }
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
    context "when no :of options given" do
      it "should return nil" do
        attr = create

        assert_nil attr.of
      end
    end

    context "when :of options is given" do
      it "should use given value" do
        attr = create(of: :card)

        assert_equal :card, attr.of
      end
    end
  end
end
