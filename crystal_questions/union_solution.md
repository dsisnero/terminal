Nice problem — Crystal’s static type system makes building a fully-dynamic DI
container less straightforward than in Ruby/Java/C#. You’ve already found the
pain: unions and Object don’t give you the ergonomics you want, and generic
containers are statically monomorphic. Below I give a practical, idiomatic
approach that many Crystal libraries use: store factories and instances as
untyped (Proc.untyped and untyped values), so the container can hold anything
at runtime, and expose a generic resolve(T) API so callers get a properly-typed
value at compile time (we cast at the last moment using .as(T)). This keeps
compile-time type-safety for callers while allowing a heterogeneous runtime
store. Key ideas (short) Register factories (closures that create instances)
keyed by the type name (or class object). Factories are stored as Proc.untyped.
Resolve generically: resolve(T) : T looks up factory/instance by T.name, calls
factory (if needed), and returns instance.as(T). Singleton/Transient: you can
store the created instance in the container to provide singletons; otherwise
return a fresh instance each resolve. Thread-safety: protect registrations
and singleton initializations with a Mutex if your use is concurrent. Macros
(optional): If you want compile-time registration convenience, use a macro
register Foo that expands to container.register(Foo). But registration itself is
usually runtime (so it can use constructors with runtime args).

```
  # simple_container.cr

class Container
  def initialize
    # store factories as untyped Proc so they can produce any runtime type
    @factories = {} of String => Proc.untyped
    # store created singletons as untyped values
    @singletons = {} of String => untyped
    @mutex = Mutex.new
  end

  # Register a factory for type T.
  # If a block is given, use it as the factory. Otherwise default factory calls T.new
  def register_type(T, &factory)
    name = T.name
    factory_proc = if factory
      factory.as(Proc.untyped)
    else
      -> { T.new }.as(Proc.untyped)
    end

    @mutex.synchronize do
      @factories[name] = factory_proc
    end
    nil
  end

  # Register an already-created instance (useful for config objects, external resources, mocks)
  def register_instance(T, instance : T)
    @mutex.synchronize do
      @singletons[T.name] = instance
    end
    nil
  end

  # Resolve a typed value (returns T).
  # This will return a previously registered instance (singleton),
  # otherwise call the registered factory and store it as singleton.
  #
  # If you want transient behavior, add an option or separate method.
  def resolve(T) : T
    name = T.name

    # fast path: existing singleton (no locking reads performed here for speed)
    if inst = @singletons[name]
      return inst.as(T)
    end

    # lock to ensure only one thread constructs singleton
    @mutex.synchronize do
      # double-check inside lock
      if inst = @singletons[name]
        return inst.as(T)
      end

      factory = @factories[name]
      raise "No factory/instance registered for #{name}" unless factory

      instance = factory.call
      # store as singleton
      @singletons[name] = instance
      return instance.as(T)
    end
  end

  # Optionally resolve without caching (transient)
  def resolve_transient(T) : T
    factory = @factories[T.name] or raise "No factory registered for #{T.name}"
    instance = factory.call
    instance.as(T)
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

`
```
# example.cr

class Repo
  def initialize
  end

  def greet
    "hello from repo"
  end
end

class Service
  getter repo : Repo

  def initialize(@repo : Repo)
  end

  def hello
    @repo.greet
  end
end

container = Container.new

# Register Repo with default constructor
container.register_type(Repo)

# Register Service with custom factory so we can inject Repo
container.register_type(Service) do
  repo = container.resolve(Repo)
  Service.new(repo)
end

# Resolve typed
service = container.resolve(Service)
puts service.hello  # => "hello from repo"


This gives you compile-time typed Service and Repo at call sites, while allowing the container runtime to hold arbitrary types.
Why this works and why it’s safe-ish
At runtime we store completely dynamic values (untyped), but callers use resolve(T) which returns T. The cast instance.as(T) will raise a runtime error if the stored value does not actually match T. So the API is type-safe as long as registration is correct.
Because registration is explicit (you must register_type or register_instance), you won't accidentally get the wrong type without someone having incorrectly registered something.
Alternatives / patterns
Key by Class instead of String
You can use Hash(Class, Proc.untyped) (or Hash(Class(T), Proc.untyped)) as the registry key if you prefer @factories[Repo.class] = .... Using the T.name string is simpler and works well; class objects are a bit more robust but either is fine.
Use macros to generate typed registration accessors
If you want compile-time guarantees for registrations, macros can generate specific register_repo methods or typed constants, but macros are compile-time — they won’t let you register "unknown at compile-time" types without invoking the generated macro.
Use special boxed wrapper types
You can write a wrapper Box with a generic Box(T) subclass that inherits from BoxBase and store a BoxBase in a hash. This is effectively the same as storing untyped values, but gives you a neat BoxBase#to_untyped interface. The core challenge (heterogeneous types inside one collection) still requires an untyped backing at some layer.
Pointer boxing (advanced / unsafe)
Some authors use Pointer(Void) or manual boxing for ultimate performance. This is error-prone and usually unnecessary.
Service factories keyed by interface name
If you register implementations for abstract module/interface types, use the interface T.name as key. The container will return the concrete instance cast to the interface type.
Thread-safety & lifecycle
The sample stores every created object as a singleton. If you want transient instances, call resolve_transient(T) or change behavior based on registration options.
Protect writes and lazy-initialization with a Mutex (shown).
For more advanced lifecycle (Dispose, Scoped per-request), extend registration metadata to include lifetime and disposal callbacks.
How other Crystal DI containers handle it (summary)
Most Crystal DI libs use one of the techniques above: factories stored as Proc.untyped or macros-generated typed registries.
Because Crystal is compiled and strongly typed, DI is commonly performed with explicit registration code at app startup (you register the concrete factory for each interface/type you use).
Libraries may provide syntactic sugar and macro helpers, but the runtime representation is usually untyped at some layer and cast back to the requested type on resolve.
Pitfalls & gotchas
instance.as(T) will raise at runtime if incorrect — registration must be accurate.
Using T.name as key fails if you have two different classes with same name in different modules unless you use a fully qualified name; T.name is typically fully-qualified (e.g. My::Module::Repo) but be aware.
Avoid storing raw Object type as an ivar for boxing — Crystal has restrictions on Object in certain places; using untyped or Proc.untyped sidesteps those restrictions at the cost of compile-time checks in the container internals.
Keep thread-safety in mind if your app is multi-threaded.
Closing / Next steps suggestions
If you want, I can:
convert the container to use Class keys instead of strings,
add explicit lifetime options (:singleton, :transient, :scoped),
show a macro-based registration DSL for nicer syntax,
or implement a small tests suite that demonstrates failure modes (bad registrations -> runtime error).
Tell me which of those you'd like and I’ll extend the code.

`