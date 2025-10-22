# File: src/terminal/input_provider.cr
# Purpose: Define InputProvider interface and concrete providers (Console and Dummy).
# ConsoleInputProvider uses line-based reads here; for production replace with
# a platform-specific raw-mode implementation (termios on Unix, Win32 Console on Windows).

require "time"
require "io"
require "socket"
require "../terminal/messages"

module Terminal
  # Abstract InputProvider: implementations must spawn a fiber and write Msg::InputEvent | Msg::Stop into out_chan
  abstract class InputProvider
    abstract def start(out_chan : Channel(Msg::Any))

    # Returns a reasonable default provider for the platform
    def self.default
      {% if flag?(:win32) %}
        RawInputProvider.new
      {% else %}
        RawInputProvider.new
      {% end %}
    rescue
      # Fallback to console provider if raw is unavailable
      ConsoleInputProvider.new
    end
  end

  # ConsoleInputProvider: reads lines from STDIN and emits characters as InputEvent.
  # This is a simple implementation for tests; replace with a raw-mode implementation for production.
  class ConsoleInputProvider < InputProvider
    def initialize
    end

    def start(out_chan : Channel(Msg::Any))
      # Non-blocking placeholder implementation for tests.
      # Replace with a proper raw-mode reader using termios/WinAPI for real applications.
      spawn do
        begin
          out_chan.send(Msg::Stop.new("console input not implemented"))
        rescue
        end
      end
    end
  end

  # DummyInputProvider: emits a predefined string at a given interval (ms)
  class DummyInputProvider < InputProvider
    def initialize(@seq : String = "", @interval_ms : Int32 = 100)
    end

    def start(out_chan : Channel(Msg::Any))
      spawn do
        begin
          @seq.each_char do |ch|
            out_chan.send(Msg::InputEvent.new(ch, Time::Span.zero))
            sleep(Time::Span.new(nanoseconds: @interval_ms * 1_000_000))
          end
          # Give time for rendering before stopping
          sleep(Time::Span.new(nanoseconds: @interval_ms * 2_000_000))
          out_chan.send(Msg::Stop.new("dummy finished"))
        rescue ex : Exception
          begin
            out_chan.send(Msg::Stop.new("DummyInputProvider error: #{ex.message}"))
          rescue
          end
        end
      end
    end
  end
end

# Load platform-specific raw providers after base class is defined
require "./input_raw_unix"
require "./input_raw_windows"
