module Bluepine
  module Endpoints
    # Represents HTTP method
    #
    # @example Create new +POST+ {Method}
    #   Method.new(:post, action: create, path: "/", schema: :user, as: :list)
    #
    # @example
    #   Method.new(:post, {
    #     action: :create,
    #     path: "/",
    #     validators: [CustomValidator]
    #   })
    class Method
      DEFAULT_OPTIONS = {
        as:          nil,
        params:      [],
        exclude:     false,
        schema:      nil,
        status:      200,
        title:       nil,
        description: nil,
        validators:  [],
      }.freeze

      attr_reader   :verb, :path, :action, :params, :schema, :status, :as
      attr_accessor :title, :description

      def initialize(verb, action:, path: "/", **options)
        @options = DEFAULT_OPTIONS.merge(options)
        @verb    = verb
        @path    = path
        @action  = action

        # Create ParamsAttribute instance
        @params  = create_params(action, options.slice(:params, :schema, :exclude))
        @schema  = @options[:schema]
        @as      = @options[:as]
        @status  = @options[:status]
        @title   = @options[:title]
        @description = @options[:description]
        @validator   = nil
        @validators  = @options[:validators]
        @resolver    = nil
        @result      = nil
      end

      def validate(params = {}, resolver = nil)
        @validator = create_validator(@resolver || resolver)
        @result    = @validator.validate(@params, params, validators: @validators)
      end

      def valid?(*args)
        validate(*args)

        @result&.errors&.empty?
      end

      def errors
        @result&.errors
      end

      # Does it have request body? (only non GET verb can have request body)
      def body?
        Bluepine::Endpoint::HTTP_METHODS_WITH_BODY.include?(@verb) && @params.keys.any?
      end

      def build_params(default = {}, resolver = nil)
        @resolver = resolver if resolver
        @params   = @params.build(default, resolver)
      end

      def permit_params(params = {}, target = nil)
        return params unless params.respond_to?(:permit)

        params.permit(*@params.permit(params))
      end

      private

      def create_params(action, **options)
        Bluepine::Endpoints::Params.new(action, **options)
      end

      def create_validator(*args)
        Bluepine::Validator.new(*args)
      end
    end
  end
end
