require "test_helper"

class Bluepine::AttributesTest < Minitest::Spec
  alias :create :create_attribute

  def validate_attribute_validators(type, expected, **options)
    object   = create(type, "name", **options)
    result   = object.validators

    assert_equal expected, result
  end

  describe "#validator" do
    context "when required: true" do
      it "should generate :presence validator" do
        expected = {
          presence: true,
        }

        validate_attribute_validators(:string, expected, required: true)
      end
    end

    context "when null: true" do
      it "should add :allow_nil option to validator" do
        expected = {
          allow_nil: true,
        }

        validate_attribute_validators(:string, expected, null: true)
      end
    end

    context "when :in is given" do
      it "should generate :inclusion validator" do
        valid = %w[yes no]
        expected = {
          inclusion: {
            in: valid,
            allow_blank: true,
          },
        }

        validate_attribute_validators(:string, expected, in: valid)
      end
    end
  end

  describe "#rules" do
    it "should build validation rules based on given ruleset" do
      rules = {
        min: {
          name: :minimum,
          group: :length,
        },
      }
      expected = {
        length: {
          minimum: 20,
          allow_blank: true,
        },
      }
      result = create(:string, :test).send(:rules, rules, { min: 20 })

      assert_equal expected, result
    end

    context "when rule name not exists in options" do
      it "should not include that rule" do
        rules = {
          min: {},
        }
        expected = {}
        result = create(:string, :test).send(:rules, rules, { max: 20 })

        assert_equal expected, result
      end
    end
  end

  describe ":options" do
    context "when passing custom option (not defined in option list)" do
      it "should keep that options" do
        attr = create(:string, :name, custom_option: true)

        assert_equal true, attr.options[:custom_option]
      end
    end
  end
end
