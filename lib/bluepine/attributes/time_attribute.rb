require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class TimeAttribute < StringAttribute
      def format
        super || "date-time"
      end

      def spec
        "ISO 8601"
      end

      def spec_uri
        "https://en.wikipedia.org/wiki/ISO_8601"
      end
    end
  end
end