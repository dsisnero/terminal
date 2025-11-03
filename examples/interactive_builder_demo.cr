#!/usr/bin/env crystal

# Interactive Builder Demo
# Shows how to compose a small chat-style interface with Terminal.run.
# Features:
# - Layout built with Terminal.app + UI builder
# - TextBoxWidget log updated on each submitted message
# - InputWidget submission with Enter, `/quit`, or Esc to exit gracefully

require "atomic"
require "signal"
require "../src/terminal"

log_box = nil.as(Terminal::TextBoxWidget?)
stop_requests = Channel(Symbol).new(1)
stop_sent = Atomic(Bool).new(false)

request_stop = ->(reason : Symbol) do
  stop_sent.compare_and_set(false, true) && stop_requests.send(reason)
end

signal_cleanup = nil.as(Proc(Nil))

_app = Terminal.run(width: 80, height: 22, signals: [] of Signal, exit_key: nil, stop_message: -> { Terminal::Msg::Stop.new("interactive_builder_demo") }, configure: ->(application : Terminal::TerminalApplication(Terminal::Widget)) {
  previous = Signal.trap(Signal::INT) { request_stop.call(:signal) }
  signal_cleanup = -> { Signal.trap(Signal::INT, previous) }

  spawn do
    reason = stop_requests.receive
    log_box.try do |box|
      case reason
      when :escape
        box.add_line("System: Escape pressed, stopping...")
      when :quit
        box.add_line("System: /quit received, stopping...")
      when :signal
        box.add_line("System: Ctrl+C received, stopping...")
      end
    end
    application.dispatch(Terminal::Msg::Stop.new("interactive_builder_demo"))
  end
}) do |builder|
  builder.layout do |layout|
    layout.vertical do
      layout.widget "header", Terminal::UI::Constraint.length(3)
      layout.widget "log", Terminal::UI::Constraint.flex
      layout.widget "input", Terminal::UI::Constraint.length(3)
    end
  end

  builder.text_box "header" do |box|
    box.set_text("Interactive Builder Demo — type and press Enter (Esc or /quit to exit)")
  end

  builder.text_box "log" do |box|
    box.set_text("Welcome!\nType messages and press Enter. Use '/quit' or press Esc to exit.\n")
    box.auto_scroll = true
    log_box = box
  end

  builder.input "input" do |input|
    input.prompt("You: ")
    input.on_submit do |value|
      next if value.empty?

      if value == "/quit"
        request_stop.call(:quit)
      else
        log_box.try(&.add_line("You: #{value}"))
        log_box.try(&.add_line("System: echo -> #{value.upcase}"))
      end
      input.clear
    end
  end

  builder.on_key(:escape) { request_stop.call(:escape) }
end

signal_cleanup.try &.call

puts "\nDemo finished. Thanks for trying the interactive builder demo!"
