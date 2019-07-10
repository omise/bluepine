module Bluepine
  module Endpoints
    # Usage
    #
    #   Params.new(:create)
    #   Params.new(:index, params: :list)
    #   Params.new(:create, params: %i[amount currency])
    #   Params.new(:create, params: %i[amount], exclude: true)
    #   Params.new(:create, params: false)
    #   Params.new :create, params: -> {
    #     integer :amount
    #   }
    #   Params.new(:index, schema: :user, as: :list)
    #
    class Params < Attributes::ObjectAttribute
      include Bluepine::Assertions
      include Bluepine::Resolvable

      InvalidType = Bluepine::Error.create("Invalid params type")
      NotBuilt    = Bluepine::Error.create("Params need to be built first")

      DEFAULT_OPTIONS = {
        exclude: false,
        schema: nil,
        built: false,
      }.freeze

      attr_reader :action, :params, :schema

      def initialize(action, params: false, **options, &block)
        super(action, options.except(DEFAULT_OPTIONS.keys))

        options  = DEFAULT_OPTIONS.merge(options)
        @action  = action.to_sym
        @exclude = options[:exclude]
        @schema  = options[:schema]
        @params  = block_given? ? block : params
        @built   = options[:built]
      end

      def build(default = {}, resolver = nil)
        # Flag as built
        @built = true

        case @params
        when Params
          @params
        when true
          # use default params
          default
        when false
          # use no params
          self
        when Proc
          instance_exec(&@params)
          self
        when Symbol
          # use params from other service
          resolver.endpoint(@params).params
        when Array
          assert_subset_of(default.keys, @params)

          # override default params by using specified symbol
          keys = @exclude ? default.keys - @params : @params
          keys.each { |name| self[name] = default[name] }
          self
        else
          raise InvalidType
        end
      end

      def built?
        @built
      end

      # Build permitted params for ActionController::Params
      def permit(params = {})
        raise NotBuilt unless built?

        build_permitted_params(attributes, params)
      end

      private

      def build_permitted_params(attrs, params = {})
        attrs.map do |name, attr|
          # permit array
          # TODO: params.permit(:foo, array: [:key1, :key2])
          next { name => [] } if attr.kind_of?(Bluepine::Attributes::ArrayAttribute)

          # permit non-object
          next name unless attr.kind_of?(Bluepine::Attributes::ObjectAttribute)

          # Rails 5.0 doesn't support arbitary hash params
          # 5.1+ supports this, via `key: {}` empty hash.
          #
          # The work around is to get hash keys from params
          # and assign them to permit keys
          # params = params&.fetch(name, {})
          data = params&.fetch(name, {})
          keys = build_permitted_params(attr.attributes, data)

          { attr.name => normalize_permitted_params(keys, data) }
        end
      end

      def normalize_permitted_params(keys, params = {})
        return keys unless keys.empty?
        return {} if params.empty?

        params.keys
      end
    end
  end
end
