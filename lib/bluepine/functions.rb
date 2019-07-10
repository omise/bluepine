module Bluepine
  # FP helpers
  module Functions
    class Result
      attr_reader :value, :errors

      def initialize(value, errors = nil)
        @value  = value
        @errors = errors
      end

      def compose(f)
        return self if errors

        f.(value)
      end
    end

    def result(value, errors = nil)
      Result.new(value, errors)
    end

    # Compose functions
    # compose : (a -> b) -> (b -> c) -> a -> c
    def compose(*fns)
      ->(v) {
        fns.reduce(fns.shift.(v)) do |x, f|
          x.respond_to?(:compose) ? x.compose(f) : f.(x)
        end
      }
    end

    # A composition that early returns value
    # f : a -> b
    # g : a -> c
    def compose_result(*fns)
      ->(v) {
        fns.reduce(fns.shift.(v)) do |x, f|
          x ? x : f.(v)
        end
      }
    end

    # Curry instance method
    def curry(method, *args)
      self.method(method).curry[*args]
    end
  end
end