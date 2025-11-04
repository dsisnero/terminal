# File: src/terminal/diff_renderer.cr
# Purpose: Consumes Msg::ScreenDiff and Msg::Stop, applies ANSI sequences and cursor control
# to render changes to the output IO (which can be real STDOUT or injected IO for tests).
#
# Notes:
# - Supports optional bracketed paste enable/disable for better paste handling.
# - Handles Msg::CopyToClipboard by emitting OSC 52 copy sequences.
# - Runs in its own fiber; on fatal exceptions, attempts to signal Stop upstream.

require "../terminal/messages"
require "../terminal/cell"

module Terminal
  class DiffRenderer
    getter io : IO
    getter cursor_chan : Channel(Terminal::Msg::Any)? # optional, may be nil

    def initialize(@io : IO, @cursor_chan : Channel(Terminal::Msg::Any)? = nil, @enable_bracketed_paste : Bool = false, @use_alternate_screen : Bool = true)
    end

    def start(diff_chan : Channel(Terminal::Msg::Any))
      spawn do
        begin
          if @enable_bracketed_paste
            enable_bracketed_paste
          end
          enter_alternate_screen if @use_alternate_screen
          loop do
            msg = diff_chan.receive
            case msg
            when Terminal::Msg::ScreenDiff
              render_diff(msg)
            when Terminal::Msg::CopyToClipboard
              copy_to_clipboard(msg.text)
            when Terminal::Msg::Stop
              finalize
              break
            else
              # ignore
            end
          end
        rescue ex : Exception
          STDERR.puts "DiffRenderer fatal: #{ex.message}\n#{ex.backtrace.join("\n")}"
          begin
            @cursor_chan.try &.send(Terminal::Msg::Stop.new("diff_renderer fatal: #{ex.message}"))
          rescue
          end
        end
      end
    end

    private def render_diff(msg : Terminal::Msg::ScreenDiff)
      msg.changes.each do |(row, cells)|
        move_cursor(row, 0)
        case cells
        when Array(Terminal::Cell)
          cells.each(&.to_ansi(@io))
        when String
          @io.print cells
        else
          @io.print cells.to_s
        end
        @io.print "\e[0m" # reset style at end of line
        @io.print "\r\n"
      end
      @io.flush
    end

    private def move_cursor(row : Int32, col : Int32)
      @io.print "\e[#{row + 1};#{col + 1}H"
    end

    def finalize
      # disable bracketed paste on shutdown if we enabled it
      if @enable_bracketed_paste
        disable_bracketed_paste
      end
      exit_alternate_screen if @use_alternate_screen
      @io.print "\e[0m\e[?25h" # reset attributes and show cursor
      @io.flush
    end

    private def enter_alternate_screen
      @io.print "\e[?1049h\e[H"
      @io.flush
    end

    private def exit_alternate_screen
      @io.print "\e[?1049l"
      @io.flush
    end

    private def enable_bracketed_paste
      @io.print "\e[?2004h"
      @io.flush
    end

    private def disable_bracketed_paste
      @io.print "\e[?2004l"
      @io.flush
    end

    private def copy_to_clipboard(text : String)
      # OSC 52 clipboard copy: ESC ] 52 ; c ; base64 ST
      b64 = Base64.strict_encode(text)
      @io.print "\e]52;c;#{b64}\a"
      @io.flush
    end
  end
end
