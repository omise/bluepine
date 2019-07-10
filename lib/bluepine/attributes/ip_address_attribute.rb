require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class IPAddressAttribute < StringAttribute
      def spec
        "RFC 2673 § 3.2"
      end

      def spec_uri
        "https://tools.ietf.org/html/rfc2673#section-3.2"
      end
    end
  end
end