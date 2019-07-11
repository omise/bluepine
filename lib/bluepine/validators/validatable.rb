module Bluepine
  module Validators
    module Validatable
      extend Bluepine::Support

      included do
        RULES = {}.freeze
      end

      # Returns validation rules (rails compatible)
      def validators
        rules(self.class::RULES, @options).tap do |rules|
          rules[:if]         = self.if if self.if
          rules[:unless]     = self.unless if self.unless
          rules[:allow_nil]  = true if null
          rules[:presence]   = true if required
          rules[:inclusion]  = { in: self.in, allow_blank: true } if self.in
          rules[:validators] = @options[:validators] if @options[:validators]
        end
      end

      private

      # Build validation rules
      #
      # @example
      #   rules = {
      #     min: { name: :minimum, group: :length }
      #   }
      #
      #   # will be converted to
      #   {
      #     length: { minimum: {value} }
      #   }
      def rules(rules, options)
        rules.keys.each_with_object({}) do |name, hash|
          next if options[name].nil?

          rule = OpenStruct.new rules[name]
          (hash[rule.group] ||= {}).tap do |r|
            r[:allow_blank] = true
            r[rule.name]    = options[name]
          end
        end
      end
    end
  end
end