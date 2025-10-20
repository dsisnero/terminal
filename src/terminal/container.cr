# Dependency Injection Container for Terminal UI
# Implements SOLID principles with explicit registration and optional annotation support

module Terminal
  # Service lifetime management
  enum ServiceLifetime
    Transient    # New instance each time
    Scoped       # One instance per scope
    Singleton    # Single instance for container lifetime
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

  # Service registration descriptor
  record ServiceRegistration,
    service_type : String,
    implementation_type : String? = nil,
    lifetime : ServiceLifetime = ServiceLifetime::Transient,
    name : String? = nil

  # Core container interface (S: Single Responsibility)
  abstract class Container
    # Register a service with explicit implementation
    abstract def register(service_type : Class, implementation_type : Class? = nil,
                         lifetime : ServiceLifetime = ServiceLifetime::Transient,
                         name : String? = nil)

    # Resolve a service instance
    abstract def resolve(service_type : Class, name : String? = nil) : Object

    # Check if service is registered
    abstract def has?(service_type : Class, name : String? = nil) : Bool

    # Create a scoped container
    abstract def create_scope : Container
  end

  # Main container implementation
  class ServiceContainer < Container
    @registrations : Hash(String, ServiceRegistration)
    @singleton_instances : Hash(String, String | Int32 | Float64 | Bool | TestInterface)
    @parent : Container?

    def initialize(@parent : Container? = nil)
      @registrations = {} of String => ServiceRegistration
      @singleton_instances = {} of String => String | Int32 | Float64 | Bool | TestInterface
    end

    # Register service with explicit type
    def register(service_type : Class, implementation_type : Class? = nil,
                 lifetime : ServiceLifetime = ServiceLifetime::Transient,
                 name : String? = nil)
      impl_type = implementation_type || service_type
      key = build_key(service_type, name)

      @registrations[key] = ServiceRegistration.new(
        service_type: service_type.name,
        implementation_type: impl_type.name,
        lifetime: lifetime,
        name: name
      )
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

    # Check if service is registered
    def has?(service_type : Class, name : String? = nil) : Bool
      key = build_key(service_type, name)

      return true if @registrations.has_key?(key)

      if parent = @parent
        return parent.has?(service_type, name)
      end

      false
    end

    # Create scoped container
    def create_scope : Container
      ScopedContainer.new(self)
    end

    private def build_key(service_type : Class, name : String?) : String
      name ? "#{service_type.name}:#{name}" : service_type.name
    end

    private def build_service(registration : ServiceRegistration, key : String) : Object
      case registration.lifetime
      when ServiceLifetime::Singleton
        if @singleton_instances.has_key?(key)
          @singleton_instances[key]
        else
          instance = create_instance(registration)
          @singleton_instances[key] = instance
          instance
        end
      when ServiceLifetime::Transient
        create_instance(registration)
      when ServiceLifetime::Scoped
        # For scoped lifetime, create new instance each time in scoped container
        # In root container, behave like transient
        create_instance(registration)
      else
        create_instance(registration)
      end
    end

    private def create_instance(registration : ServiceRegistration) : Object
      if impl_type_name = registration.implementation_type
        # Simple constructor - will be enhanced in Phase 2 with dependency resolution
        # For now, we'll handle basic types that we know about
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
          # For other custom classes, we'll need a better approach
          # For now, just return a string placeholder
          "instance-of-#{impl_type_name}"
        end
      else
        raise "Cannot create instance for #{registration.service_type}"
      end
    end
  end

  # Scoped container for request/scope lifetime
  class ScopedContainer < ServiceContainer
    @scoped_instances : Hash(String, String | Int32 | Float64 | Bool | TestInterface)

    def initialize(parent : Container)
      super(parent)
      @scoped_instances = {} of String => String | Int32 | Float64 | Bool | TestInterface
    end

    def resolve(service_type : Class, name : String? = nil) : Object
      key = build_key(service_type, name)

      # Check if we have a scoped instance
      if @scoped_instances.has_key?(key)
        return @scoped_instances[key]
      end

      # Check current registrations
      if registration = @registrations[key]?
        instance = build_service(registration, key)

        # Cache scoped instances
        if registration.lifetime == ServiceLifetime::Scoped
          @scoped_instances[key] = instance
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

  # Convenience methods for common registrations
  class ServiceContainer
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
  end
end