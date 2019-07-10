require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class FloatAttribute < NumberAttribute
      self.serializer = ->(v) { v.to_f }

      def format
        super || "float"
      end
    end
  end
end