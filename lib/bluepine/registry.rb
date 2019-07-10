module Bluepine
  # A generic registry
  #
  # @example Create key/value pairs registry (Hash)
  #   registry = Registry.new do |key, value|
  #     { name: key, age: value }
  #   end
  #
  #   # Register object
  #   registry.register(:john, name: :john, age: 10)
  #
  #   # Retrieve object
  #   registry.get(:john) # => { name: :john, age: 10 }
  #
  #   # Create new object
  #   registry.create(:joe, 10) # => { name: joe, age: 10 }
  class Registry
    include Bluepine::Assertions

    KeyError = Bluepine::Error.create("Object %s already exists")

    # @param [Object] A collection of objects which has #name property
    # @param &block A {Proc} that'll create new object
    def initialize(objects = [], error: KeyError, &block)
      assert_kind_of Proc, block

      @objects = normalize objects
      @factory = block
      @error   = error
    end

    # Registers new object by id
    #
    # @param id [String] Unique name
    # @param object [Object] Object to register
    # @param override [Boolean] Overrides existing key if exists
    def register(id, object, override: false)
      if key?(id) && !override
        raise @error, id
      end

      @objects[id.to_sym] = object
    end

    # Creates new object by using a {Proc} from #new
    #
    # @return [Object]
    # @example
    #   registry.create(:user, "john")
    def create(id, *args, &block)
      instance_exec(id, *args, block, &@factory)
    end

    # Retrieves registered Object by key
    def get(id)
      raise @error, id unless key?(id)

      @objects[id.to_sym]
    end

    def key?(id)
      @objects.key? id
    end

    def keys
      @objects.keys
    end

    private

    def normalize(objects = [])
      (objects || []).each_with_object({}) { |object, target| target[object.name] = object }
    end
  end
end