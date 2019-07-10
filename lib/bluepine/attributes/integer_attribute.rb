require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class IntegerAttribute < NumberAttribute
      self.serializer = ->(v) { v.to_i }

      # JSON schema supports `integer` type
      def native_type
        "integer"
      end
    end
  end
end