module Bluepine
  module Resolvable
    ResolverRequired = Bluepine::Error.create("Resolver is required")

    def resolver
      raise ResolverRequired unless @resolver

      @resolver
    end
  end
end