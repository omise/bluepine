require_relative "../base_test_case"

class Bluepine::Generators::OpenAPI::PropertyGeneratorTest < Bluepine::Generators::BaseTest
  def setup; end

  def generate_property(object, options = {})
    Bluepine::Generators::OpenAPI::PropertyGenerator.visit(object, options)
  end

  describe "#generate" do
    context "when no options is given" do
      it "should generate correct property" do
        expected = {
          type: "integer",
        }
        object = create_attribute(:integer, :amount)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    context "when :description is given" do
      it "should generate property with description" do
        expected = {
          type: "integer",
          description: "Total amount",
        }
        object = create_attribute(:integer, :amount, description: "Total amount")
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    context "when :in is given" do
      it "should add :enum to property" do
        expected = {
          type: "string",
          enum: %w[usd thb],
        }
        object = create_attribute(:string, :currency, in: %w[usd thb])
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    context "when null: true" do
      it "should add nullable: true to property" do
        expected = {
          type: "string",
          nullable: true,
        }
        object = create_attribute(:string, :currency, null: true)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    context "when :default is given" do
      it "should add default value to property" do
        expected = {
          type: "string",
          default: :thb,
        }
        object = create_attribute(:string, :currency, default: :thb)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    context "when :match is given" do
      it "should add regex to `pattern` property" do
        REGEX = /test_\w+/.freeze

        expected = {
          type: "string",
          pattern: REGEX.source,
        }
        object = create_attribute(:string, :id, match: REGEX)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    context "when :schema is given" do
      it "should include original schema name" do
        expected = {
          type: "string",
          default: :thb,
          "x-omise-schema" => :account,
        }
        object = create_attribute(:string, :currency, default: :thb)
        result = generate_property(object, schema: :account)

        assert_equal expected, result
      end
    end

    describe "when attribute is Symbol" do
      it "should generate $ref" do
        result   = generate_property(:user)
        expected = {
          :$ref => "#/components/schemas/user",
        }

        assert_equal expected, result
      end
    end

    describe "format property" do
      context "when Attribute doesn't have default :format value" do
        it "should not add format property to result" do
          object   = create_attribute(:string, :currency)
          result   = generate_property(object)

          assert_nil result[:format]
        end
      end

      context "when Attribute have default :format value" do
        it "should add format property to result" do
          object   = create_attribute(:time, :created)
          result   = generate_property(object)
          expected = {
            type: "string",
            format: "time",
          }

          assert expected, result
        end
      end

      context "when custom :format value is given" do
        it "should override default :format value" do
          object   = create_attribute(:time, :created, format: "int64")
          result   = generate_property(object)
          expected = {
            type: "string",
            format: "int64",
          }

          assert expected, result
        end
      end
    end

    describe "#visit_string" do
      it "should generate string property" do
        expected = {
          type: "string",
        }
        object = create_attribute(:string, :email)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    describe "#visit_integer" do
      it "should generate integer property" do
        expected = {
          type: "integer",
        }
        object = create_attribute(:integer, :amount)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    describe "#visit_boolean" do
      it "should generate boolean property" do
        expected = {
          type: "boolean",
          enum: [true, false],
        }
        object = create_attribute(:boolean, :livemode)
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    describe "#visit_array" do
      it "should generate array property" do
        expected = {
          type: "array",
          items: {
            type: "string",
          },
        }
        object = create_attribute(:array, :currencies, of: "string")
        result = generate_property(object)

        assert_equal expected, result
      end

      context "when :of option is not given" do
        it "should generate array property with empty items (arbitary type)" do
          expected = {
            type: "array",
            items: {},
          }
          object = create_attribute(:array, :currencies)
          result = generate_property(object)

          assert_equal expected, result
        end
      end
    end

    describe "#visit_object" do
      it "should generate Open API Object Schema" do
        expected = {
          type: "object",
          required: [
            :amount,
          ],
          properties: {
            amount: {
              type: "integer",
            },
            name: {
              type: "string",
            },
            user: {
              :$ref => "#/components/schemas/user",
            },
          },
        }
        object = create_object("test") do
          integer :amount, required: true
          string  :name
          schema  :user
        end
        result = generate_property(object)

        assert_equal expected, result
      end
    end

    describe "#visit_schema" do
      context "when :of option is given" do
        it "should add $ref with different property name" do
          expected = {
            type: "object",
            properties: {
              friends: {
                :$ref => "#/components/schemas/user",
              },
            },
          }
          object = create_object("test") do
            schema :friends, of: :user
          end
          result = generate_property(object)

          assert_equal expected, result
        end
      end

      context "when :of and :expandable options are given" do
        it "should add oneOf property" do
          expected = {
            type: "object",
            properties: {
              friend: {
                oneOf: [
                  { :$ref => "#/components/schemas/user" },
                  { type: "string" },
                ],
              },
            },
          }
          object = create_object("test") do
            schema :friend, of: :user, expandable: true
          end
          result = generate_property(object)

          assert_equal expected, result
        end
      end

      context "when :of is array and :expandable options are given" do
        it "should add oneOf property" do
          expected = {
            type: "object",
            properties: {
              friend: {
                oneOf: [
                  { :$ref => "#/components/schemas/user" },
                  { :$ref => "#/components/schemas/customer" },
                  { type: "string" },
                ],
              },
            },
          }
          object = create_object("test") do
            schema :friend, of: %i[user customer], expandable: true
          end
          result = generate_property(object)

          assert_equal expected, result
        end
      end
    end
  end
end
