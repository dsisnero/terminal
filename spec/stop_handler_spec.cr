require "./spec_helper"

describe Terminal::StopHandler do
  it "forwards signals once and restores traps" do
    chan = Channel(Terminal::Msg::Any).new(1)
    cleanup = Terminal::StopHandler.install_signal_forwarders(
      chan,
      [Signal::TERM],
      -> { Terminal::Msg::Stop.new("sigterm") }
    )

    Process.signal(Signal::TERM, Process.pid)
    msg = chan.receive
    msg.should be_a(Terminal::Msg::Stop)
    msg.as(Terminal::Msg::Stop).reason.should eq("sigterm")

    Process.signal(Signal::TERM, Process.pid)
    select
    when unexpected = chan.receive
      raise "Received duplicate stop message: #{unexpected}"
    when timeout(10.milliseconds)
      # expected: second signal ignored
    end

    cleanup.call
  end
end
