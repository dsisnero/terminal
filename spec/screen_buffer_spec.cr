# File: spec/screen_buffer_spec.cr
# Purpose: Tests for ScreenBuffer diff computation and message emission.

require "spec"
require "../src/terminal/messages"
require "../src/terminal/screen_buffer"
require "../src/terminal/cell"

describe ScreenBuffer do
  it "emits a ScreenDiff when content changes" do
    diff_chan = Channel(Terminal::Msg::Any).new
    buffer_chan = Channel(Terminal::Msg::Any).new

    buffer = ScreenBuffer.new(diff_chan)
    buffer.start(buffer_chan)

    frame1 = ["hello", "world"]
    frame2 = ["hello", "there"]

    spawn do
      buffer_chan.send(Terminal::Msg::ScreenUpdate.new(frame1))
      buffer_chan.send(Terminal::Msg::ScreenUpdate.new(frame2))
      buffer_chan.send(Terminal::Msg::Stop.new("done"))
    end

    msgs = [] of Terminal::Msg::Any
    3.times do
      msg = diff_chan.receive
      msgs << msg
    end

    diffs = msgs.select(Terminal::Msg::ScreenDiff).map(&.as(Terminal::Msg::ScreenDiff))
    diffs.size.should be > 0

    diffs.last.changes.size.should eq 1
    diffs.last.changes.first[0].should eq 1 # line index changed
  end
end
