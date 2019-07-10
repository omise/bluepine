module Bluepine
  module Generators
    module OpenAPI
      # Generate property based on Open API Spec (shared for both Omise/Open API specs)
      class PropertyGenerator < Bluepine::Attributes::Visitor
        include Bluepine::Assertions

        class << self
          def visit(attr, options = {})
            new.visit(attr, options)
          end

          alias_method :generate, :visit
        end

        def visit(attr, options = {})
          attr = normalize_attribute(attr, options)

          # handle case when attr is a Symbol (reference)
          return attr unless attr.respond_to?(:native_type)

          super
        end

        # catch-all
        def visit_attribute(attr, options = {})
          build(attr, options)
        end

        def visit_array(attr, options = {})
          build(attr, options).tap do |property|
            property[:items] = attr.of ? visit(attr.of, options) : {}
          end
        end

        def visit_object(attr, options = {})
          build(attr, options).tap do |property|
            required = []
            attr.attributes.values.each_with_object(property) do |attribute, object|

              # Adds to required list
              required << attribute.name if attribute.required

              object[:properties] ||= {}
              object[:properties][attribute.name] = visit(attribute, options) if attribute.serializable?
            end

            # additional options
            property[:required] = required unless required.empty?
          end
        end

        # Handle SchemaAttribute
        def visit_schema(attr, options)
          return build_ref(attr.of) unless attr.expandable

          # SchemaAttribute#of may contains array of references
          # e.g. of = [:user, :customer]
          refs = Array(attr.of).map { |of| build_ref(of) }
          refs << visit("string")

          {
            "oneOf": refs,
          }
        end

        def normalize_attribute(object, options = {})
          return build_ref(object, options)    if object.kind_of?(Symbol)
          return object                        if object.respond_to?(:native_type)

          # object is string (native types e.g. "integer", "boolean" etc)
          Bluepine::Attributes.create(object.to_sym, object)
        end

        private

        def build(attr, options = {})
          assert_kind_of Bluepine::Attributes::Attribute, attr

          # build base property
          {
            type: attr.native_type,
          }.tap do |property|
            property[:description]     = attr.description if attr.description.present?
            property[:default]         = attr.default if attr.default
            property[:enum]            = attr.in if attr.in
            property[:nullable]        = attr.null if attr.null
            property[:format]          = attr.format if attr.format
            property[:pattern]         = build_pattern(attr.match) if attr.match
            property["x-omise-schema"] = options[:schema] if options[:schema].present?
          end
        end

        # create $ref
        def build_ref(attr, options = {})
          ref = options[:as] || attr

          {
            "$ref": "#/components/schemas/#{ref}",
          }
        end

        def build_pattern(value)
          return value.source if value.respond_to?(:source)

          value
        end
      end
    end
  end
end
