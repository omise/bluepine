require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class URIAttribute < StringAttribute
      def format
        super || type
      end

      def spec
        "RFC 3986"
      end

      def spec_uri
        "https://tools.ietf.org/html/rfc3986"
      end
    end
  end
end