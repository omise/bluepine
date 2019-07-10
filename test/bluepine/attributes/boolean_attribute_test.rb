require_relative "base_attribute"

class Bluepine::Attributes::BooleanAttributeTest < BaseAttribute
  let(:attribute_type) { :boolean }

  test_attribute_type { "boolean" }
  test_native_type { "boolean" }
  test_default_format { nil }

  test_custom_format do
    ["custom-format", create(format: "custom-format")]
  end

  test_validators do
    [
      {
        inclusion: {
          in: [true, false],
          allow_blank: true
        },
      },
      create
    ]
  end

  describe ":options" do
    context "when no :in options given" do
      it "should use default [true, false] as default" do
        attr = create

        assert_equal [true, false], attr.in
      end
    end

    context "when :in options is given" do
      it "should use given value" do
        attr = create(in: [true])

        assert_equal [true], attr.in
      end
    end
  end
end
