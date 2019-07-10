module Bluepine
  # user_schema = Attributes.create(:object) do
  #   string :username
  #   string :email
  # end
  #
  # user = <any object>
  #
  # resolver   = Resolver.new(schemas: [user_schema, ...])
  # serializer.serialize(user_schema, user)
  class Serializer < Bluepine::Attributes::Visitor
    include Bluepine::Resolvable

    InvalidPredicate = Bluepine::Error.create("Invalid predicate value (must be either Symbol or Proc)")

    def initialize(resolver = nil)
      @resolver = resolver
    end

    # Override to make it accepts 3 arguments
    def normalize_attribute(attribute, object, options = {})
      super(attribute, options)
    end

    # catch all
    def visit_attribute(attribute, object, options = {})
      attribute.serialize(attribute.value(object))
    end

    # Primitive attribute
    # -------------------
    # serialize(string, "user")
    # serialize(object, { name: "john" })
    #
    # Schema Attribute
    # ----------------
    # schema = Attributes.create(:object, :user) do
    #   string :username
    # end
    #
    # class User
    #   def initialize(data)
    #     @data = data
    #   end
    #
    #   def username
    #     @data[:name]
    #   end
    # end
    # user = User.new(name: "john")
    #
    # serialize(schema, user)
    alias :serialize :visit

    # Defines visitors for primitive types e.g. `visit_string` etc
    Bluepine::Attributes::SCALAR_TYPES.each do |type|
      alias_method "visit_#{type}", :visit_attribute
    end

    def visit_object(attribute, object, options = {})
      visit_object_handler(attribute, object) do |attr, value, attrs|
        attrs[attr.name] = visit(attr, value, options)
      end
    end

    def visit_array(attribute, object, options = {})
      as = attribute.of

      Array(object).map do |item|
        # item#serialize_as will be used when of: option is not specified.
        # e.g. ListSerializer.schema has `array :data`
        # as = attribute.of || (item.serialize_as if item.respond_to?(:serialize_as))
        unless as.kind_of?(Symbol)
          item
        else
          visit(as, item, options)
        end
      end
    end

    def visit_schema(attribute, object, options = {})
      attribute = resolver.schema(attribute.of)

      visit_object(attribute, object, options)
    end

    private

    def get(object, name)
      object.respond_to?(name) ? object.send(name) : object&.fetch(name, nil)
    end

    def visit_object_handler(attribute, object)
      attribute.attributes.values.each_with_object({}) do |attr, attrs|
        next unless serializable?(attr, object)

        # get value for each field
        value = get(object, attr.method)

        yield(attr, value, attrs)
      end
    end

    def serializable?(attr, object)
      return unless attr.serializable?

      # check predicate :if and :unless
      return execute_predicate(attr.if, object)      if attr.if
      return !execute_predicate(attr.unless, object) if attr.unless

      true
    end

    def execute_predicate(predicate, object)
      case predicate
      when Symbol
        get(object, predicate)
      when Proc
        predicate.call(object)
      else
        raise InvalidPredicate
      end
    end
  end
end