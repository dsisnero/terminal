# File: spec/spec_helper.cr
# Purpose: Common spec setup for terminal library tests

require "spec"
require "../src/terminal"
require "../src/spec_support/runtime_helper"

# Helper for rendering grids to strings (for testing)
module SpecHelper
  def self.grid_to_lines(grid : Array(Array(Cell))) : Array(String)
    grid.map(&.map(&.char).join)
  end
end
