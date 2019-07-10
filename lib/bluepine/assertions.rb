module Bluepine
  # Declarative way to deal with errors
  module Assertions
    Error       = Class.new(StandardError)
    KeyError    = Class.new(Error)
    SubsetError = Class.new(Error)

    extend self
    def self.included(object)
      object.extend(self)
    end

    # Usage
    #
    # Use default error message
    #
    #   assert valid?
    #
    # Use custom error message
    #
    #   assert valid?, "Invalid value"
    #
    # Use custom Error class
    #
    #   assert valid?, ValidationError, "Invalid value"
    def assert(object, *msgs)
      raises Error, msgs << "#{object.class} is not a truthy" unless object
    end

    def assert_not(object, *msgs)
      raises Error, msgs << "#{object.class} is not a falsey" if object
    end

    def assert_kind_of(classes, object, *msgs)
      classes = normalize_array(classes)
      found   = classes.find { |klass| object.kind_of?(klass) }

      raises Error, msgs << "#{object.class} must be an instance of #{classes.map(&:name).join(', ')}" unless found
    end

    alias_method :assert_kind_of_either, :assert_kind_of

    # Usage
    #
    #   assert_in ["john", "joe"], "joe"
    #   assert_in { amount: 1 }, :amount
    def assert_in(list, value, *msgs)
      raises KeyError, msgs << "#{value.class} - #{value} is not in the #{list.keys}" if list.respond_to?(:key?) && !list.key?(value)
      raises KeyError, msgs << "#{value.class} - #{value} is not in the #{list}" if list.kind_of?(Array) && !list.include?(value)
    end

    def assert_subset_of(parent, subset, *msgs)
      rest = subset - parent
      raises SubsetError, msgs << "#{rest} are not subset of #{parent}" if rest.present?
    end

    private

    def normalize_array(values)
      values.respond_to?(:each) ? values : [values]
    end

    # allow caller to pass custom Error
    def raises(error, msgs = [])
      error, msg = msgs unless msgs.first.kind_of?(String)

      # Error class has its own error message and caller
      # doesn't specify custom message
      if msgs.length == 2
        if error.respond_to?(:message)
          msg = error.message
        elsif error.respond_to?(:new)
          msg = error.new&.message
        end
      end

      raise error, msg || msgs.last
    end
  end
end
