module Helper
  def create_result(value, errors = nil)
    Bluepine::Functions::Result.new(value, errors)
  end

  def create_open_api_generator(*args)
    Bluepine::Generators::OpenAPI::Generator.new(*args)
  end

  def create_serializer(*args, &block)
    Bluepine::Serializer.new(*args, &block)
  end

  def create_registry(*args, &block)
    Bluepine::Registry.new(*args, &block)
  end

  def create_resolver(*args, &block)
    Bluepine::Resolver.new(*args, &block)
  end

  def create_attribute(*args, &block)
    Bluepine::Attributes.create(*args, &block)
  end

  def create_schema(*args, &block)
    Bluepine::Attributes.create(:object, *args, &block)
  end

  def create_proxy(*args)
    Bluepine::Validators::Proxy.new(*args)
  end

  def create_validator(*args)
    Bluepine::Validator.new(*args)
  end

  def create_endpoint(path, **options, &block)
    Bluepine::Endpoint.new(path, **options, &block)
  end

  def create_method(*args)
    Bluepine::Endpoints::Method.new(*args)
  end

  def create_params(action, options = {}, &block)
    default = { schema: nil }

    Bluepine::Endpoints::Params.new(action, default.merge(options), &block)
  end

  def create_users(attributes = {}, size = 3)
    (1..size).to_a.map do |i|
      {
        username: "user_#{i}",
        password: "pass_#{i}",
      }.merge(attributes)
    end
  end

  def create_complex_schema
    user_schema = create_attribute(:object, :user) do
      string  :username
      string  :password
      boolean :enabled

      # recursive type :user
      array  :friends, of: :user
      array  :pets, of: :string

      # nested object
      object :address do
        integer :number
        object :info do
          string :notes
        end
      end

      # schema
      schema :team, of: :team
    end

    team_schema = create_attribute(:object, :team) do
      string :name
    end

    resolver = create_resolver(schemas: [user_schema, team_schema])
  end

  def create_user_schema
    create_attribute(:object, :user) do
      boolean :other
      string  :name, default: "john"
      object :team do
        boolean :enabled
      end
    end
  end

  def load_json(path)
    JSON.parse(File.read(path))
  end

  def assert_result(expected, actual)
    # minitest complains about assert_nil values
    if expected.value.nil?
      assert_nil actual.value
    else
      assert_equal expected.value, actual.value
    end

    if expected.errors.nil?
      assert_nil actual.errors
    else
      assert_equal expected.errors, actual.errors
    end
  end
end
