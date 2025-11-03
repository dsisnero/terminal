require "./spec_helper"
require "signal"

describe Terminal do
  it "returns application after receiving stop message" do
    result = Terminal::SpecSupport::Runtime.run(width: 10, height: 4) do |builder|
      builder.text_box("demo", &.set_text("hi"))
    end

    result.app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end

  it "installs default escape handler" do
    result = Channel(Bool).new(1)

    Terminal.run(width: 10, height: 4, signals: [] of Signal, stop_message: -> { Terminal::Msg::Stop.new("spec-run") }, configure: ->(application : Terminal::TerminalApplication(Terminal::Widget)) {
      spawn do
        sleep 10.milliseconds
        application.dispatch(Terminal::Msg::KeyPress.new("escape"))
        result.send(true)
      end
    }) do |builder|
      builder.text_box("demo", &.set_text("hi"))
    end

    result.receive.should be_true
  end
end
