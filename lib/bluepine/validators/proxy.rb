module Bluepine
  module Validators
    # Proxy will act as a wrapper for a pair of attribute and value.
    # It internally creates anonymous model with single attribute.
    # This will simplify validation process for nested attributes
    # (let's Visitor handles traversal instead).
    #
    # @example
    #   attribute = StringAttribute.new(:username)
    #   value     = "john"
    #
    #   proxy = Proxy.new(attribute, value)
    #   proxy.username # => "john"
    #   proxy.valid?   # => true|false
    #   proxy.errors
    class Proxy
      include Bluepine::Assertions
      include ActiveModel::Validations

      attr_reader :value, :validators

      # rails requires this for anonymous model
      def self.model_name
        ActiveModel::Name.new(self, nil, name)
      end

      def initialize(attribute, value = nil, options = {})
        @attribute = attribute
        @value     = attribute.value(value)
        @params    = { attribute.name.to_sym => @value }
        @context   = options[:context] || {}
      end

      def valid?
        # clear validators
        self.class.clear_validators!

        register(@attribute.validators.dup)

        super
      end

      # Register validators to model
      #
      #   register(presense: true, ..., validators: [Validator1, Validator2, ...])
      def register(validators)
        customs = validators.delete(:validators) || []

        # register custom validators (requires :attributes)
        self.class.validates_with(*customs, attributes: [@attribute.name]) if customs.any?

        # register ActiveModel's validations e.g. presence: true
        self.class.validates(@attribute.name, validators) if validators.any?
      end

      def messages
        errors.messages.values.flatten
      end

      private

      # Delegates method call to hash accessor e.g. `a.name` will become `a[:name]`
      # and return `nil` for all undefined attributes e.g. `a.non_exists` => `nil`
      def method_missing(m, *args, &block)
        normalize_missing_value m
      end

      def respond_to_missing?(method, *)
        @params.key?(method) || super
      end

      def normalize_missing_value(method)
        @params.key?(method) ? @value : @context[method]
      end
    end
  end
end