require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    class DateAttribute < StringAttribute
      def format
        super || "date"
      end
    end
  end
end