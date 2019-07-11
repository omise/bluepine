module Bluepine
  module Validators
    module Normalizable
      extend Bluepine::Support

      included do
        class << self
          # Normalizes value before passing it to validator
          attr_accessor :normalizer

          def normalizer
            @normalizer || superclass.normalizer
          end
        end

        self.normalizer = ->(v) { v }
      end

      def normalize(value)
        self.class.normalizer.(value)
      end
    end
  end
end