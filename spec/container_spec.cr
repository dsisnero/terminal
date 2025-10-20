require "spec"
require "../src/terminal/container"

include Terminal

# Test classes for interface registration
abstract class TestInterface
  abstract def value : String
end

class TestImplementation < TestInterface
  def value : String
    "implementation"
  end
end

describe Container do
  describe "basic registration and resolution" do
    it "registers and resolves transient services" do
      container = ServiceContainer.new

      container.register_transient(String)

      instance1 = container.resolve(String).as(String)
      instance2 = container.resolve(String).as(String)

      instance1.should be_a(String)
      instance2.should be_a(String)
      instance1.should_not eq(instance2) # Different instances for transient
    end

    it "registers and resolves singleton services" do
      container = ServiceContainer.new

      container.register_singleton(String)

      instance1 = container.resolve(String).as(String)
      instance2 = container.resolve(String).as(String)

      instance1.should be_a(String)
      instance2.should be_a(String)
      instance1.should eq(instance2) # Same instance for singleton
    end

    # TODO: Factory functions not yet implemented
    # it "registers with factory functions" do
    #   container = ServiceContainer.new
    #
    #   container.register_factory(String) do |c|
    #     "factory-created-instance"
    #   end
    #
    #   instance = container.resolve(String)
    #   instance.should eq("factory-created-instance")
    # end

    it "checks if service is registered" do
      container = ServiceContainer.new

      container.has?(String).should be_false
      container.register_transient(String)
      container.has?(String).should be_true
    end

    it "raises error for unregistered service" do
      container = ServiceContainer.new

      expect_raises(Exception, "Service not registered: String") do
        container.resolve(String)
      end
    end
  end

  describe "named services" do
    it "registers and resolves named services" do
      container = ServiceContainer.new

      container.register_transient(String, name: "primary")
      container.register_transient(String, name: "secondary")

      primary = container.resolve(String, "primary").as(String)
      secondary = container.resolve(String, "secondary").as(String)

      primary.should be_a(String)
      secondary.should be_a(String)
      primary.should_not eq(secondary)
    end

    it "checks if named service is registered" do
      container = ServiceContainer.new

      container.has?(String, "primary").should be_false
      container.register_transient(String, name: "primary")
      container.has?(String, "primary").should be_true
      container.has?(String, "secondary").should be_false
    end
  end

  describe "scoped container" do
    it "creates scoped containers" do
      root_container = ServiceContainer.new
      scoped_container = root_container.create_scope

      scoped_container.should be_a(Container)
      scoped_container.should be_a(ScopedContainer)
    end

    it "shares singleton instances between scopes" do
      root_container = ServiceContainer.new
      root_container.register_singleton(TestInterface, TestImplementation)

      scope1 = root_container.create_scope
      scope2 = root_container.create_scope

      instance1 = scope1.resolve(TestInterface).as(Terminal::TestInterface)
      instance2 = scope2.resolve(TestInterface).as(Terminal::TestInterface)

      instance1.should be(instance2) # Same singleton instance
    end

    it "creates new instances for transient services in scopes" do
      root_container = ServiceContainer.new
      root_container.register_transient(String)

      scope1 = root_container.create_scope
      scope2 = root_container.create_scope

      instance1 = scope1.resolve(String).as(String)
      instance2 = scope2.resolve(String).as(String)

      instance1.should_not be(instance2) # Different instances
    end
  end

  describe "interface/abstract class registration" do
    it "registers and resolves interface implementations" do
      container = ServiceContainer.new

      container.register_transient(TestInterface, TestImplementation)

      instance = container.resolve(TestInterface).as(Terminal::TestInterface)
      instance.should be_a(Terminal::TestInterface)
      instance.should be_a(Terminal::TestImplementation)
      instance.value.should eq("implementation")
    end
  end
end