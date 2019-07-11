module Bluepine
  module Serializers
    module Serializable
      extend Bluepine::Support

      included do
        class << self
          attr_accessor :serializer

          def serializer
            @serializer || superclass.serializer
          end
        end

        self.serializer = ->(v) { v }
      end

      def serialize(value)
        self.class.serializer.(value)
      end
    end
  end
end