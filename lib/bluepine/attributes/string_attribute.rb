require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class StringAttribute < Attribute
      self.serializer = ->(v) { v.to_s }

      RULES = {
        match: {
          group: :format,
          name:  :with,
        },
        min: {
          group: :length,
          name:  :minimum,
        },
        max: {
          group: :length,
          name:  :maximum,
        },
        range: {
          group: :length,
          name:  :in,
        },
      }.freeze

      def native_type
        "string"
      end

      def in
        super&.map(&:to_s)
      end
    end
  end
end