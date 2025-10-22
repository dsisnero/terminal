# Container System Implementation Plan

## Overview
Implementation of a dependency injection container system for Crystal with optional annotation support.

## Oracle Guidance Summary

### Architecture Recommendations
- **Core Container Interface**: Abstract container with register/resolve methods
- **Service Lifetimes**: Transient, Scoped, Singleton
- **Hybrid Approach**: Combine annotations with explicit registration

### Annotation Usage
- **Benefits**: Reduces boilerplate, cleaner code, compile-time checking
- **Drawbacks**: Magic behavior, less explicit, limited flexibility
- **Recommended**: Use selectively for simple services, prefer explicit registration for complex dependencies

## Implementation Phases

### Phase 1: Core Container (Week 1)
- [ ] Define basic container interface
- [ ] Implement ServiceContainer with registration system
- [ ] Add ServiceLifetime enum (Transient, Scoped, Singleton)
- [ ] Create ServiceRegistration record
- [ ] Basic resolve functionality

### Phase 2: Constructor Injection (Week 2)
- [ ] Implement dependency resolution
- [ ] Add constructor parameter analysis
- [ ] Support for interface/abstract class registration
- [ ] Factory registration support

### Phase 3: Annotation Support (Week 3)
- [ ] Define Inject, Singleton, Transient, Scoped annotations
- [ ] Create AnnotationContainer with auto-registration
- [ ] Add compile-time service discovery
- [ ] Hybrid registration system

### Phase 4: Advanced Features (Week 4)
- [ ] Scoped containers for web applications
- [ ] Service provider pattern
- [ ] Configuration integration
- [ ] Performance optimizations

### Phase 5: Testing & Documentation (Week 5)
- [ ] Comprehensive test suite
- [ ] Usage examples and documentation
- [ ] Performance benchmarks
- [ ] Integration examples

## Key Components

### Core Types
```crystal
abstract class Container
  abstract def register(service_type : Class, implementation_type : Class | Object, name : String? = nil)
  abstract def resolve(service_type : Class, name : String? = nil) : Object
  abstract def has?(service_type : Class, name : String? = nil) : Bool
end

enum ServiceLifetime
  Transient    # New instance each time
  Scoped       # One instance per scope
  Singleton    # Single instance for container lifetime
end

record ServiceRegistration,
  service_type : Class,
  implementation_type : Class | Object,
  lifetime : ServiceLifetime,
  factory : Proc(Container, Object)?,
  instance : Object? = nil,
  name : String? = nil
```

### Annotations
```crystal
annotation Inject; end
annotation Singleton; end
annotation Transient; end
annotation Scoped; end
```

## Design Decisions

1. **Hybrid Registration**: Support both explicit registration and annotation-based auto-registration
2. **Compile-time Safety**: Leverage Crystal's compile-time features for type safety
3. **Performance Focus**: Optimize for common use cases with caching and lazy resolution
4. **Web Framework Ready**: Design with HTTP request scopes in mind

## Success Metrics

- [ ] All core container functionality working
- [ ] Constructor injection with complex dependency graphs
- [ ] Annotation-based registration working
- [ ] Performance: < 1ms per resolve for singleton services
- [ ] Test coverage > 90%
- [ ] Clear documentation and examples

## Related Files
- [Main Plan](../plan.md)
- Container implementation source files
- Test specifications
- Usage examples

## Notes
- Consider integration with popular Crystal web frameworks
- Explore compile-time service graph validation
- Plan for extension points (custom lifetimes, decorators)