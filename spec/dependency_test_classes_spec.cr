# Test classes for dependency resolution testing

# Simple dependency chain
class DatabaseConfig
  @host : String
  @port : Int32

  def initialize
    @host = "localhost"
    @port = 5432
  end

  def host : String
    @host
  end

  def port : Int32
    @port
  end
end

class DatabaseConnection
  def initialize(config : DatabaseConfig)
    @config = config
  end

  def config : DatabaseConfig
    @config
  end
end

class UserRepository
  def initialize(db : DatabaseConnection)
    @db = db
  end

  def db : DatabaseConnection
    @db
  end
end

# Circular dependency test classes
class ServiceA
  def initialize(service_b : ServiceB)
    @service_b = service_b
  end

  def service_b : ServiceB
    @service_b
  end
end

class ServiceB
  def initialize(service_a : ServiceA)
    @service_a = service_a
  end

  def service_a : ServiceA
    @service_a
  end
end

# Email service for testing
class EmailService
  @smtp_host : String
  @smtp_port : Int32

  def initialize
    @smtp_host = "smtp.example.com"
    @smtp_port = 587
  end

  def smtp_host : String
    @smtp_host
  end

  def smtp_port : Int32
    @smtp_port
  end
end

# Class with multiple constructors
class MultiConstructor
  @value : String

  def initialize
    @value = "default"
  end

  def initialize(value : String)
    @value = value
  end

  def value : String
    @value
  end
end
