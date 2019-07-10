module Bluepine
  module Generators
    class Generator
      include Bluepine::Assertions
      include Bluepine::Resolvable

      def initialize(resolver = nil)
        @resolver = resolver
      end

      def generate(*args)
        raise NotImplementedError
      end
    end
  end
end
