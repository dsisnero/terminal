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
      fun GetKeyState(vKey : Int32) : Int16

      VK_SHIFT   = 0x10
      VK_CONTROL = 0x11
      VK_MENU    = 0x12
    end

    class RawInputProvider < InputProvider
      DEFAULT_POLL_INTERVAL = 2.milliseconds

      def initialize(interval_ms : Int32 = 0)
        @poll_interval = interval_ms > 0 ? interval_ms.milliseconds : DEFAULT_POLL_INTERVAL
        @pending_surrogate = nil
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
          ::sleep(@poll_interval)
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
          if ch = decode_code_unit(code)
            emit_character(out_chan, ch)
          end
          true
        end
      end

      private def handle_extended_prefix(out_chan : Channel(Msg::Any))
        return if WinInput._kbhit == 0
        extended = WinInput._getwch
        if key = Terminal::WindowsKeyMap.lookup_with_modifiers(extended, current_modifiers)
          out_chan.send(Msg::KeyPress.new(key))
        end
      end

      private def decode_code_unit(code : UInt16) : Char?
        if high_surrogate?(code)
          @pending_surrogate = code
          nil
        elsif low_surrogate?(code) && (pending = @pending_surrogate)
          pair = StaticArray(UInt16, 2).new { |i| i == 0 ? pending : code }
          @pending_surrogate = nil
          String.from_utf16(pair.to_slice)[0]
        else
          @pending_surrogate = nil
          code.to_i32.chr
        end
      rescue ArgumentError
        nil
      end

      private def high_surrogate?(code : UInt16) : Bool
        0xD800_u16 <= code && code <= 0xDBFF_u16
      end

      private def low_surrogate?(code : UInt16) : Bool
        0xDC00_u16 <= code && code <= 0xDFFF_u16
      end

      private def emit_character(out_chan : Channel(Msg::Any), ch : Char)
        modifiers = current_modifiers
        out_chan.send(Msg::InputEvent.new(ch, Time::Span.zero))
        unless modifiers.empty?
          combo = Terminal::WindowsKeyMap.combine(ch.to_s, modifiers)
          out_chan.send(Msg::KeyPress.new(combo))
        end
      end

      private def current_modifiers : Array(String)
        modifiers = [] of String
        modifiers << "ctrl" if key_down?(WinInput::VK_CONTROL)
        modifiers << "alt" if key_down?(WinInput::VK_MENU)
        modifiers << "shift" if key_down?(WinInput::VK_SHIFT)
        modifiers
      end

      private def key_down?(vk : Int32) : Bool
        (WinInput.GetKeyState(vk) & 0x8000) != 0
      end
    end
  {% end %}
end
