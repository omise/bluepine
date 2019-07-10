require "bluepine/endpoints/params"
require "bluepine/endpoints/method"

module Bluepine
  class Endpoint
    include Bluepine::Assertions

    # See `docs/api/endpoint-validations.md`.
    HTTP_METHODS_WITHOUT_BODY = %i[get head trace]
    HTTP_METHODS_WITH_BODY    = %i[post put patch delete]
    HTTP_METHODS = HTTP_METHODS_WITHOUT_BODY + HTTP_METHODS_WITH_BODY

    class << self
      # Converts `/users/:id/friends` to `users_id_friends`
      def normalize_name(name)
        name.to_s.delete(":").gsub(/(\A\/+|\/+\z)/, '').tr('/', '_').to_sym
      end
    end

    DEFAULT_OPTIONS = {
      schema:      nil,
      title:       nil,
      description: nil,
    }.freeze

    attr_reader   :path, :name, :schema
    attr_accessor :title, :description

    def initialize(path, options = {}, &block)
      options  = DEFAULT_OPTIONS.merge(options)
      @schema  = options[:schema]
      @path    = path
      @name    = normalize_name(options[:name])
      @methods = {}
      @params  = nil
      @block   = block
      @loaded  = false
      @title   = options[:title]
      @description = options[:description]
    end

    # Defines http methods dynamically e.g. :get, :post ...
    #   endpoint.define do
    #     get :index, path: "/"
    #     post :create
    #   end
    HTTP_METHODS.each do |method|
      define_method method do |action, path: "/", **options|
        create_method(method, action, path: path, **options)
      end
    end

    # Lazily builds all params and return methods hash
    def methods(resolver = nil)
      ensure_loaded

      @methods.each { |name, _| method(name, resolver: resolver) }
    end

    # Lazily builds params for speicified method
    def method(name, resolver: nil)
      ensure_loaded
      assert_in @methods, name.to_sym

      @methods[name.to_sym].tap { |method| method.build_params(params, resolver) }
    end

    # Returns default params
    def params(&block)
      ensure_loaded

      @params ||= Bluepine::Endpoints::Params.new(:default, schema: schema, built: true, &block || -> {})
    end

    # Registers http verb method
    #
    #   create_method(:post, :create, path: "/")
    def create_method(verb, action, path: "/", **options)
      # Automatically adds it self as schema value
      options[:schema] = options.fetch(:schema, schema)

      @methods[action.to_sym] = Bluepine::Endpoints::Method.new(verb, action: action, path: path, **options)
    end

    private

    def normalize_name(name)
      (name || @schema || self.class.normalize_name(@path)).to_sym
    end

    # Lazily executes &block
    def ensure_loaded
      return if @loaded

      # We need to set status here; otherwise, we'll have
      # error when there's nested block.
      @loaded = true

      instance_exec(&@block) if @block
    end
  end
end
