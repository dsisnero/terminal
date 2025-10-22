# File: src/terminal/input_raw_windows.cr
# Raw terminal input provider for Windows using Win32 Console APIs.
# Guarded to only compile on Windows. Currently a minimal stub that enables
# VT input mode and immediately emits Stop. Full key parsing is TODO.

require "../terminal/messages"

module Terminal
  {% if flag?(:win32) %}
    lib Win
      alias HANDLE = Void*
      alias DWORD = UInt32
      alias BOOL = Int32

      fun GetStdHandle(nStdHandle : DWORD) : HANDLE
      fun GetConsoleMode(hConsoleHandle : HANDLE, lpMode : DWORD*) : BOOL
      fun SetConsoleMode(hConsoleHandle : HANDLE, dwMode : DWORD) : BOOL

      STD_INPUT_HANDLE              = 0xFFFFFFF6_u32
      ENABLE_VIRTUAL_TERMINAL_INPUT =     0x0200_u32
      ENABLE_PROCESSED_INPUT        =     0x0001_u32
    end

    class RawInputProvider < InputProvider
      def start(out_chan : Channel(Msg::Any))
        spawn do
          begin
            h = Win.GetStdHandle(Win::STD_INPUT_HANDLE)
            mode = uninitialized Win::DWORD
            Win.GetConsoleMode(h, pointerof(mode))
            # enable VT input
            Win.SetConsoleMode(h, mode | Win::ENABLE_VIRTUAL_TERMINAL_INPUT | Win::ENABLE_PROCESSED_INPUT)
            # Minimal stub: Windows full input parsing not implemented yet
            out_chan.send(Msg::Stop.new("windows raw input not yet implemented"))
          rescue ex
            begin
              out_chan.send(Msg::Stop.new("windows raw input error: #{ex.message}"))
            rescue
            end
          end
        end
      end
    end
  {% end %}
end
