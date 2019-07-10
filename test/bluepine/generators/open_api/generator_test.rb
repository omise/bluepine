require "json"
require_relative "../base_test_case"

class Bluepine::Generators::OpenAPI::GeneratorTest < Bluepine::Generators::BaseTest
  include BluepineApiEndpointFixtures

  let(:generator) {
    Bluepine::Generators::OpenAPI::Generator.new(resolver, {
      version: "1.0.0",
      title: "Omise API",
      description: "Omise API",
      servers: {
        api: "https://api.omise.co",
        vault: "https://vault.omise.co",
      }
    })
  }

  describe "#generate" do
    it "should generate open api v3 spec" do
      expected = load_json("#{__dir__}/../fixtures/open_api_spec.json")
      result   = generator.generate

      assert_equal expected.to_json, result.to_json
    end
  end

  describe "#generate_params" do
    it "should generate params object" do
      expected = [{
        name: "email",
        in: :query,
        schema: {
          type: "string",
        },
      }]
      method = create_method("/", verb: :get)
      result = generator.generate_params(method)

      assert_equal expected, result
    end

    describe "#url" do
      it "should generate url" do
        result = generator.send :url, "/users", "/", "/{id}/"

        assert_equal "/users/{id}", result
      end
    end

    describe "#generate_params" do
      context "when params contains ids in url" do
        it "should generate path params" do
          method   = create_method("/users/:user/books/:book")
          result   = generator.generate_params(method)
          expected = [
            {
              name: "user",
              in: :path,
              schema: {
                type: "string",
              },
              required: true,
            },
            {
              name: "book",
              in: :path,
              schema: {
                type: "string",
              },
              required: true,
            },
          ]

          assert_equal expected, result
        end
      end

      context "when Method#verb is :get" do
        it "should generate query params" do
          method = create_method("/users", verb: :get, params: lambda {
            integer :limit
          })
          result   = generator.generate_params(method)
          expected = [
            {
              name: "limit",
              in: :query,
              schema: {
                type: "integer",
              },
            },
          ]

          assert_equal expected, result
        end
      end

      context "when Method#verb is not :get" do
        it "should generate request body params" do
          method = create_method("/users", verb: :post, params: lambda {
            string :email, required: true
            string :username
          })

          result   = generator.generate_request_params(method)
          expected = {
            content: {
              "application/x-www-form-urlencoded": {
                schema: {
                  type: "object",
                  properties: {
                    email:    { type: "string" },
                    username: { type: "string" },
                  },
                  required: [:email],
                }
              }
            }
          }

          assert_equal expected, result
        end
      end
    end

    context "when path contains {id}" do
      it "should add {id} to parameters" do
        expected = [
          {
            name: "id",
            in: :path,
            required: true,
            schema: {
              type: "string",
            },
          },
          {
            name: "user_id",
            in: :path,
            required: true,
            schema: {
              type: "string",
            },
          },
        ]
        method = create_method("/:id/:user_id")
        result = generator.generate_params(method)

        assert_equal expected, result
      end
    end
  end

  describe "#generate_responses" do
    it "should generate Responose Object" do
      method    = create_method("/:id/:user_id", schema: :customer)
      responses = generator.generate_responses(method)

      expected = {
        200 => {
          description: "Customer",
          content: {
            "application/json": {
              schema: {
                "$ref": "#/components/schemas/customer",
              },
            },
          },
        },
      }

      assert_equal expected, responses
    end

    context "when :schema option is nil" do
      it "should generate empty response" do
        method    = create_method("/:id/:user_id", schema: nil)
        responses = generator.generate_responses(method)

        expected = {
          200 => {
            description: "Response",
          },
        }

        assert_equal expected, responses
      end
    end

    context "when speicifying as: option" do
      it "should generate Response Object with type :array" do
        method    = create_method("/:id/:user_id", schema: :customer, as: :list)
        responses = generator.generate_responses(method)

        expected = {
          200 => {
            description: "Customer",
            content: {
              "application/json": {
                schema: {
                  "$ref": "#/components/schemas/list",
                },
              },
            },
          },
        }

        assert_equal expected, responses
      end
    end
  end
end
