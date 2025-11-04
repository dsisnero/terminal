# File: spec/terminal_integration_spec.cr
# Purpose: Integration test simulating full terminal data flow.

require "spec"
require "../src/terminal/messages"
require "../src/terminal/screen_buffer"
require "../src/terminal/diff_renderer"
require "../src/terminal/cursor_manager"
require "../src/terminal/widget_manager"

describe "Terminal Integration" do
  it "flows data from widget -> screen buffer -> diff renderer" do
    io = IO::Memory.new
    diff_chan = Channel(Terminal::Msg::Any).new

    # Set up components
    screen = ScreenBuffer.new(diff_chan)
    renderer = DiffRenderer.new(io, use_alternate_screen: false)
    cursor = CursorManager.new(io)

    screen.start(diff_chan)
    renderer.start(diff_chan)
    cursor.start(diff_chan)

    # Simulate widget output - send ScreenUpdate through the channel
    cells = [Cell.new('O'), Cell.new('K')]
    diff_chan.send(Terminal::Msg::ScreenUpdate.new([cells]))

    # Stop fibers
    diff_chan.send(Terminal::Msg::Stop.new)
    sleep(Time::Span.new(nanoseconds: 50_000_000))

    io.rewind
    output = io.gets_to_end

    output.should contain('O')
    output.should contain('K')
  end
end
