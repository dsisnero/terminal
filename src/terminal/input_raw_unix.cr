# File: src/terminal/input_raw_unix.cr
# Raw terminal input provider for Unix-like systems using termios.
# - Sets stdin to raw, non-blocking mode
# - Emits InputEvent for most characters
# - Detects bracketed paste (ESC[200~ ... ESC[201~) and emits PasteEvent with full content
# - Restores terminal mode on stop to avoid leaving the tty in raw mode

# # no external C require needed; we use LibC
require "io"
require "time"
require "base64"
require "../terminal/messages"

module Terminal
  {% unless flag?(:win32) %}
    class RawInputProvider < InputProvider
      FD_STDIN   =      0
      TCSANOW    =      0
      F_SETFL    =      4
      O_NONBLOCK = 0x0004

      def initialize(@interval_ms : Int32 = 0)
        @orig = uninitialized LibC::Termios
        @raw = uninitialized LibC::Termios
      end

      def start(out_chan : Channel(Msg::Any))
        spawn do
          begin
            setup_raw
            read_loop(out_chan)
          rescue ex : Exception
            begin
              out_chan.send(Msg::Stop.new("raw input error: #{ex.message}"))
            rescue
            end
          ensure
            restore
          end
        end
      end

      # Put tty in raw mode and non-blocking read
      private def setup_raw
        # get and save original
        LibC.tcgetattr(FD_STDIN, pointerof(@orig))
        @raw = @orig
        LibC.cfmakeraw(pointerof(@raw))
        LibC.tcsetattr(FD_STDIN, TCSANOW, pointerof(@raw))
        # set non-blocking
        LibC.fcntl(FD_STDIN, F_SETFL, O_NONBLOCK)
      end

      # Restore saved tty mode
      private def restore
        LibC.tcsetattr(FD_STDIN, TCSANOW, pointerof(@orig))
      end

      # Minimal non-blocking read loop. For simplicity, this treats any non-bracketed
      # bytes as individual InputEvent chars. More sophisticated key parsing can be
      # added later (arrows, function keys, UTF-8 multi-byte handling, etc.).
      private def read_loop(out_chan : Channel(Msg::Any))
        buf = Bytes.new(1024)
        paste_mode = false
        paste_buf = String.new
        loop do
          # small sleep to avoid spinning
          ::sleep(Time::Span.new(nanoseconds: 2_000_000))
          n = STDIN.read(buf)
          if n > 0
            data = String.new(buf[0, n])
            i = 0
            while i < data.bytesize
              if !paste_mode && data.byte_at?(i) == 0x1B # ESC
                # look ahead for bracketed paste start "[200~"
                if data.size >= i + 6 && data[i, 6] == "\e[200~"
                  paste_mode = true
                  i += 6
                  next
                end
              end
              if paste_mode
                if data.size >= i + 6 && data[i, 6] == "\e[201~"
                  # end paste
                  out_chan.send(Msg::PasteEvent.new(paste_buf))
                  paste_buf = String.new
                  paste_mode = false
                  i += 6
                  next
                else
                  paste_buf += data.byte_at(i).unsafe_chr
                  i += 1
                end
              else
                ch = data.byte_at(i).unsafe_chr
                out_chan.send(Msg::InputEvent.new(ch, Time::Span.zero))
                i += 1
              end
            end
          end
        end
      end
    end
  {% end %}
end
