class Bluepine::RegistryTest < Minitest::Spec
  alias :create :create_registry

  let(:registry) { create { |id, value| { id => value }} }

  describe "#new" do
    it "should create new registry instance" do
      registry = create nil do |*args|
        args
      end

      assert_instance_of Bluepine::Registry, registry
    end

    it "should raise error when {factory} is not Proc" do
      assert_raises Bluepine::Registry::Error do
        create 1
      end
    end
  end

  describe "#register" do
    it "should register new object by id" do
      expected = { me: 5 }
      actual   = registry.register(:me, expected)

      assert_equal expected, actual
    end

    context "when registering with existing id" do
      it "should raise KeyError" do
        assert_raises Bluepine::Registry::KeyError do
          registry.register(:me, {})
          registry.register(:me, {})
        end
      end
    end

    context "when override: true is given" do
      it "should override existing key" do
        registry.register(:me, {})
        registry.register(:me, {}, override: true)
      end
    end
  end

  describe "#create" do
    it "should create new object from given value" do
      expected = { me: 5 }
      actual   = registry.create(:me, 5)

      assert_equal expected, actual
    end
  end

  describe "#get" do
    it "should get object by id" do
      expected = { me: 5 }
      registry.register(:me, expected)

      assert_equal expected, registry.get(:me)
    end
  end
end
