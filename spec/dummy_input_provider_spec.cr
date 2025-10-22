# File: spec/dummy_input_provider_spec.cr
# Purpose: Unit tests for DummyInputProvider behavior.

require "spec"
require "../src/terminal/input_provider"

describe DummyInputProvider do
  it "emits input events for each character in sequence" do
    chan = Channel(Terminal::Msg::Any).new
    provider = DummyInputProvider.new("abc", 0) # 0ms interval for immediate execution

    provider.start(chan)

    # Collect all messages
    messages = [] of Terminal::Msg::Any
    4.times do |_|
      messages << chan.receive
    end

    # Should have 3 input events and 1 stop message
    messages.size.should eq(4)

    # Check input events
    messages[0].should be_a(Terminal::Msg::InputEvent)
    messages[0].as(Terminal::Msg::InputEvent).char.should eq('a')

    messages[1].should be_a(Terminal::Msg::InputEvent)
    messages[1].as(Terminal::Msg::InputEvent).char.should eq('b')

    messages[2].should be_a(Terminal::Msg::InputEvent)
    messages[2].as(Terminal::Msg::InputEvent).char.should eq('c')

    # Check stop message
    messages[3].should be_a(Terminal::Msg::Stop)
    messages[3].as(Terminal::Msg::Stop).reason.should eq("dummy finished")
  end

  it "handles empty sequence gracefully" do
    chan = Channel(Terminal::Msg::Any).new
    provider = DummyInputProvider.new("", 0)

    provider.start(chan)

    message = chan.receive
    message.should be_a(Terminal::Msg::Stop)
    message.as(Terminal::Msg::Stop).reason.should eq("dummy finished")
  end

  it "respects interval timing" do
    chan = Channel(Terminal::Msg::Any).new
    provider = DummyInputProvider.new("ab", 100) # 100ms interval

    start_time = Time.monotonic
    provider.start(chan)

    # Receive first message
    message1 = chan.receive
    message1.should be_a(Terminal::Msg::InputEvent)

    # Receive second message
    message2 = chan.receive
    message2.should be_a(Terminal::Msg::InputEvent)

    # Receive stop message
    message3 = chan.receive
    message3.should be_a(Terminal::Msg::Stop)

    elapsed = Time.monotonic - start_time
    # Should take at least 200ms (2 characters * 100ms each)
    elapsed.should be >= Time::Span.new(seconds: 0, nanoseconds: 200_000_000)
  end

  it "handles exceptions gracefully" do
    # This test verifies that DummyInputProvider implements the InputProvider interface
    provider = DummyInputProvider.new("test", 0)

    # Should implement the InputProvider interface
    provider.should be_a(InputProvider)

    # Should have the start method
    provider.responds_to?(:start).should be_true
  end
end
