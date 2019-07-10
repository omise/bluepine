require "test_helper"

class Bluepine::ResolverTest < Minitest::Spec
  alias :create :create_resolver

  let(:resolver) { 
    create({
      schemas: [
        create_schema(:user) do
          string :username
          string :password
        end 
      ],
      endpoints: [
        create_endpoint("/users")
      ]
    })
  }

  describe "#new" do
    context "when passing schemas: objects" do
      it "should register given schemas" do
        group = create_schema(:group) do
          string :name
          string :description
        end

        resolver = create(schemas: [group])

        assert_equal group, resolver.schema(:group)
      end
    end

    context "when passing endpoints: objects" do
      it "should register given endpoints" do
        group    = create_endpoint("/groups")
        resolver = create(endpoints: [group])

        assert_equal group, resolver.endpoint(:groups)
      end
    end

    context "when &block is given" do
      it "should create schema definitions" do
        resolver = create do
          schema :user do
            string :username
          end
        end

        assert_instance_of Bluepine::Resolver, resolver
        assert_instance_of Bluepine::Attributes::ObjectAttribute, resolver.schema(:user)
      end

      it "should create endpoint definitions" do
        resolver = create do
          endpoint "/users" do
            get :show, params: lambda {}
          end
        end

        assert_instance_of Bluepine::Resolver, resolver
        assert_instance_of Bluepine::Endpoint, resolver.endpoint(:users)
      end
    end
  end

  describe "#schema" do
    it "should register new schema object when &block given" do
      schema = resolver.schema(:team) do
        string :name
      end

      assert_equal schema, resolver.schema(:team)
      assert_instance_of Bluepine::Attributes::ObjectAttribute, schema
    end

    it "should raise error when trying to get non-exists schema" do
      assert_raises Bluepine::Resolver::SchemaNotFound do
        resolver.schema(:people)
      end
    end
  end

  describe "#endpoint" do
    it "should register new endpoint object when &block given" do
      endpoint = resolver.endpoint("/teams") do
        post :create
      end

      assert_equal endpoint, resolver.endpoint(:teams)
      assert_instance_of Bluepine::Endpoint, endpoint
    end

    it "should raise error when trying to get non-exists endpoint" do
      assert_raises Bluepine::Resolver::EndpointNotFound do
        resolver.endpoint(:people)
      end
    end
  end
end
