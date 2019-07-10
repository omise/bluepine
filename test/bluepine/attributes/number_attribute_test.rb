require_relative "base_attribute"

class Bluepine::Attributes::NumberAttributeTest < BaseAttribute
  let(:attribute_type) { :number }

  test_attribute_type { "number" }
  test_native_type { "number" }
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

  describe "#validators" do
    context "when :min option is given" do
      it "should generate :numericality validators" do
        expected = {
          numericality: {
            greater_than_or_equal: 20,
            allow_blank: true,
          },
        }
        actual = create(min: 20).validators

        assert_equal expected, actual
      end
    end

    context "when :max option is given" do
      it "should generate :numericality validators" do
        expected = {
          numericality: {
            less_than_or_equal: 20,
            allow_blank: true,
          },
        }
        actual = create(max: 20).validators

        assert_equal expected, actual
      end
    end
  end
end
