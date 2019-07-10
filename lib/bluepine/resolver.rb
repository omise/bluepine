module Bluepine
  # Responsible for registering and looking up the schemas and endpoints
  #
  # @example Register via +:schemas+ and +:endpoints+ options
  #   resolver = Resolver.new(schemas: [], endpoints: [])
  #
  # @example Register via +block+
  #   resolver = Resolver.new do
  #     schema :user do
  #       string :username
  #     end
  #
  #     schema :team do
  #       string :name
  #     end
  #
  #     endpoint "/users" do
  #       string :username
  #     end
  #   end
  #
  # @example Manually register new schema/endpoint
  #   resolver.schema(:user) do
  #     string :username
  #   end
  #
  #   resolver.endpoint("/teams") do
  #     post :create
  #   end
  #
  # @example Register an existing schema/endpoint
  #   resolver.schemas.register(:user, user_schema)
  #
  class Resolver
    Endpoint   = Bluepine::Endpoint
    Attributes = Bluepine::Attributes

    SchemaNotFound   = Bluepine::Error.create("Endpoint %s cannot be found")
    EndpointNotFound = Bluepine::Error.create("Schema %s cannot be found")

    def initialize(schemas: [], endpoints: [], schema_registry: nil, endpoint_registry: nil, &block)
      @registries = {
        schemas:   create_schema_registry(schemas, schema_registry),
        endpoints: create_endpoint_registry(endpoints, endpoint_registry)
      }

      instance_exec(&block) if block_given?
    end

    def resolve(type, name)
      @registries[type].get(name)
    end

    def register(type, name, *args, &block)
      @registries[type].create(name, *args, &block)
    end

    # Exposes schema registry
    def schemas
      @registries[:schemas]
    end

    # Exposes endpoint registry
    def endpoints
      @registries[:endpoints]
    end

    def schema(name, options = {}, &block)
      return resolve(:schemas, name) unless block_given?

      register(:schemas, name, options, &block)
    end

    def endpoint(path, options = {}, &block)
      return resolve(:endpoints, Endpoint.normalize_name(path)) unless block_given?

      register(:endpoints, path, options, &block)
    end

    private

    def create_schema_registry(schemas, registry = nil)
      return registry.(schemas) if registry

      Registry.new(schemas, error: SchemaNotFound) do |name, options = {}, block|
        @objects[name] = Attributes.create(:object, name, options, &block)
      end
    end

    def create_endpoint_registry(endpoints, registry = nil)
      return registry.(endpoints) if registry

      Registry.new(endpoints, error: EndpointNotFound) do |path, options = {}, block|
        endpoint = Endpoint.new(path, options, &block)
        @objects[endpoint.name] = endpoint
      end
    end
  end
end