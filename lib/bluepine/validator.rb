require "bluepine/validators/proxy"

module Bluepine
  # A validator (can validate any kind of {Attribute}).
  #
  # @example Validate simple {Attribute}
  #   attribute = Attributes.create(:string, :username, required: true)
  #   payload   = { username: nil }
  #
  #   validator = Validator.new(resolver)
  #   validator.validate(attribute, payload) # => { username: ["can't be blank"] }
  #
  # @example Validate compound type (e.g. Object, Array).
  #   attribute = Attributes.create(:object, :user) do
  #     string :username, min: 5
  #     array  :pets, of: :string
  #   end
  #   payload   = { username: "john", pets: ["jay", 1] }
  #
  #   validator.validate(attribute, payload) # =>
  #   # {
  #   #   username: ["is too short (minimum is 5 characters)"]
  #   #   pets: { 1: ["is not string"] }
  #   # }
  class Validator < Bluepine::Attributes::Visitor
    include Bluepine::Resolvable
    include Functions

    def initialize(resolver = nil)
      @resolver = resolver
    end

    # Overrides to make it accepts 3 arguments
    def normalize_attribute(attribute, value, options = {})
      super(attribute, options)
    end

    # Overrides to make it normalizes value before validating attribute
    #
    # @return [Result]
    def visit(attribute, value, options = {})
      method, attribute = find_method!(attribute, value, options)
      value = attribute.normalize(attribute.value(value))

      send(method, attribute, value, options)
    end

    alias :validate :visit

    # catch-all
    def visit_attribute(attribute, value, options = {})
      run(attribute, options, value)
    end

    def visit_string(attribute, value, options = {})
      compose(
        curry(:is_valid?, :string),
        curry(:run, attribute, options)
      ).(value)
    end

    def visit_boolean(attribute, value, options = {})
      compose(
        curry(:is_valid?, :boolean),
        curry(:run, attribute, options),
      ).(value)
    end

    def visit_number(attribute, value, options = {})
      compose(
        curry(:is_valid?, :number),
        curry(:run, attribute, options)
      ).(value)
    end

    def visit_integer(attribute, value, options = {})
      compose(
        curry(:is_valid?, :integer),
        curry(:run, attribute, options)
      ).(value)
    end

    def visit_float(attribute, value, options = {})
      compose(
        curry(:is_valid?, :float),
        curry(:run, attribute, options)
      ).(value)
    end

    def visit_array(attribute, value, options = {})
      compose(
        curry(:is_valid?, :array),
        curry(:iterate, value || [], lambda { |(item, v), i|

          # when of: is not specified, item can be any type
          next result(item) unless attribute.of

          # validate each item
          visit(attribute.of, item, options)
        })
      ).(value)
    end

    def visit_object(attribute, value, options = {})
      compose(
        curry(:is_valid?, :object),
        curry(:iterate, attribute.attributes, lambda { |(key, attr), i|

          # validate each attribute
          data = get(value, attr.method)
          options[:context] = value

          visit(attr, data, options)
        })
      ).(value)
    end

    def visit_schema(attribute, value, options = {})
      attr = resolver.schema(attribute.of)

      visit_object(attr, value, options)
    end

    private

    def create_proxy(attr, value, options = {})
      Bluepine::Validators::Proxy.new(attr, value, options)
    end

    def get(object, name)
      return unless object

      object.respond_to?(name) ? object.send(name) : object[name]
    end

    def run(attribute, options, value)
      proxy = create_proxy(attribute, value, options)
      return result(value, proxy.messages) unless proxy.valid?

      result(value)
    end

    # Iterates through Hash/Array
    #
    # @param target Hash|Array
    # @return [Result]
    def iterate(target, proc, value)
      is_hash = target.is_a?(Hash)
      errors  = {}
      values  = is_hash ? {} : []

      # When target is a Hash. k = name, v = Attribute.
      # When it's an Array. k = value, v = nil.
      target.each.with_index do |(k, v), i|
        name   = is_hash ? v&.name : i
        result = proc.([k, v], i)

        if result.errors
          errors[name] = result.errors
        else
          values[name] = result.value
        end
      end

      return result(nil, errors) if errors.any?

      result(values)
    end

    def is_valid?(type, value)
      return result(value) if value.nil?
      return result(value, ["is not #{type}"]) unless send("is_#{type}?", value)

      result(value)
    end

    def is_boolean?(v)
      [true, false].include?(v)
    end

    def is_string?(v)
      v.is_a?(String)
    end

    def is_number?(v)
      is_integer?(v) || is_float?(v)
    end

    def is_integer?(v)
      v.is_a?(Integer)
    end

    def is_float?(v)
      v.is_a?(Float)
    end

    def is_array?(v)
      v.is_a?(Array)
    end

    def is_object?(v)
      v.is_a?(Hash) || v.is_a?(ActionController::Parameters)
    end
  end
end