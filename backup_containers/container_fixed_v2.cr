# Fixed Dependency Injection Container for Terminal UI
# Uses type-safe factory approach with wrapper class

module Terminal
  # Service lifetime management
  enum ServiceLifetime
    Transient # New instance each time
    Scoped    # One instance per scope
    Singleton # Single instance for container lifetime
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
    def initialize(service_type : String, dependency_type : String)
      super("Circular dependency detected: #{service_type} -> #{dependency_type}")
    end
  end

  # Wrapper class to hold any service instance
  class ServiceInstance(T)
    getter value : T

    def initialize(@value : T)
    end
  end

  # Service registration information
  class ServiceRegistration
    getter service_type : String
    getter lifetime : ServiceLifetime
    getter factory : Proc(ServiceInstance(Object))

    def initialize(@service_type, @lifetime, @factory)
    end
  end

  # Main container implementation
  class Container
    def initialize
      @registrations = {} of String => ServiceRegistration
      @instances = {} of String => ServiceInstance(Object)
      @mutex = Mutex.new
    end

    # Register a service with a factory block
    def register(type : T.class, lifetime : ServiceLifetime = ServiceLifetime::Singleton, &factory : -> T) forall T
      name = type.name
      wrapped_factory = -> { ServiceInstance(T).new(factory.call) }

      @mutex.synchronize do
        @registrations[name] = ServiceRegistration.new(name, lifetime, wrapped_factory)
      end
      nil
    end

    # Register a service using default constructor
    def register(type : T.class, lifetime : ServiceLifetime = ServiceLifetime::Singleton) forall T
      register(type, lifetime) { type.new }
    end

    # Convenience methods for different lifetimes
    def register_transient(type : T.class, &factory : -> T) forall T
      register(type, ServiceLifetime::Transient, &factory)
    end

    def register_transient(type : T.class) forall T
      register(type, ServiceLifetime::Transient)
    end

    def register_singleton(type : T.class, &factory : -> T) forall T
      register(type, ServiceLifetime::Singleton, &factory)
    end

    def register_singleton(type : T.class) forall T
      register(type, ServiceLifetime::Singleton)
    end

    def register_scoped(type : T.class, &factory : -> T) forall T
      register(type, ServiceLifetime::Scoped, &factory)
    end

    def register_scoped(type : T.class) forall T
      register(type, ServiceLifetime::Scoped)
    end

    # Register an existing instance
    def register_instance(type : T.class, instance : T) forall T
      name = type.name

      @mutex.synchronize do
        @instances[name] = ServiceInstance(T).new(instance)
      end
      nil
    end

    # Resolve a service
    def resolve(type : T.class) : T forall T
      name = type.name

      # Check for existing instance first
      if instance = @instances[name]?
        return instance.value.as(T)
      end

      # Look up registration
      registration = @registrations[name]?
      raise MissingDependencyError.new(name, "factory") unless registration

      # Create instance based on lifetime
      case registration.lifetime
      when ServiceLifetime::Singleton
        @mutex.synchronize do
          # Double-check inside lock
          if instance = @instances[name]?
            return instance.value.as(T)
          end

          instance = registration.factory.call
          @instances[name] = instance
          instance.value.as(T)
        end
      when ServiceLifetime::Transient
        registration.factory.call.value.as(T)
      when ServiceLifetime::Scoped
        # For scoped, we'd need a scope context - for now treat as transient
        registration.factory.call.value.as(T)
      end
    end

    # Clear all registrations and instances (for testing)
    def clear!
      @mutex.synchronize do
        @registrations.clear
        @instances.clear
      end
      nil
    end
  end

  # Alias for backward compatibility
  ServiceContainer = Container
end
