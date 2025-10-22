# Crystal Union Types and Generic Container Problem

## Problem Overview

We're building a dependency injection container in Crystal that needs to handle arbitrary types, but we're running into limitations with Crystal's type system, particularly around union types and generic constraints.

## Current Implementation

```crystal
# Original approach using union types
alias ServiceType = String | Int32 | Float64 | Bool | TestImplementation

class ServiceInstance
  getter value : ServiceType

  def initialize(@value : ServiceType)
  end
end

class ServiceContainer
  @singleton_instances : Hash(String, ServiceInstance)

  def resolve(service_type : Class, name : String? = nil) : ServiceType
    # Implementation that returns ServiceType
  end
end
```

## The Problem

1. **Restrictive Union Type**: The `ServiceType` union only includes predefined types, making it impossible to register custom classes without modifying the union.

2. **Type Safety vs Flexibility**: We want type safety but also need the container to handle any registered type dynamically.

3. **Generic Type Limitations**: When we tried to make `ServiceInstance` generic:

```crystal
class ServiceInstance(T)
  getter value : T

  def initialize(@value : T)
  end
end
```

We encountered these issues:
- Can't use `Object` as generic type parameter: `ServiceInstance(Object)`
- Can't use `Object` as instance variable type: `@value : Object`
- Can't create a heterogeneous collection that can hold `ServiceInstance` of different types

## Failed Approaches

### Approach 1: Non-generic with Object
```crystal
class ServiceInstance
  getter value : Object  # Error: can't use Object as instance variable type

  def initialize(@value : Object)
  end
end
```

### Approach 2: Generic with type parameter
```crystal
@singleton_instances = {} of String => ServiceInstance(Object)
# Error: can't use Object as generic type argument
```

### Approach 3: Using union of all possible types
```crystal
alias ServiceType = String | Int32 | Float64 | Bool | TestImplementation |
                    DatabaseConfig | DatabaseConnection | UserRepository |
                    ServiceA | ServiceB | MultiConstructor
# Not scalable - have to update union for every new type
```

## Core Challenge

Crystal's type system requires specific types at compile time, but our container needs to:
- Store instances of arbitrary types
- Return properly typed instances when resolved
- Maintain type safety
- Be extensible without modifying core container code

## Questions for Oracle

1. How can we create a type-safe container that can handle arbitrary types without using `Object` or restrictive unions?

2. What patterns exist in Crystal for creating heterogeneous collections that maintain type information?

3. Is there a way to use generics or macros to solve this problem?

4. How do other Crystal DI containers handle this problem?

## Current Workaround

We're currently hardcoding type creation logic:

```crystal
private def create_instance_from_type_name(type_name : String) : Object
  case type_name
  when "String" then "string-instance"
  when "TestImplementation" then TestImplementation.new
  when "DatabaseConfig" then DatabaseConfig.new
  # ... more hardcoded types
  else
    raise "Cannot create instance of unknown type: #{type_name}"
  end
end
```

This is not scalable and defeats the purpose of a generic container.