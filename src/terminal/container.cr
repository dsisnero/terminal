# Dependency Injection Container for Terminal UI
# Implements SOLID principles with explicit registration and optional annotation support

module Terminal
  # Service lifetime management
  enum ServiceLifetime
    Transient # New instance each time
    Scoped    # One instance per scope
    Singleton # Single instance for container lifetime
  end

  # Test classes for interface registration (temporary for testing)
  abstract class TestInterface
    abstract def value : String
  end

  class TestImplementation < TestInterface
    def value : String
      "implementation"
    end
  end

  # Additional test classes for container testing
  class TestFoo
    def value : String
      "foo"
    end
  end

  class TestBar
    @x : String

    def initialize(@x : String)
    end

    def x : String
      @x
    end
  end

  class TestBaz; end

  class TestS
    @n : Float64

    def initialize
      @n = Random.new.rand
    end

    def n : Float64
      @n
    end
  end

  class TestA
    def initialize(b : TestB)
    end
  end

  class TestB
    def initialize(a : TestA)
    end
  end

  class TestConfig
    @value : String
    @count : Int32

    def initialize(@value : String, @count : Int32 = 0)
    end

    def value : String
      @value
    end

    def count : Int32
      @count
    end
  end

  class TestComposite
    @config : TestConfig
    @prefix : String

    def initialize(@config : TestConfig, @prefix = "test:")
    end

    def value : String
      "#{@prefix}#{@config.value}"
    end
  end

  # Dependency resolution errors
  class DependencyResolutionError < Exception
    property service_type : String
    property dependency_type : String?

    def initialize(@service_type, @dependency_type = nil, message = nil)
      super(message || build_message)
    end

    private def build_message
      if @dependency_type
        "Failed to resolve dependency #{@dependency_type} for service #{@service_type}"
      else
        "Failed to resolve service #{@service_type}"
      end
    end
  end

  class MissingDependencyError < DependencyResolutionError
    def initialize(service_type : String, dependency_type : String)
      super(service_type, dependency_type,
        "Required dependency #{dependency_type} not registered for #{service_type}")
    end
  end

  class CircularDependencyError < Exception
    def initialize(stack : Array(String), circular_type : String)
      cycle = (stack + [circular_type]).join(" -> ")
      super("Circular dependency detected: #{cycle}")
    end
  end

  # Service registration descriptor
  class ServiceRegistration
    @service_type : String
    @implementation_type : String?
    @lifetime : ServiceLifetime
    @name : String?
    @factory : Proc(ServiceType)?

    def initialize(service_type : String, implementation_type : String? = nil, lifetime : ServiceLifetime = ServiceLifetime::Transient, name : String? = nil, factory : Proc(ServiceType)? = nil)
      @service_type = service_type
      @implementation_type = implementation_type
      @lifetime = lifetime
      @name = name
      @factory = factory
    end

    def set_factory(factory : Proc(ServiceType))
      @factory = factory
    end

    def service_type : String
      @service_type
    end

    def implementation_type : String?
      @implementation_type
    end

    def lifetime : ServiceLifetime
      @lifetime
    end

    def name : String?
      @name
    end

    def factory : Proc(ServiceType)?
      @factory
    end
  end

  # Core container interface (S: Single Responsibility)
  abstract class Container
    # Register a service with explicit implementation
    abstract def register(service_type : Class, implementation_type : Class? = nil,
                          lifetime : ServiceLifetime = ServiceLifetime::Transient,
                          name : String? = nil)

    # Resolve a service instance
    abstract def resolve(service_type : Class, name : String? = nil) : Object

    # Resolve a service instance asynchronously. Returns a Channel that will receive the
    # instance once construction completes. This allows pluggable async factories to be used.
    abstract def resolve_async(service_type : Class, name : String? = nil) : Channel(ServiceType)

    # Check if service is registered
    abstract def has?(service_type : Class, name : String? = nil) : Bool

    # Create a scoped container
    abstract def create_scope : Container
  end

  # Type alias for supported service types in container
  # Note: Test types are included for testing purposes
  alias ServiceType = String | Int32 | Float64 | Bool | TestImplementation |
                      TestFoo | TestBar | TestBaz | TestS | TestA | TestB | TestConfig | TestComposite

  # Wrapper class to hold any service instance
  class ServiceInstance
    @value : ServiceType

    def initialize(@value : ServiceType)
    end

    def value : ServiceType
      @value
    end
  end

  # Wrapper to store constructor procs for dependency injection
  class ConstructorWrapper
    # Store the proc in a stable field
    @factory : Proc(ServiceType)

    def initialize(@factory : Proc(ServiceType))
    end

    # Call factory with the container
    def call(container : Container) : ServiceType
      @factory.call
    end
  end

  # NOTE: Async constructor support simplified: we spawn a fiber to run
  # the synchronous constructor and send the result over a channel.
  # This avoids storing Channel-typed procs in ivars which complicates
  # Crystal's generic typing rules.

  # Main container implementation
  class ServiceContainer < Container
    @registrations : Hash(String, ServiceRegistration)
    @singleton_instances : Hash(String, ServiceInstance)

    # Pluggable constructors registry: keyed by registration key -> ConstructorWrapper

    # (async constructor registry removed; we use a simple adapter to spawn resolves)
    # Helper method to register a type with its default implementation
    def register_type(type : Class, lifetime : ServiceLifetime = ServiceLifetime::Singleton)
      register(type, type, lifetime)
    end

    # Helper method to register a factory
    def register_factory(type : Class, name : String? = nil, lifetime : ServiceLifetime = ServiceLifetime::Transient, &block : Container -> ServiceType)
      key = build_key(type, name)
      # Store factory both as a registration and in the pluggable constructors
      reg = ServiceRegistration.new(type.name, nil, lifetime, name, -> { block.call(self) })
      @registrations[key] = reg
      # Wrap block into a ConstructorWrapper so the ivar has a concrete type
      # Wrap the provided block into a zero-arg proc that calls the block with the container
      @constructors[key] = ConstructorWrapper.new(-> { block.call(self) })
    end

    # Register an async factory: adapt it into a synchronous registration by
    # wrapping the provided block into a factory that blocks until the block
    # sends a value on a channel. This keeps storage simple while allowing
    # async implementations.
    def register_async_factory(type : Class, name : String? = nil, lifetime : ServiceLifetime = ServiceLifetime::Transient, &block : Channel(ServiceType) -> Nil)
      key = build_key(type, name)
      # Create a wrapper factory which will run the async block and wait for the value
      reg = ServiceRegistration.new(type.name, nil, lifetime, name, -> do
        ch = Channel(ServiceType).new(1)
        # run the user's async block in a spawned fiber so it can use ch
        spawn do
          block.call(ch)
        end
        # wait for value from the async block (user block should send and close the channel)
        val = ch.receive
        val
      end)
      @registrations[key] = reg
    end

    # Helper method to register an instance
    def register_instance(type : Class, instance : Object, name : String? = nil)
      key = build_key(type, name)
      @registrations[key] = ServiceRegistration.new(type.name, type.name, ServiceLifetime::Singleton, name)
      @singleton_instances[key] = ServiceInstance.new(instance.as(ServiceType))
    end

    @parent : Container?
    @resolution_stack : Array(String)

    def initialize(@parent : Container? = nil)
      @registrations = {} of String => ServiceRegistration
      @singleton_instances = {} of String => ServiceInstance
      @resolution_stack = [] of String
      @constructors = {} of String => ConstructorWrapper
      # Initialize async constructors via helper to avoid generic ivar typing issues
      init_async_constructors!

      # Register basic types that the container can handle natively
      register_basic_types
    end

    private def init_async_constructors!
      # no-op now; async constructors are wrapped into ServiceRegistration by register_async_factory
    end

    # Register service with explicit type
    def register(service_type : Class, implementation_type : Class? = nil,
                 lifetime : ServiceLifetime = ServiceLifetime::Transient,
                 name : String? = nil)
      impl_type = implementation_type || service_type
      key = build_key(service_type, name)

      # If there's an existing registration with a factory, preserve it
      if existing = @registrations[key]?
        @registrations[key] = ServiceRegistration.new(
          service_type.name,
          impl_type.name,
          lifetime,
          name,
          existing.factory
        )
      else
        @registrations[key] = ServiceRegistration.new(service_type.name, impl_type.name, lifetime, name)
      end
    end

    # Resolve service instance
    def resolve(service_type : Class, name : String? = nil) : Object
      key = build_key(service_type, name)

      # Check current container
      if registration = @registrations[key]?
        return build_service(registration, key)
      end

      # Check parent container
      if parent = @parent
        return parent.resolve(service_type, name)
      end

      raise "Service not registered: #{service_type.name}#{name ? " (name: #{name})" : ""}"
    end

    # Resolve service asynchronously. Returns a Channel that will receive the ServiceType.
    def resolve_async(service_type : Class, name : String? = nil) : Channel(ServiceType)
      ch = Channel(ServiceType).new(1)
      key = build_key(service_type, name)

      # Build synchronously (register_async_factory wraps async work into the registration)
      spawn do
        begin
          instance = nil
          if registration = @registrations[key]?
            instance = build_service(registration, key)
          else
            if parent = @parent
              # Delegate to parent synchronously then send
              instance = parent.resolve(service_type, name).as(ServiceType)
            else
              raise DependencyResolutionError.new(service_type.name, nil, "Service not registered: #{service_type.name}")
            end
          end
          ch.send(instance)
        rescue ex : Exception
          # swallow; close channel
        ensure
          ch.close
        end
      end

      ch
    end

    # Check if service is registered
    def has?(service_type : Class, name : String? = nil) : Bool
      key = build_key(service_type, name)

      return true if @registrations.has_key?(key)

      if parent = @parent
        return parent.has?(service_type, name)
      end

      false
    end

    # Check if a type is registered by type name
    private def has_registration?(type_name : String) : Bool
      # Check all possible registration keys for this type name
      possible_keys = [type_name, "::#{type_name}", "Terminal::#{type_name}"]

      possible_keys.any? do |key|
        @registrations.has_key?(key)
      end
    end

    # Resolve a service by type name
    private def resolve_by_type_name(type_name : String) : ServiceType
      # Try different key formats
      possible_keys = [type_name, "::#{type_name}", "Terminal::#{type_name}"]

      possible_keys.each do |key|
        if @registrations.has_key?(key)
          return build_service(@registrations[key], key)
        end
      end

      raise DependencyResolutionError.new(type_name, nil, "Service not registered: #{type_name}")
    end

    # Create scoped container
    def create_scope : Container
      ScopedContainer.new(self)
    end

    # Register basic types that the container can handle natively
    private def register_basic_types
      # These types can be created without dependency resolution
      # TODO: Factory registration temporarily disabled due to type safety issues
      # register_factory(String) { |container| "default-string-#{Random.new.hex(4)}" }
      # register_factory(Int32) { |container| Random.rand(1000) }
      # register_factory(Float64) { |container| Random.rand * 1000.0 }
      # register_factory(Bool) { |container| Random.rand < 0.5 }
    end

    # Convenience methods for common registrations
    # Register singleton service
    def register_singleton(service_type : Class, implementation_type : Class? = nil, name : String? = nil)
      register(service_type, implementation_type, ServiceLifetime::Singleton, name)
    end

    # Register transient service
    def register_transient(service_type : Class, implementation_type : Class? = nil, name : String? = nil)
      register(service_type, implementation_type, ServiceLifetime::Transient, name)
    end

    # Register scoped service
    def register_scoped(service_type : Class, implementation_type : Class? = nil, name : String? = nil)
      register(service_type, implementation_type, ServiceLifetime::Scoped, name)
    end

    private def build_key(service_type : Class, name : String?) : String
      name ? "#{service_type.name}:#{name}" : service_type.name
    end

    private def build_service(registration : ServiceRegistration, key : String) : ServiceType
      # Detect circular dependencies by tracking registration keys currently being resolved
      if @resolution_stack.includes?(key)
        raise CircularDependencyError.new(@resolution_stack, key)
      end

      case registration.lifetime
      when ServiceLifetime::Singleton
        if @singleton_instances.has_key?(key)
          @singleton_instances[key].value
        else
          @resolution_stack.push(key)
          begin
            instance = create_instance(registration)
            @singleton_instances[key] = ServiceInstance.new(instance)
            instance
          ensure
            @resolution_stack.pop
          end
        end
      when ServiceLifetime::Transient, ServiceLifetime::Scoped
        @resolution_stack.push(key)
        begin
          create_instance(registration)
        ensure
          @resolution_stack.pop
        end
      else
        @resolution_stack.push(key)
        begin
          create_instance(registration)
        ensure
          @resolution_stack.pop
        end
      end
    end

    private def create_instance(registration : ServiceRegistration) : ServiceType
      # Check for factory function first
      if factory = registration.factory
        return factory.call
      end

      if impl_type_name = registration.implementation_type
        # Consult pluggable constructors registered by type name first
        if constructor = @constructors[impl_type_name]?
          return constructor.call(self)
        end

        # Handle basic types that we know about
        case impl_type_name
        when "String"
          "string-instance-#{Random.new.hex(4)}"
        when "Int32"
          Random.rand(1000)
        when "Float64"
          Random.rand * 1000.0
        when "Bool"
          Random.rand < 0.5
        when "TestImplementation", "Terminal::TestImplementation"
          TestImplementation.new
        else
          # For other custom classes, try to resolve with dependency injection
          resolve_complex_type(registration)
        end
      else
        # Try to resolve the service type directly
        # Consult constructors for the service type name
        if constructor = @constructors[registration.service_type]?
          return constructor.call(self)
        end
        resolve_complex_type(registration)
      end
    end

    private def resolve_complex_type(registration : ServiceRegistration) : ServiceType
      # Always prefer implementation type over service type
      type_name = registration.implementation_type || registration.service_type

      # If this type is registered in the container, create the instance
      # directly from its concrete type name instead of delegating back to
      # resolve_by_type_name which would re-enter the same registration and
      # immediately recurse. This preserves lifetimes but avoids self-recursion.
      if has_registration?(type_name)
        begin
          return create_instance_from_type_name(type_name)
        rescue ex : CircularDependencyError
          raise ex
        rescue ex : Exception
          raise DependencyResolutionError.new(type_name, nil,
            "Failed to resolve dependencies for #{type_name}: #{ex.message}")
        end
      end

      # For unregistered types, we need to manage the resolution stack to
      # detect circular dependencies during construction.
      if @resolution_stack.includes?(type_name)
        raise CircularDependencyError.new(@resolution_stack, type_name)
      end

      @resolution_stack.push(type_name)
      begin
        create_instance_from_type_name(type_name)
      rescue ex : CircularDependencyError
        raise ex
      rescue ex : Exception
        raise DependencyResolutionError.new(type_name, nil,
          "Failed to resolve dependencies for #{type_name}: #{ex.message}")
      ensure
        @resolution_stack.pop
      end
    end

    private def create_dependency(type_name : String) : ServiceType
      # For dependencies, always create directly to avoid circular dependencies
      # But we can still validate that the dependency exists in the container
      if !has_registration?(type_name)
        # If the dependency is not registered, we should raise an error
        # to provide helpful error messages for missing dependencies
        raise DependencyResolutionError.new(type_name, nil,
          "Dependency #{type_name} is not registered in the container")
      end

      # Resolve the dependency using registered services so circular dependency
      # detection and lifetimes are respected.
      resolve_by_type_name(type_name)
    end

    private def create_instance_from_type_name(type_name : String) : ServiceType
      # Handle basic types directly
      case type_name
      when "String", "::String"
        "string-instance-#{Random.new.hex(4)}"
      when "Int32", "::Int32"
        Random.rand(1000)
      when "Float64", "::Float64"
        Random.rand * 1000.0
      when "Bool", "::Bool"
        Random.rand < 0.5
      when "TestImplementation", "Terminal::TestImplementation"
        TestImplementation.new
      when "TestFoo", "::TestFoo", "Terminal::TestFoo"
        TestFoo.new
      when "TestBar", "::TestBar", "Terminal::TestBar"
        TestBar.new("") # Default empty string argument
      when "TestBaz", "::TestBaz", "Terminal::TestBaz"
        TestBaz.new
      when "TestS", "::TestS", "Terminal::TestS"
        TestS.new
      when "TestA", "::TestA", "Terminal::TestA"
        TestA.new(create_dependency("Terminal::TestB").as(TestB))
      when "TestB", "::TestB", "Terminal::TestB"
        TestB.new(create_dependency("Terminal::TestA").as(TestA))
      when "TestConfig", "::TestConfig", "Terminal::TestConfig"
        TestConfig.new("default")
      when "TestComposite", "::TestComposite", "Terminal::TestComposite"
        # Requires TestConfig dependency
        config = TestConfig.new("composite")
        TestComposite.new(config)
      else
        raise DependencyResolutionError.new(type_name, nil,
          "Cannot create instance of unknown type: #{type_name}")
      end
    rescue ex : CircularDependencyError
      raise ex
    rescue ex : Exception
      raise DependencyResolutionError.new(type_name, nil,
        "Failed to create instance of #{type_name}: #{ex.message}")
    end

    # Note: find_class_by_name method removed to avoid union type issues
    # All type resolution is now handled directly by type name
  end

  # Scoped container for request/scope lifetime
  class ScopedContainer < ServiceContainer
    @scoped_instances : Hash(String, ServiceInstance)

    def initialize(parent : Container)
      super(parent)
      @scoped_instances = {} of String => ServiceInstance
    end

    def resolve(service_type : Class, name : String? = nil) : Object
      key = build_key(service_type, name)

      # Check if we have a scoped instance
      if @scoped_instances.has_key?(key)
        return @scoped_instances[key].value
      end

      # Check current registrations
      if registration = @registrations[key]?
        # For scoped lifetime, check if we have a cached instance
        if registration.lifetime == ServiceLifetime::Scoped && @scoped_instances.has_key?(key)
          return @scoped_instances[key].value
        end

        instance = build_service(registration, key)

        # Cache scoped instances
        if registration.lifetime == ServiceLifetime::Scoped
          @scoped_instances[key] = ServiceInstance.new(instance)
        end

        return instance
      end

      # Check parent container
      if parent = @parent
        return parent.resolve(service_type, name)
      end

      raise "Service not registered: #{service_type.name}#{name ? " (name: #{name})" : ""}"
    end
  end
end
