require_relative "registry"
require_relative "attributes/visitor"
require_relative "serializers/serializable"
require_relative "validators/normalizable"
require_relative "validators/validatable"

# Attributes
require_relative "attributes/boolean_attribute"
require_relative "attributes/string_attribute"
require_relative "attributes/number_attribute"
require_relative "attributes/integer_attribute"
require_relative "attributes/float_attribute"
require_relative "attributes/array_attribute"
require_relative "attributes/object_attribute"
require_relative "attributes/schema_attribute"
require_relative "attributes/date_attribute"
require_relative "attributes/time_attribute"
require_relative "attributes/currency_attribute"
require_relative "attributes/uri_attribute"
require_relative "attributes/ip_address_attribute"

module Bluepine
  # Attributes registry holds the references to all attributes
  #
  # @see .create
  module Attributes
    include Bluepine::Assertions
    KeyError  = Bluepine::Error.create "Attribute %s already exists"

    @registry = Registry.new({}, error: KeyError) do |id, name, options, block|
      attribute = get(id)
      attribute.new(name, options, &block)
    end

    class << self
      # Holds reference to all attribute objects
      #
      # @return [Registry]
      attr_accessor :registry

      # Creates new attribute (Delegates to Registry#create).
      #
      # @return [Attribute]
      #
      # @example Creates primitive attribute
      #   Attributes.create(:string, :username, required: true)
      #
      # @example Creates compound attribute
      #   Attributes.create(:object, :user) do
      #     string :username
      #   end
      def create(type, name, options = {}, &block)
        registry.create(type, name, options, &block)
      end

      # Registers new Attribute (alias for Registry#register)
      #
      # @example
      #   register(:custom, CustomAttribute)
      def register(type, klass, override: false)
        registry.register(type, klass, override: override)
      end

      def key?(key)
        registry.key?(key)
      end
    end

    ALL = {
      string:       StringAttribute,
      number:       NumberAttribute,
      integer:      IntegerAttribute,
      float:        FloatAttribute,
      boolean:      BooleanAttribute,
      object:       ObjectAttribute,
      array:        ArrayAttribute,
      schema:       SchemaAttribute,
      time:         TimeAttribute,
      date:         DateAttribute,
      uri:          URIAttribute,
      currency:     CurrencyAttribute,
      ip_address:   IPAddressAttribute,
    }.freeze

    SCALAR_TYPES     = %i[string number integer float boolean].freeze
    NATIVE_TYPES     = SCALAR_TYPES + %i[array object].freeze
    NON_SCALAR_TYPES = ALL.keys - SCALAR_TYPES

    # register pre-defined attributes
    ALL.each { |name, attr| register(name, attr) }
  end
end
