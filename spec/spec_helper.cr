# File: spec/spec_helper.cr
# Purpose: Common spec setup for terminal library tests

require "spec"
require "../src/terminal/prelude"
require "../src/terminal/container"
require "../src/terminal/terminal_application"
require "../src/terminal/interactive_streaming_ui"
require "../src/terminal/wait_group"

# Helper for rendering grids to strings (for testing)
module SpecHelper
  def self.grid_to_lines(grid : Array(Array(Cell))) : Array(String)
    grid.map(&.map(&.char).join)
  end
end
