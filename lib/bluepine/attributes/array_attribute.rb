require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class ArrayAttribute < Attribute
      def native_type
        "array"
      end
    end
  end
end