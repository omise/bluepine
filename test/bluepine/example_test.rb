require "test_helper"

class Bluepine::ExampleTest < Minitest::Spec
  let(:resolver) { 
    create_resolver do
      # register new schema
      schema :hero do
        string  :name, min: 4

        # nested object
        object :stats do
          number :strength, default: 0
        end

        # recursive schema
        array :friends, of: :hero

        # reference
        schema :team
      end

      schema :team do
        string :name, min: 5, default: "Avengers"
      end
    end
  }

  describe "#validator" do
    it "should use schema to validate payload" do
      payload = {
        name: "Hulk",
        friends: [
          { name: "Tony" },
          { name: "Sta"},
        ],
        team: {
          name: "Aven"
        }
      }

      expected = create_result(nil, {
        friends: {
          1 => {
            name: ["is too short (minimum is 4 characters)"]
          }
        },
        team: {
          name: ["is too short (minimum is 5 characters)"]
        }
      })

      result = create_validator(resolver).validate(resolver.schema(:hero), payload)

      assert_result expected, result
    end

    context "when success" do
      it "should return normalized value" do
        payload = {
          name: "Thor",
          friends: [
            { name: "Iron Man" },
          ],
          age: 20,
        }
        result   = create_validator(resolver).validate(resolver.schema(:hero), payload)
        expected = {
          name: "Thor",
          stats: {
            strength: 0
          },
          friends: [
            { name: "Iron Man", stats: { strength: 0 }, friends: [], team: { name: "Avengers"} }
          ],
          team: { name: "Avengers" }
        }

        assert_equal expected, result.value
      end
    end
  end

  describe "#serializer" do
    it "should serialize object" do
      hero = {
        name: "Thor",
        friends: [
          {
            name: "Iron Man",
            stats: {
              strength: "9"
            }
          }
        ],
        stats: {
          strength: "8"
        }
      }
      expected = {
        name: "Thor",
        stats: {
          strength: 8
        },
        friends: [
          { name: "Iron Man", stats: { strength: 9 }, friends: [], team: { name: "Avengers" }}
        ],
        team: {
          name: "Avengers"
        }
      }

      serializer = create_serializer resolver
      actual     = serializer.serialize resolver.schema(:hero), hero

      assert_equal expected, actual
    end
  end

  describe "#Open API generator" do
    it "should generate spec" do
      generator = create_open_api_generator resolver
      expected  = load_json("#{__dir__}/example_open_api.json")

      assert_equal expected.to_json, generator.generate.to_json
    end
  end
end
