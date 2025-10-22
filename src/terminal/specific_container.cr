module Terminal
  # Simple DI container using specific union type for test classes
  class SimpleContainer
    # Define the union type for our test classes
    alias ServiceType = SimpleDatabaseConfig | SimpleDatabaseConnection | SimpleUserRepository

    def initialize
      @factories = {} of String => Proc(ServiceType)
      @singletons = {} of String => ServiceType
      @mutex = Mutex.new
    end

    # Register a type with default constructor
    def register_type(type : T.class) forall T
      name = type.name
      factory_proc = -> { type.new.as(ServiceType) }
      @factories[name] = factory_proc
    end

    # Register a type with custom factory
    def register_type(type : T.class, &block : -> T) forall T
      name = type.name
      factory_proc = -> { block.call.as(ServiceType) }
      @factories[name] = factory_proc
    end

    # Register a singleton instance
    def register_instance(type : T.class, instance : T) forall T
      @singletons[type.name] = instance.as(ServiceType)
    end

    # Resolve a type
    def resolve(type : T.class) : T forall T
      name = type.name

      if @singletons.has_key?(name)
        instance = @singletons[name]
        if instance.is_a?(T)
          return instance
        else
          raise "Resolved instance is not of expected type #{T}. Got: #{instance.class}"
        end
      end

      if @factories.has_key?(name)
        factory = @factories[name]
        instance = factory.call
        if instance.is_a?(T)
          return instance
        else
          raise "Factory produced instance is not of expected type #{T}. Got: #{instance.class}"
        end
      end

      raise "No factory or singleton registered for type: #{name}"
    end

    def clear!
      @mutex.synchronize do
        @factories.clear
        @singletons.clear
      end
    end
  end
end
