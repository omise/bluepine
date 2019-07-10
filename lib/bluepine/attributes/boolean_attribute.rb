require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    # @example Registers custom normalizer that accepts "on" as truth value
    #   BooleanAttribute.normalizer = ->(x) { ["on", true].include?(x) ? true : false }
    #
    # @example Registers custom serializer
    #   BooleanAttribute.serialize = ->(x) { x == "on" ? true : false }
    class BooleanAttribute < Attribute
      self.serializer = ->(v) { ActiveModel::Type::Boolean.new.cast(v) }

      def native_type
        "boolean"
      end

      def in
        @options.fetch(:in, [true, false])
      end
    end
  end
end