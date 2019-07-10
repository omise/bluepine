require "ostruct"

module Bluepine
  module Generators
    module OpenAPI
      # Generate Open API v3 Specifications
      #
      # @example
      #   resolver  = Resolver.new(schemas: [])
      #   generator = OpenApi::Generator.new(resolver, {
      #     title: "Awesome API",
      #     version: "1.0.0",
      #     # other infos ...
      #   })
      #
      #   generator = OpenApi::Generator.new(resolver) do
      #     title "Awesome API"
      #     version "1.0.0"
      #     servers []
      #   end
      #
      #   generator.generate # => {  }
      class Generator < Bluepine::Generators::Generator
        OPEN_API_VERSION  = "3.0.0".freeze
        OPEN_API_ID_REGEX = /:([\w]+)/.freeze
        EMPTY_RESPONSE    = "Response".freeze

        OPTIONS = {
          version: nil,
          title: nil,
          description: nil,
          servers: []
        }

        def initialize(resolver = nil, options = {})
          super(resolver)

          @options = OPTIONS.merge(options)
        end

        def generate
          {
            openapi: OPEN_API_VERSION,
            info: {
              version: @options[:version],
              title: @options[:title],
              description: @options[:description],
            },
            servers: generate_server_urls(@options[:servers]),
            paths: generate_paths(resolver.endpoints.keys),
            components: {
              schemas: generate_schemas(resolver.schemas.keys),
            },
          }
        end

        # share for both specs
        def generate_params(method, base_url = nil)
          generate_path_params(method, base_url) + generate_query_params(method)
        end

        def generate_param(param, in: :query, schema: nil)
          return unless param.serializable?

          {
            name: param.name.to_s,
            in: binding.local_variable_get(:in),
            schema: PropertyGenerator.generate(param, schema: schema),
          }.tap do |parameter|
            parameter[:required]    = param.required if param.required
            parameter[:deprecated]  = param.deprecated if param.deprecated
            parameter[:description] = param.description if param.description
          end
        end

        # path contains id? e.g. /users/:id
        def generate_path_params(method, base_url = nil)
          extract_ids(url(base_url, method.path))
            .map { |id| Attributes::StringAttribute.new(id, required: true) }
            .map { |id| generate_param(id, in: :path) }
        end

        # convert request body to `query` params when HTTP verb is `GET`
        def generate_query_params(method)
          return [] unless method.verb == :get

          method.params.attributes.values.each_with_object([]) do |param, params|
            # include original schema when method.schema differs from params.schema
            schema = method.params.schema if method.schema != method.params.schema
            params << generate_param(param, schema: schema)
          end.compact
        end

        def group_methods_by_path(methods)
          methods.values.each_with_object({}) do |method, paths|
            paths[method.path] ||= []
            paths[method.path] << method
          end
        end

        # -- end --
        def generate_server_urls(urls = [])
          urls.map { |name, url| { url: url, description: name } }
        end

        def generate_paths(services)
          services.each_with_object({}) do |name, paths|
            # no need to initialize
            next unless (endpoint = resolver.endpoint(name))

            generate_operations(endpoint, paths)
          end
        end

        def generate_operations(endpoint, paths)
          base_url = endpoint.path
          group_methods_by_path(endpoint.methods(resolver)).each do |path, methods|
            resource_url = convert_id_params(url(base_url, path))
            paths[resource_url] = {}

            methods.each do |method|
              paths[resource_url][method.verb] = generate_operation(method, base_url)
            end
          end
        end

        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#operationObject
        def generate_operation(method, base_url = nil)
          {
            tags: [method.schema.to_s.humanize.pluralize],
            parameters: generate_params(method, base_url),
          }.tap do |operation|
            operation[:requestBody] = generate_request_params(method) if method.body?
            operation[:summary]     = method.description if method.description
            operation[:responses]   = generate_responses(method)
          end
        end

        def generate_request_params(method)
          {
            "content": {
              "application/x-www-form-urlencoded": {
                schema: generate_schema(method.params),
              },
            },
          }
        end

        def generate_responses(method)
          {
            method.status => generate_response(method),
          }
        end

        def generate_response(method)
          {
            description: method.schema&.to_s&.humanize || EMPTY_RESPONSE,
          }.tap do |response|
            response[:content] = generate_json_response(method) if method.schema.present?
          end
        end

        def generate_json_response(method)
          {
            "application/json": {
              schema: PropertyGenerator.generate(method.schema, as: method.as),
            },
          }
        end

        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject
        def generate_schemas(serializers)
          serializers.each_with_object({}) do |name, schemas|
            # no need to initialize
            next unless (object = resolver.schema(name))

            schemas[name] = generate_schema(object)
          end
        end

        def generate_schema(object)
          self.class.assert_kind_of Bluepine::Attributes::Attribute, object

          PropertyGenerator.generate(object)
        end

        private

        # convert :id to {id} format
        def convert_id_params(url)
          url.gsub(OPEN_API_ID_REGEX, '{\1}')
        end

        def extract_ids(path)
          path.scan(OPEN_API_ID_REGEX).flatten
        end

        # join relative url
        def url(*parts)
          "/" + parts.compact.map { |part| part.gsub(/^\/|\/$/, "") }.reject(&:blank?).join("/")
        end
      end
    end
  end
end
