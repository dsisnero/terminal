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
require "./tty"

module Terminal
  {% unless flag?(:win32) %}
    class RawInputProvider < InputProvider
      DEFAULT_POLL_INTERVAL = 2.milliseconds

      def initialize(interval_ms : Int32 = 0)
        @poll_interval = interval_ms > 0 ? interval_ms.milliseconds : DEFAULT_POLL_INTERVAL
      end

      def start(out_chan : Channel(Msg::Any))
        spawn do
          begin
            Terminal::TTY.with_raw_mode(STDIN, non_blocking: true) do
              read_loop(out_chan)
            end
          rescue ex : Exception
            begin
              out_chan.send(Msg::Stop.new("raw input error: #{ex.message}"))
            rescue
            end
          end
        end
      end

      # Minimal non-blocking read loop. For simplicity, this treats any non-bracketed
      # bytes as individual InputEvent chars. More sophisticated key parsing can be
      # added later (arrows, function keys, UTF-8 multi-byte handling, etc.).
      private def read_loop(out_chan : Channel(Msg::Any))
        buf = Bytes.new(1024)
        paste_mode = false
        paste_buf = String.new
        loop do
          ::sleep(@poll_interval)
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
