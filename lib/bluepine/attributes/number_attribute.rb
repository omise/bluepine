require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class NumberAttribute < Attribute
      self.serializer = ->(v) { v.to_s.include?(".") ? v.to_f : v.to_i }

      RULES = {
        max: {
          group: :numericality,
          name:  :less_than_or_equal,
        },
        min: {
          group: :numericality,
          name:  :greater_than_or_equal,
        },
      }.freeze

      def native_type
        "number"
      end
    end
  end
end