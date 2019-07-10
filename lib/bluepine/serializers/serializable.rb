module Bluepine
  module Serializers
    module Serializable
      extend ActiveSupport::Concern

      included do
        # Serializer
        class_attribute :serializer

        # Default serializer
        self.serializer = ->(v) { v }
      end

      def serialize(value)
        self.class.serialize(value)
      end

      module ClassMethods
        def serialize(value)
          serializer.(value)
        end
      end
    end
  end
end