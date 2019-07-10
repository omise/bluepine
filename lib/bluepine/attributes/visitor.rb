module Bluepine
  module Attributes
    # An abstract Visitor for traversing {Attribute}.
    #
    # Sub-classes must implement the methods correspond to {Attribute} classes.
    #
    # @example Implements +string+ visitor for {StringAttribute}
    #   class SimpleVisitor < Bluepine::Attributes::Visitor
    #     def visit_string(attribute, *args)
    #       "Hello #{attribute.name}"
    #     end
    #   end
    #
    #   # Usage
    #   username = Attributes.create(:string, :username)
    #   visitor  = StringVisitor.new
    #   visitor.visit(username) # => "Hello username"
    #
    # @abstract
    class Visitor
      include Functions

      MethodNotFound = Bluepine::Error.create("Cannot find method Visitor#%s")

      # Traveres a visitable object and calls corresponding method based-on
      # sub-classes' impementations.
      #
      # @example When +attribute+ is an instance of {Attribute}.
      #   object = Attributes.create(:object, :user) { }
      #   visit(object) # => visit_object
      #
      # @example When +attribute+ is a {Symbol}.
      #   visit(:user) # => visit_user or visit_schema(attr, of: :user)
      #
      # @param [Attribute|Symbol] The +Attribute+ object or +Symbol+
      def visit(attribute, *args)
        method, attribute = find_method!(attribute, *args)

        send(method, attribute, *args)
      end

      # Performs visitor logic when no corresponding method can be found (Catch-all).
      def visit_attribute(attribute, options = {})
        raise NotImplementedError
      end

      def visit_schema(attribute, options = {})
        raise NotImplementedError
      end

      private

      # Finds a vistor method.
      #
      # @return Array<String, Attribute> Pair of method name and +Attribute+ object
      #
      # It'll return a first callable method in the chains or return +nil+ when no methods can be found.
      # If +attribute+ is a Symbol. It'll stop looking any further.
      #
      #   find_method(:integer) # => `visit_integer`
      #
      # If it's an instance of <tt>Attribute</tt>. It'll look up in ancestors
      # chain and return the first callable method.
      #
      #   object = Attributes.create(:object, :name) { ... }
      #   find_method(object) => `visit_object`
      def find_method(attribute, *args)
        compose(
          curry(:resolve_methods),
          curry(:respond_to_visitor?),
          curry(:normalize_symbol, attribute, args)
        ).(attribute)
      end

      def find_method!(attribute, *args)
        method, attribute = find_method(attribute, *args)

        raise MethodNotFound, normalize_method(attribute) unless method

        [method, attribute]
      end

      # Returns list of method Symbols from given +Attribute+
      #
      # @return [Symbol] Method symbols e.g. [:string, StringAttribute, Attribute]
      def resolve_methods(attribute)
        return [attribute] if attribute.kind_of?(Symbol)

        # Finds all ancestors in hierarchy up to `Attribute`
        parents = attribute.class.ancestors.map(&:to_s)
        parents.slice(0, parents.index(Attribute.name).to_i + 1)
      end

      def normalize_method(method)
        return unless method

        # Cannot use `chomp("Attribute")` here, because the top most class is `Attribute`
        "visit_" + method.to_s.demodulize.gsub(/(\w+)Attribute/, "\\1").underscore
      end

      # Creates Attribute from symbol
      # e.g. :integer to IntegerAttribute
      def normalize_attribute(attribute, options = {})
        return attribute unless Attributes.key?(attribute)

        Attributes.create(attribute, attribute.to_s, options)
      end

      # Finds method from method list that respond_to `visit_{attribute}` call
      def respond_to_visitor?(methods)
        methods.find { |m| respond_to?(normalize_method(m)) }
      end

      def normalize_symbol(attribute, args, method)
        # When we can't find method e.g. `visit_{method}`
        # and `attribute` is a symbol (e.g. :user),
        # we'll enforce the same logic for all visitor sub-classes
        # by calling `visit_schema` with of: attribute
        if !method && attribute.kind_of?(Symbol)
          method, attribute = normalize_schema_symbol(attribute, *args)
        end

        [
          normalize_method(method),
          normalize_attribute(attribute, *args),
        ]
      end

      def normalize_schema_symbol(schema, *args)
        args.last[:of] = schema if args.last.is_a?(Hash)

        [:schema, :schema]
      end
    end
  end
end
