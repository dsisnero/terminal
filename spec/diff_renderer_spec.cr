# File: spec/diff_renderer_spec.cr
# Purpose: Unit tests for DiffRenderer rendering ANSI sequences to IO.

require "spec"
require "../src/terminal/messages"
require "../src/terminal/diff_renderer"
require "../src/terminal/cell"

describe DiffRenderer do
  it "renders ScreenDiff changes to IO" do
    io = IO::Memory.new
    renderer = DiffRenderer.new(io, use_alternate_screen: false)
    diff_chan = Channel(Terminal::Msg::Any).new

    renderer.start(diff_chan)

    cells = [Cell.new('H'), Cell.new('i')]
    diff = Terminal::Msg::ScreenDiff.new([{0, cells.as(Terminal::Msg::Payload)}])

    spawn do
      diff_chan.send(diff)
      diff_chan.send(Terminal::Msg::Stop.new)
    end

    # Give time for fiber to process messages
    sleep(Time::Span.new(nanoseconds: 100_000_000))
    io.rewind
    output = io.gets_to_end

    output.should contain('H')
    output.should contain('i')
  end
end
