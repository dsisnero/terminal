# File: src/terminal/input_provider.cr
# Purpose: Define InputProvider interface and concrete providers (Console and Dummy).
# - ConsoleInputProvider reads bytes from STDIN (uses termios/RawTerminal externally provided)
#   and emits Msg::InputEvent and Msg::Stop to a system channel.
# - DummyInputProvider emits a deterministic sequence (useful for tests).

require "time"
require "io"
require "socket"
require "../terminal/messages"

module InputProvider
  # Start must spawn a fiber and write Msg::InputEvent | Msg::Stop into out_chan
  abstract def start(out_chan : Channel(Terminal::Msg::Any))
end

# ConsoleInputProvider: synchronous blocking reads inside its own fiber.
# NOTE: This implementation assumes raw mode is set externally (RawTerminal.with_raw_mode)
# so we can simply call STDIN.getc in a fiber. For production use, integrate termios FFI.
class ConsoleInputProvider
  include InputProvider

  def initialize
    # placeholder for any config in future
  end

  def start(out_chan : Channel(Terminal::Msg::Any))
    spawn do
      begin
        loop do
          val = STDIN.getc
          if val == nil
            out_chan.send(Terminal::Msg::Stop.new("stdin closed"))
            break
          end

          b = val.to_u8
          # Control keys handling (simple): Ctrl-C (3) -> Stop
          if b == 3_u8
            out_chan.send(Terminal::Msg::Stop.new("ctrl-c"))
            break
          else
            ch = b.to_char
            out_chan.send(Terminal::Msg::InputEvent.new(ch, Time::Span.new(nanoseconds: 0)))
          end
        end
      rescue ex : Exception
        begin
          out_chan.send(Terminal::Msg::Stop.new("ConsoleInputProvider error: #{ex.message}"))
        rescue
          # avoid raising from rescue
        end
      end
    end
  end
end

# DummyInputProvider: emits a predefined string at a given interval (ms)
class DummyInputProvider
  include InputProvider

  def initialize(@seq : String = "", @interval_ms : Int32 = 100)
  end

  def start(out_chan : Channel(Terminal::Msg::Any))
    spawn do
      begin
        @seq.each_char do |ch|
          sleep(Time::Span.new(seconds: 0, nanoseconds: @interval_ms * 1_000_000))
          out_chan.send(Terminal::Msg::InputEvent.new(ch, Time::Span.new(nanoseconds: 0)))
        end
        out_chan.send(Terminal::Msg::Stop.new("dummy finished"))
      rescue ex : Exception
        begin
          out_chan.send(Terminal::Msg::Stop.new("DummyInputProvider error: #{ex.message}"))
        rescue
        end
      end
    end
  end
end