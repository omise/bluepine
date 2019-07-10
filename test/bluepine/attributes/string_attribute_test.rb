require_relative "base_attribute"

class Bluepine::Attributes::StringAttributeTest < BaseAttribute
  let(:attribute_type) { :string }

  test_attribute_type { "string" }
  test_native_type { "string" }
  test_default_format { nil }

  test_custom_format do
    ["custom-format", create(format: "custom-format")]
  end

  test_validators do
    [
      {
        length: {
          allow_blank: true,
          minimum: 1,
          maximum: 5,
        },
      },
      create(min: 1, max: 5)
    ]
  end

  describe "#validators" do
    context "when :match is given" do
      it "should generate :format validators" do
        REGEX = /id_\w+/.freeze
        expected = {
          format: {
            with: REGEX,
            allow_blank: true,
          },
        }

        actual = create(match: REGEX).validators

        assert_equal(expected, actual)
      end
    end

    context "when :range is given" do
      it "should generate :length validators" do
        RANGE = 5..20
        expected = {
          length: {
            in: RANGE,
            allow_blank: true,
          },
        }
        actual = create(range: RANGE).validators

        assert_equal expected, actual
      end
    end

    context "when :min is given" do
      it "should generate :length validators" do
        expected = {
          length: {
            minimum: 20,
            allow_blank: true,
          },
        }
        actual = create(min: 20).validators

        assert_equal expected, actual
      end
    end

    context "when :max is given" do
      it "should generate :length validators" do
        expected = {
          length: {
            maximum: 20,
            allow_blank: true,
          },
        }
        actual = create(max: 20).validators

        assert_equal expected, actual
      end
    end
  end
end
