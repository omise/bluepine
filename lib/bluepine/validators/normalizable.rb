module Bluepine
  module Validators
    module Normalizable
      extend ActiveSupport::Concern

      included do
        # Normalizes value before passing it to validator
        class_attribute :normalizer

        # Default normalizer
        self.normalizer = ->(v) { v }
      end

      def normalize(value)
        self.class.normalize(value)
      end

      module ClassMethods
        def normalize(value)
          normalizer.(value)
        end
      end
    end
  end
end