module Bluepine
  module Attributes
    # An abstract Attribute based class.
    #
    # @abstract
    class Attribute
      include Bluepine::Assertions
      include Bluepine::Serializers::Serializable
      include Bluepine::Validators::Normalizable
      include Bluepine::Validators::Validatable

      class_attribute :options
      attr_reader     :name

      # Assigns default class attribute values
      self.options    = {}.freeze

      def initialize(name, options = {})
        @name    = name
        @options = self.class.options.merge(options)
      end

      def options
        @options.merge({
          name:         @name,
          match:        match,
          method:       method,
          type:         type,
          native_type:  native_type,
          of:           of,
          in:           send(:in),
          if:           @options[:if],
          unless:       @options[:unless],
          null:         null,
          spec:         spec,
          spec_uri:     spec_uri,
          format:       format,
          private:      private,
          deprecated:   deprecated,
          required:     required,
          default:      default,
          description:  description,
          attributes:   attributes.values&.map(&:options),
        })
      end

      def type
        self.class.name.demodulize.chomp("Attribute").underscore
      end

      def match
        @options[:match]
      end

      def method
        @options[:method] || @name
      end

      def of
        @options[:of]
      end

      def in
        @options[:in]
      end

      def if
        @options[:if]
      end

      def unless
        @options[:unless]
      end

      def null
        @options.fetch(:null, false)
      end

      def native_type
        type
      end

      def format
        @options[:format]
      end

      def spec
        nil
      end

      def spec_uri
        nil
      end

      def attributes
        {}
      end

      # deprecated attribute should be listed in schema
      def deprecated
        @options.fetch(:deprecated, false)
      end

      def private
        @options.fetch(:private, false)
      end

      def required
        @options.fetch(:required, false)
      end

      def default
        @options[:default]
      end

      def description
        @options[:description]
      end

      # Should not be listed in schema or serialize this attribute
      def serializable?
        !private
      end

      def value(value)
        value.nil? ? default : value
      end
    end
  end
end