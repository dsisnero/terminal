# Simple Dependency Injection Container for Terminal UI
# Uses the same pattern as the working container

module Terminal
  # Service lifetime management
  enum ServiceLifetime
    Transient # New instance each time
    Scoped    # One instance per scope
    Singleton # Single instance for container lifetime
  end

  # Wrapper class to hold any service instance
  class ServiceInstance
    @value : String | Int32 | Bool | Float64 | Nil
    getter value

    def initialize(@value : String | Int32 | Bool | Float64 | Nil)
    end
  end

  # Service registration information
  class ServiceRegistration
    getter service_type : String
    getter lifetime : ServiceLifetime
    getter factory : -> ServiceInstance

    def initialize(@service_type, @lifetime, @factory)
    end
  end

  # Main container implementation
  class Container
    def initialize
      @registrations = {} of String => ServiceRegistration
      @instances = {} of String => ServiceInstance
      @mutex = Mutex.new
    end

    # Register a service with a factory block
    def register(type : T.class, lifetime : ServiceLifetime = ServiceLifetime::Singleton, &factory : -> T) forall T
      name = type.name
      wrapped_factory = -> { ServiceInstance.new(factory.call) }

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
        @instances[name] = ServiceInstance.new(instance)
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
      raise "No factory/instance registered for #{name}" unless registration

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
      else
        raise "Unknown service lifetime: #{registration.lifetime}"
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
