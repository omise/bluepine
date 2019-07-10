require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class CurrencyAttribute < StringAttribute
      def format
        super || type
      end

      def spec
        "ISO 4217"
      end

      def spec_uri
        "https://en.wikipedia.org/wiki/ISO_4217"
      end
    end
  end
end