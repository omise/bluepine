module Bluepine
  module Support
    # Mimic Active Support's .included behaviours
    def included(base = nil, &block)
      if base.nil?
        @_included_block = block
      else
        base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
        base.class_eval &@_included_block
      end
    end
  end
end