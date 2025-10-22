require "spec"
require "../src/terminal/container"
require "../src/terminal/service_provider"

include Terminal

# Test classes are now defined in Terminal module (in container.cr)
# Using Terminal::TestFoo, Terminal::TestBar, etc.

describe ServiceContainer do
  it "registers and resolves a simple type" do
    container = ServiceContainer.new
    container.register_type(Terminal::TestFoo)
    inst = container.resolve(Terminal::TestFoo).as(Terminal::TestFoo)
    inst.should be_a(Terminal::TestFoo)
    inst.value.should eq("foo")
  end

  it "supports factories and instances" do
    container = ServiceContainer.new
    container.register_factory(TestBar) { |_| TestBar.new("f") }
    b = container.resolve(TestBar).as(TestBar)
    b.x.should eq("f")

    baz = TestBaz.new
    container.register_instance(TestBaz, baz)
    container.resolve(TestBaz).as(TestBaz).should be(baz)
  end

  it "respects singleton and transient lifetimes" do
    container = ServiceContainer.new
    container.register_type(TestS)
    s1 = container.resolve(TestS).as(TestS)
    s2 = container.resolve(TestS).as(TestS)
    s1.n.should eq(s2.n)

    container.register_transient(String)
    i1 = container.resolve(String).as(String)
    i2 = container.resolve(String).as(String)
    i1.should_not eq(i2)
  end

  it "handles named services and scopes" do
    container = ServiceContainer.new
    container.register_transient(String, name: "a")
    container.register_transient(String, name: "b")
    a = container.resolve(String, "a").as(String)
    b = container.resolve(String, "b").as(String)
    a.should_not eq(b)

    container.register_singleton(String)
    scope = container.create_scope
    scope.resolve(String).as(String).should eq(container.resolve(String).as(String))
  end

  it "detects circular dependencies" do
    container = ServiceContainer.new
    container.register_singleton(TestA)
    container.register_singleton(TestB)
    expect_raises(CircularDependencyError) { container.resolve(TestA).as(TestA) }
  end

  it "allows constructor override and composition" do
    container = ServiceContainer.new

    # Register default factory
    container.register_factory(TestConfig) { |_| TestConfig.new("first", 1) }
    config1 = container.resolve(TestConfig).as(TestConfig)
    config1.value.should eq("first")
    config1.count.should eq(1)

    # Override with new factory
    container.register_factory(TestConfig) { |_| TestConfig.new("second", 2) }
    config2 = container.resolve(TestConfig).as(TestConfig)
    config2.value.should eq("second")
    config2.count.should eq(2)

    # Compose constructors
    container.register_factory(TestComposite) { |c|
      config = c.resolve(TestConfig).as(TestConfig)
      TestComposite.new(config, "prefix:")
    }
    composite = container.resolve(TestComposite).as(TestComposite)
    composite.value.should eq("prefix:second")
  end

  it "maintains constructor registration in scopes" do
    container = ServiceContainer.new
    container.register_factory(TestConfig) { |_| TestConfig.new("parent") }

    # Create scope
    scope = container.create_scope

    # Scope inherits parent constructors
    scope_config1 = scope.resolve(TestConfig).as(TestConfig)
    scope_config1.value.should eq("parent")

    # Scope can override constructors
    scope.register_factory(TestConfig) { |_| TestConfig.new("scoped") }
    scope_config2 = scope.resolve(TestConfig).as(TestConfig)
    scope_config2.value.should eq("scoped")

    # Parent container unaffected by scope override
    parent_config = container.resolve(TestConfig).as(TestConfig)
    parent_config.value.should eq("parent")
  end

  it "supports named registrations with factories" do
    container = ServiceContainer.new

    # Register factories with explicit lifetimes
    container.register_factory(TestConfig, nil, ServiceLifetime::Singleton) { |_| TestConfig.new("default", 0) }
    container.register_factory(TestConfig, "dev", ServiceLifetime::Transient) { |_| TestConfig.new("dev", 1) }
    container.register_factory(TestConfig, "prod", ServiceLifetime::Singleton) { |_| TestConfig.new("prod", 2) }

    # Test default unnamed registration
    default1 = container.resolve(TestConfig).as(TestConfig)
    default2 = container.resolve(TestConfig).as(TestConfig)
    default1.value.should eq("default")
    default1.should be(default2) # Explicitly registered as singleton

    # Test transient named registration
    dev1 = container.resolve(TestConfig, "dev").as(TestConfig)
    dev2 = container.resolve(TestConfig, "dev").as(TestConfig)
    dev1.value.should eq("dev")
    dev1.should_not be(dev2) # Explicitly registered as transien

    # Test singleton named registration
    prod1 = container.resolve(TestConfig, "prod").as(TestConfig)
    prod2 = container.resolve(TestConfig, "prod").as(TestConfig)
    prod1.value.should eq("prod")
    prod1.should be(prod2) # Explicitly registered as singleton

    # Can override just the lifetime without changing the factory
    container.register_transient(TestConfig, name: "prod") # Change to transien
    prod3 = container.resolve(TestConfig, "prod").as(TestConfig)
    prod4 = container.resolve(TestConfig, "prod").as(TestConfig)
    prod3.value.should eq("prod") # Same factory
    prod3.should_not be(prod4)    # Now creates new instances
  end

  it "supports scoped factory inheritance and override" do
    container = ServiceContainer.new

    # Register factories in paren
    container.register_factory(TestConfig) { |_| TestConfig.new("parent-default") }
    container.register_factory(TestConfig, "dev") { |_| TestConfig.new("parent-dev") }

    # Create scope and verify inheritance
    scope = container.create_scope
    scope_default = scope.resolve(TestConfig).as(TestConfig)
    scope_default.value.should eq("parent-default")
    scope_dev = scope.resolve(TestConfig, "dev").as(TestConfig)
    scope_dev.value.should eq("parent-dev")

    # Override factory in scope
    scope.register_factory(TestConfig, "dev") { |_| TestConfig.new("scope-dev") }
    scope_dev2 = scope.resolve(TestConfig, "dev").as(TestConfig)
    scope_dev2.value.should eq("scope-dev")

    # Parent resolution unaffected
    parent_dev = container.resolve(TestConfig, "dev").as(TestConfig)
    parent_dev.value.should eq("parent-dev")
  end

  it "supports async factories and ServiceProvider facade" do
    container = ServiceContainer.new
    provider = ServiceProvider.new(container)

    # Register async factory that waits and then sends instance
    container.register_async_factory(TestConfig) do |ch|
      spawn do
        sleep(Time::Span.new(nanoseconds: 10_000_000))
        ch.send(TestConfig.new("async", 5))
        ch.close
      end
    end

    ch = provider.resolve_async(TestConfig)
    val = ch.receive
    val.as(TestConfig).value.should eq("async")
    val.as(TestConfig).count.should eq(5)
  end
end
