# File: spec/cursor_manager_spec.cr
# Purpose: Tests for CursorManager cursor visibility and movement.

require "spec"
require "../src/terminal/messages"
require "../src/terminal/cursor_manager"

describe CursorManager do
  it "handles hide, move, show, and stop messages" do
    io = IO::Memory.new
    chan = Channel(Terminal::Msg::Any).new
    cursor = CursorManager.new(io)
    cursor.start(chan)

    spawn do
      chan.send(Terminal::Msg::CursorHide.new)
      chan.send(Terminal::Msg::CursorMove.new(2, 4))
      chan.send(Terminal::Msg::CursorShow.new)
      chan.send(Terminal::Msg::Stop.new)
    end

    # Wait briefly for fiber processing
    sleep(Time::Span.new(nanoseconds: 50_000_000))
    io.rewind
    output = io.gets_to_end

    output.should contain("\e[?25l") # hide
    output.should contain("\e[3;5H") # move (1-based)
    output.should contain("\e[?25h") # show
  end
end
