require "bluepine/attributes/attribute"

module Bluepine
  module Attributes
    # Reference to other schema and doesn't accept &block.
    #
    # SchemaAttribute supports extra option named `expandable`
    # which will either return `id` or `serialized object`
    # as the result.
    class SchemaAttribute < ObjectAttribute
      DEFAULT_EXPANDABLE = false
      def initialize(name, options = {})
        # automatically add name to :of if it's not given
        options[:of] = name unless options.key?(:of)
        @expandable  = options.fetch(:expandable, DEFAULT_EXPANDABLE)

        super
      end

      attr_reader :expandable
    end
  end
end