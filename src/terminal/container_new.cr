module Terminal
  # Simple, type-safe DI container using untyped storage
  class SimpleContainer
    # Broad union type to cover test fixtures that use both `Test*` and `Simple*` classes
    alias SimpleContainerValue = ::TestImplementation | ::TestDatabaseConfig | ::TestDatabaseConnection | ::NewUserRepository | ::SimpleDatabaseConfig | ::SimpleDatabaseConnection | ::SimpleUserRepository

    # Wrapper class to hold any service instance (typed to the union above)
    class ServiceInstance
      @value : SimpleContainerValue

      def initialize(@value : SimpleContainerValue)
      end

      def value : SimpleContainerValue
        @value
      end
    end

    # Type alias for all supported service types (local to SimpleContainer)
    alias SimpleServiceType = TestImplementation | TestDatabaseConfig | TestDatabaseConnection | NewUserRepository

    def initialize
      # Store factories as Proc that return wrapped instances
      @factories = {} of String => Proc(ServiceInstance)
      # Store created singletons as wrapped instances
      @singletons = {} of String => ServiceInstance
      @mutex = Mutex.new
    end

    # Register a factory for type T with a block
    def register_type(type : T.class, &factory : -> T) forall T
      name = type.name
      factory_proc = -> { ServiceInstance.new(factory.call.as(SimpleContainerValue)) }

      @mutex.synchronize do
        @factories[name] = factory_proc
      end
      nil
    end

    # Register a factory for type T without a block (uses T.new)
    def register_type(type : T.class) forall T
      name = type.name
      factory_proc = -> { ServiceInstance.new(type.new.as(SimpleContainerValue)) }

      @mutex.synchronize do
        @factories[name] = factory_proc
      end
      nil
    end

    # Register an already-created instance (useful for config objects, external resources, mocks)
    def register_instance(type : T.class, instance : T) forall T
      @mutex.synchronize do
        @singletons[type.name] = ServiceInstance.new(instance.as(SimpleContainerValue))
      end
      nil
    end

    # Resolve a typed value (returns T).
    # This will return a previously registered instance (singleton),
    # otherwise call the registered factory and store it as singleton.
    #
    # If you want transient behavior, add an option or separate method.
    def resolve(type : T.class) : T forall T
      name = type.name

      # fast path: existing singleton (no locking reads performed here for speed)
      if inst = @singletons[name]?
        return inst.value.as(T)
      end

      # lock to ensure only one thread constructs singleton
      @mutex.synchronize do
        # double-check inside lock
        if inst = @singletons[name]?
          return inst.value.as(T)
        end

        factory = @factories[name]?
        raise "No factory/instance registered for #{name}" unless factory

        # Release the lock before calling factory to avoid deadlocks
        # This is safe because we've already checked for existing instances
        factory_proc = factory
        @mutex.unlock
        begin
          instance = factory_proc.call
        ensure
          @mutex.lock
        end

        # store as singleton
        @singletons[name] = instance
        return instance.value.as(T)
      end
    end

    # Optionally resolve without caching (transient)
    def resolve_transient(type : T.class) : T forall T
      factory = @factories[type.name]?
      raise "No factory registered for #{type.name}" unless factory
      instance = factory.call
      instance.value.as(T)
    end

    # Utility: clear registrations (tests)
    def clear!
      @mutex.synchronize do
        @factories.clear
        @singletons.clear
      end
      nil
    end
  end
end
