# File: spec/cell_spec.cr
# Purpose: Unit tests for Cell behavior and ANSI rendering.

require "spec"
require "../src/terminal/cell"

describe Cell do
  it "compares equality correctly" do
    a = Cell.new('A', "red", "blue", true, true)
    b = Cell.new('A', "red", "blue", true, true)
    c = Cell.new('B', "red", "blue", true, true)

    a.should eq b
    a.should_not eq c
  end

  it "renders ANSI output for styled cells" do
    io = IO::Memory.new
    c = Cell.new('X', "red", "blue", true, true)
    c.to_ansi(io)
    io.rewind
    out = io.gets_to_end

    out.should contain("\e[")
    out.should contain('X')
  end

  it "renders plain cells without styles" do
    io = IO::Memory.new
    c = Cell.new('Y')
    c.to_ansi(io)
    io.rewind
    out = io.gets_to_end

    out.should eq("Y")
  end
end
