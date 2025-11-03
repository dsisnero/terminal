# File: src/terminal/input_raw_windows.cr
# Raw terminal input provider for Windows using Win32 Console APIs.
# Compiles only on Windows; emits InputEvent messages similar to the Unix provider.

require "time"
require "../terminal/messages"
require "./tty"
require "./windows_key_map"

module Terminal
  {% if flag?(:win32) %}
    lib WinInput
      fun _kbhit : Int32
      fun _getwch : UInt16
    end

    class RawInputProvider < InputProvider
      POLL_SLEEP = 2.milliseconds

      def initialize(@interval_ms : Int32 = 0)
      end

      def start(out_chan : Channel(Msg::Any))
        spawn do
          begin
            Terminal::TTY.with_raw_mode(STDIN) do
              read_loop(out_chan)
            end
          rescue ex
            begin
              out_chan.send(Msg::Stop.new("windows raw input error: #{ex.message}"))
            rescue
            end
          end
        end
      end

      private def read_loop(out_chan : Channel(Msg::Any))
        loop do
          ::sleep(POLL_SLEEP)
          next if WinInput._kbhit == 0

          code = WinInput._getwch
          handle_code(out_chan, code) || break
        end
      end

      private def handle_code(out_chan : Channel(Msg::Any), code : UInt16) : Bool
        case code
        when 0_u16, 0xE0_u16
          handle_extended_prefix(out_chan)
          true
        when 3_u16 # Ctrl-C
          out_chan.send(Msg::Stop.new("SIGINT"))
          false
        else
          ch = code.to_i32.chr
          out_chan.send(Msg::InputEvent.new(ch, Time::Span.zero))
          true
        end
      end

      private def handle_extended_prefix(out_chan : Channel(Msg::Any))
        return if WinInput._kbhit == 0
        extended = WinInput._getwch
        if key = Terminal::WindowsKeyMap.lookup(extended)
          out_chan.send(Msg::KeyPress.new(key))
        end
      end
    end
  {% end %}
end
