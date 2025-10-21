require "spec"
require "../src/terminal/container"

include Terminal

# Top-level test classes (Crystal requires types to be declared at top-level)
# Top-level test classes (Crystal requires types to be declared at top-level)
class TestFoo
  def value : String
    "foo"
  end
end

class TestBar
  @x : String

  def initialize(@x : String)
  end

  def x : String
    @x
  end
end

class TestBaz; end

class TestS
  @n : Float64

  def initialize
    @n = Random.new.rand
  end

  def n : Float64
    @n
  end
end

class TestA
  def initialize(b : TestB)
  end
end

class TestB
  def initialize(a : TestA)
  end
end

describe ServiceContainer do

  it "registers and resolves a simple type" do
  container = ServiceContainer.new
  container.register_type(TestFoo)
  inst = container.resolve(TestFoo).as(TestFoo)
  inst.should be_a(TestFoo)
  inst.value.should eq("foo")
  end

  it "supports factories and instances" do
  container = ServiceContainer.new
  container.register_factory(TestBar) { |_| TestBar.new("f") }
  b = container.resolve(TestBar).as(TestBar)
  b.x.should eq("f")

  baz = TestBaz.new
  container.register_instance(TestBaz, baz)
  container.resolve(TestBaz).as(TestBaz).should be(baz)
  end

  it "respects singleton and transient lifetimes" do
  container = ServiceContainer.new
  container.register_type(TestS)
  s1 = container.resolve(TestS).as(TestS)
  s2 = container.resolve(TestS).as(TestS)
  s1.n.should eq(s2.n)

  container.register_transient(String)
  i1 = container.resolve(String).as(String)
  i2 = container.resolve(String).as(String)
  i1.should_not eq(i2)
  end

  it "handles named services and scopes" do
  container = ServiceContainer.new
  container.register_transient(String, name: "a")
  container.register_transient(String, name: "b")
  a = container.resolve(String, "a").as(String)
  b = container.resolve(String, "b").as(String)
    a.should_not eq(b)

  container.register_singleton(String)
  scope = container.create_scope
  scope.resolve(String).as(String).should eq(container.resolve(String).as(String))
  end

  it "detects circular dependencies" do
  container = ServiceContainer.new
  container.register_singleton(TestA)
  container.register_singleton(TestB)
  expect_raises(CircularDependencyError) { container.resolve(TestA).as(TestA) }
  end
end