#!/usr/bin/env crystal

# Interactive Builder Demo
# Demonstrates an interactive chat-style interface backed by Terminal.run.
# The demo uses the runtime harness so automated tests can drive it with
# synthetic input while the CLI remains fully interactive.

require "../src/terminal"

module Examples
  module InteractiveBuilderDemo
    class Stats
      property messages : Int32
      property commands : Int32
      property last_command : String
      property started_at : Time
      property pinned_message : String?

      def initialize
        @messages = 0
        @commands = 0
        @last_command = "None"
        @started_at = Time.utc
        @pinned_message = nil
      end

      def uptime : Time::Span
        Time.utc - @started_at
      end
    end

    HELP_LINES = [
      "Available commands:",
      "  /help   - show this help",
      "  /clear  - clear the chat log",
      "  /stats  - print current statistics",
      "  /pin <msg> - pin a message in the status panel",
      "  /unpin  - clear pinned message",
      "  /quit   - exit the demo",
      "Keyboard shortcuts: F1=Help, Esc=Exit",
    ]

    private def self.format_duration(span : Time::Span) : String
      total_seconds = span.total_seconds.to_i
      minutes, seconds = total_seconds.divmod(60)
      hours, minutes = minutes.divmod(60)
      if hours > 0
        sprintf("%02d:%02d:%02d", hours, minutes, seconds)
      else
        sprintf("%02d:%02d", minutes, seconds)
      end
    end

    def self.build(builder : Terminal::UI::Builder)
      harness = builder.harness
      log_box = nil.as(Terminal::TextBoxWidget?)
      status_box = nil.as(Terminal::TextBoxWidget?)
      stats = Stats.new

      record = ->(tag : String, message : String) { harness.try &.record("#{tag}: #{message}") }

      update_status = -> do
        lines = [] of String
        lines << "Messages: #{stats.messages}"
        lines << "Commands: #{stats.commands}"
        lines << "Last command: #{stats.last_command}"
        lines << "Pinned: #{stats.pinned_message || "None"}"
        lines << "Uptime: #{format_duration(stats.uptime)}"
        lines << "Shortcuts: F1 Help | Esc Exit"
        status_box.try(&.set_text(lines.join("\n")))
      end

      log_user = ->(message : String) do
        record.call("User", message)
        log_box.try(&.add_line("You: #{message}"))
        stats.messages += 1
        update_status.call
      end

      log_system = ->(message : String) do
        record.call("System", message)
        log_box.try(&.add_line("System: #{message}"))
      end

      builder.layout do |layout|
        layout.vertical do
          layout.widget "header", Terminal::UI::Constraint.length(3)
          layout.widget "status", Terminal::UI::Constraint.length(6)
          layout.widget "log", Terminal::UI::Constraint.flex
          layout.widget "input", Terminal::UI::Constraint.length(3)
        end
      end

      builder.text_box "header" do |box|
        box.set_text("Interactive Builder Demo — type and press Enter (Esc or /quit to exit)")
        box.can_focus = false
      end

      builder.text_box "log" do |box|
        log_box = box
        initial_lines = [
          "Welcome!",
          "Type messages and press Enter. Use '/quit' or press Esc to exit.",
        ]
        box.set_text(initial_lines.join("\n"))
        box.auto_scroll = true
        box.can_focus = false
        initial_lines.each { |line| record.call("System", line) }
      end

      builder.text_box "status" do |box|
        status_box = box
        box.auto_scroll = false
        box.can_focus = false
      end

      builder.input "input" do |input|
        input.prompt("You: ")
        input.on_submit do |value|
          next if value.empty?

          trimmed = value.rstrip

          if trimmed.starts_with?("/")
            stats.commands += 1
            stats.last_command = trimmed
            record.call("User", trimmed)
            log_box.try(&.add_line("You: #{trimmed}"))

            case trimmed
            when "/help"
              HELP_LINES.each { |line| log_system.call(line) }
            when "/clear"
              log_box.try(&.clear)
              log_system.call("Log cleared.")
            when "/stats"
              log_system.call("Messages sent: #{stats.messages}, commands used: #{stats.commands}")
            when /^\/pin\s+(.+)/
              pinned = $1.strip
              stats.pinned_message = pinned
              log_system.call("Pinned message updated.")
            when "/unpin"
              stats.pinned_message = nil
              log_system.call("Pinned message cleared.")
            when "/quit"
              log_system.call("/quit received, stopping...")
              builder.request_stop(:quit)
            else
              log_system.call("Unknown command '#{trimmed}'. Type /help for options.")
            end
            update_status.call
          else
            log_user.call(trimmed)
            log_system.call("Echo -> #{trimmed.upcase}")
          end

          input.clear
        end
      end

      builder.on_key(:escape) do
        log_system.call("Escape pressed, stopping...")
        builder.request_stop(:escape)
      end

      builder.on_key(:f1) do
        HELP_LINES.each { |line| log_system.call(line) }
      end

      builder.on_stop do
        log_system.call("Application stopped.")
      end

      update_status.call
    end
  end
end

unless ENV["TERM_DEMO_SKIP_MAIN"]?
  test_mode = ENV["TERM_DEMO_TEST"]? == "1"

  harness = Terminal::RuntimeHarness::Controller.new(
    auto_dispatch: test_mode,
    stop_message: ->(reason : Symbol) { Terminal::Msg::Stop.new("interactive_builder_demo:#{reason}") }
  )

  unless test_mode
    puts "Press Enter to start the interactive builder demo..."
    STDIN.gets
  end

  app = Terminal.run(
    width: 80,
    height: 22,
    exit_key: nil,
    stop_message: -> { Terminal::Msg::Stop.new("interactive_builder_demo") },
    harness: harness
  ) do |builder|
    builder.attach_harness(harness)
    Examples::InteractiveBuilderDemo.build(builder)
  end

  reason = harness.wait_for_stop
  app.stop
  puts "\nDemo finished (reason: #{reason}). Thanks for trying the interactive builder demo!"
end
