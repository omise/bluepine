module Bluepine
  # @example
  #   InvaldKey = Error.create("Invalid %s key")
  #   raise InvalidKey, "id"
  class Error < StandardError
    def self.create(msg)
      Class.new(Error) do
        MESSAGE.replace msg
      end
    end

    MESSAGE = "Error"
    def initialize(*args)
      super args.any? ? MESSAGE % args : MESSAGE
    end
  end
end