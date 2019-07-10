require "test_helper"

class Bluepine::ValidatorTest < Minitest::Spec
  alias :create :create_validator

  def validate(attribute_type, value, options = {})
    validator = create
    validator.validate(create_attribute(attribute_type, options[:name] || :name, options), value)
  end

  let(:validator) { create }

  TEST_CASES = {
    boolean: {
      valid: [true, false],
      invalid: [1, "test"]
    },
    string: {
      valid: ["a", 'a'],
      invalid: [1, true, 1.5]
    },
    number: {
      valid: [1, 1.2, 4, -4],
      invalid: [true, "test"]
    },
    integer: {
      valid: [1, 2, 3],
      invalid: [true, "test", 1.5]
    },
    float: {
      valid: [1.2, 1.3],
      invalid: [true, "test", 1]
    },
    array: {
      valid: [[], %w[a b], %i[a b]],
      invalid: [1, true, false, {}]
    },
    object: {
      valid: [{}, a: 1, b: 2],
      invalid: [1, true, false, []]
    }
  }

  TEST_CASES.each do |type, cases|
    describe "#visit_#{type}" do
      it "should validate #{type} attribute" do
        cases[:valid].each do |t|
          assert_nil validate(type, t).errors
        end
      end
  
      it "should return errors when data is invalid" do
        expected = ["is not #{type}"]
  
        cases[:invalid].each do |t|
          assert_equal expected, validate(type, t).errors
        end
      end
    end
  end

  describe "Custom normalizer" do
    BooleanAttribute = Bluepine::Attributes::BooleanAttribute

    let(:user_attrs) { create_user_schema }

    context "when using default normalizer" do
      it "should not accept 'on' as valid boolean value" do
        expected = ["is not boolean"]

        assert_equal expected, validate(:boolean, "on").errors
      end
  
      it "should not accept 'on' as valid boolean value for nested attributes" do
        expected = {
          other: ["is not boolean"],
          team: {
            enabled: ["is not boolean"]
          }
        }

        assert_equal expected, validator.validate(user_attrs, other: "on", team: { enabled: "on" }).errors
      end
    end

    context "when overriding default normalizer" do
      before do
        @default = BooleanAttribute.normalizer
  
        # Override default normalizer by accepting "on" as valid boolean value
        BooleanAttribute.normalizer = ->(x) { [true, "on"].include?(x) ? true : false }
      end
  
      after do
        BooleanAttribute.normalizer = @default
      end

      it "should accept 'on' as valid boolean value" do
        assert_nil validate(:boolean, "on").errors
      end

      it "should not affect other attribute" do
        assert_equal ["is not number"], validate(:number, "on").errors
      end
  
      it "should accept 'on' as valid boolean value for nested attributes and cast values" do
        payload  = {
          other: "on",
          team: { enabled: "on" }
        }

        expected = create_result({
          other: true,
          name: "john",
          team: {
            enabled: true
          }
        })

        assert_result expected, validator.validate(user_attrs, payload)
      end
    end
  end

  describe "#visit_array" do
    context "when of: is not given" do
      it "should validate each item in array" do
        values = [1, 2, "string", true, 3.5]

        assert_nil validate(:array, values).errors
      end
    end

    context "when of: is given" do
      it "should validate array attribute" do
        values = (1..5).to_a

        assert_nil validate(:array, values, of: :number).errors
      end

      context "when array contains invalid elements" do
        it "should return errors at invalid position" do
          values   = [1, "me", 2, "me"]
          expected = {
            1 => ["is not number"],
            3 => ["is not number"],
          }

          assert_equal expected, validate(:array, values, of: :number).errors
        end
      end

      context "when of: refers to other schema (e.g. {of: :user})" do
        it "should use given schema to validate each item" do
          user_schema = create_attribute(:object, :user) do
            string :username
            string :password
          end

          resolver = create_resolver(schemas: [user_schema])
          users    = create_attribute(:array, :users, of: :user)
          data     = create_users({}, 3)

          # modify user at #1 to include invalid data
          data[1][:username] = 1234

          result   = create(resolver).validate(users, data).errors
          expected = {
            1 => {
              username: ["is not string"]
            }
          }

          assert_equal expected, result
        end
      end
    end
  end

  describe "#visit_object" do
    it "should validate object attribute" do
      attr = create_attribute(:object, :user) do
        string :username
      end

      value = {
        username: 123
      }

      expected = {
        username: ["is not string"]
      }

      assert_equal expected, validator.validate(attr, value).errors
    end

    describe "condition validation (if/else)" do
      context "when value is Symbol (e.g. if: :other)" do
        before do
          @attr = create_attribute(:object, :user) do
            boolean :other
            string  :note, required: true, if: :other
          end
        end

        it "should not return errors when it evaluates to false" do
          value = {
            other: false
          }

          refute validator.validate(@attr, value).errors
        end

        it "should return errors when it evaluates to true" do
          value = {
            other: true
          }
          expected = {
            note: ["can't be blank"]
          }

          assert_equal expected, validator.validate(@attr, value).errors
        end
      end

      context "when value is Proc (e.g. if: ->(x) { x.status == 'success' })" do
        before do
          @attr = create_attribute(:object, :user) do
            string :status
            string :note, required: true, if: ->(x) { x.status == "success" }
          end
        end

        it "should not return errors when it evaluates to false" do
          value = {
            status: "failed"
          }

          refute validator.validate(@attr, value).errors
        end

        it "should return errors when it evaluates to true" do
          value = {
            status: "success"
          }
          expected = {
            note: ["can't be blank"]
          }

          assert_equal expected, validator.validate(@attr, value).errors
        end
      end
    end
  end

  it "should be able to validate complex object structure" do
    resolver = create_complex_schema
    data     = {
      username: "john",
      password: "doe",
      enabled: true,
      friends: [
        {
          username: "joe"
        },
        {
          username: true,
        }
      ],
      pets: ["Nyan", true],
      address: {
        number: true,
        info: {
          notes: true,
        }
      },
      team: {
        name: 0
      }
    }

    result   = create(resolver).validate(resolver.schema(:user), data).errors
    expected = {
      friends: {
        1 => {
          username: ["is not string"]
        }
      },
      pets: {
        1 => ["is not string"]
      },
      address: {
        number: ["is not integer"],
        info: {
          notes: ["is not string"]
        }
      },
      team: {
        name: ["is not string"]
      }
    }

    assert_equal expected, result
  end
end
