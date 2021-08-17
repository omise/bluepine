require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class ObjectAttribute < Attribute
      class_attribute :stacks
      attr_reader     :attributes

      self.stacks = []

      def initialize(name, options = {}, &block)
        super

        @attributes = {}
        instance_exec(&block) if block_given?
      end

      def native_type
        "object"
      end

      # Apply default options to all attributes
      #
      # group if: :deleted? { ... }
      # group unless: :deleted? { ... }
      # group if: ->{ @user.deleted? } { ... }
      def group(options, &block)
        return unless block_given?

        # Use stacks to allow nested conditions
        self.class.stacks << Attribute.options
        Attribute.options = options

        instance_exec(&block)

        # restore options
        Attribute.options = self.class.stacks.pop
      end

      # Shortcut for creating attribute (delegate call to Registry.create)
      # This allows us to access newly registered attributes
      #
      #   string :username (or array, number etc)
      def method_missing(type, name = nil, options = {}, &block)
        if Attributes.registry.key?(type)
          @attributes[name] = Attributes.create(type, name, options, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, *)
        super
      end

      def [](name)
        @attributes[name.to_sym]
      end

      def []=(name, attribute)
        assert_kind_of Attribute, attribute

        @attributes[name.to_sym] = attribute
      end

      def keys
        @attributes.keys
      end
    end
  end
end
