module Terminal
  # Lightweight facade around Container implementations that provides
  # a simpler API for common operations while still allowing access
  # to async and pluggable constructors available on ServiceContainer.
  class ServiceProvider
    getter container : Container

    def initialize(@container : Container = ServiceContainer.new)
    end

    # Synchronous resolve
    def resolve(type : Class, name : String? = nil) : Object
      @container.resolve(type, name)
    end

    # Async resolve returns a Channel that will receive the ServiceType
    def resolve_async(type : Class, name : String? = nil) : Channel(ServiceType)
      @container.resolve_async(type, name)
    end

    # Register a synchronous factory. If the underlying container is a
    # ServiceContainer it will call the extended API; otherwise we attempt
    # a best-effort call (duck-typed).
    def register_factory(type : Class, name : String? = nil, lifetime : ServiceLifetime = ServiceLifetime::Transient, &block : Container -> ServiceType)
      if @container.is_a?(ServiceContainer)
        (@container.as(ServiceContainer)).register_factory(type, name, lifetime, &block)
      else
        # Best-effort: try to call register_factory on the container
        @container.register_factory(type, name, lifetime, &block) rescue nil
      end
    end

    # Register an async factory. Delegates to ServiceContainer when available.
    def register_async_factory(type : Class, name : String? = nil, &block : Channel(ServiceType) -> Nil)
      if @container.is_a?(ServiceContainer)
        (@container.as(ServiceContainer)).register_async_factory(type, name, &block)
      else
        @container.register_async_factory(type, name, &block) rescue nil
      end
    end

    # Convenience wrappers
    def register_singleton(type : Class, name : String? = nil)
      if @container.is_a?(ServiceContainer)
        (@container.as(ServiceContainer)).register_singleton(type, nil, name)
      else
        @container.register_singleton(type, nil, name) rescue nil
      end
    end

    def register_transient(type : Class, name : String? = nil)
      if @container.is_a?(ServiceContainer)
        (@container.as(ServiceContainer)).register_transient(type, nil, name)
      else
        @container.register_transient(type, nil, name) rescue nil
      end
    end

    def create_scope : ServiceProvider
      if @container.is_a?(ServiceContainer)
        ServiceProvider.new((@container.as(ServiceContainer)).create_scope)
      else
        ServiceProvider.new(@container.create_scope) rescue ServiceProvider.new(@container)
      end
    end
  end
end
