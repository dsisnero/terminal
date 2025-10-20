# File: src/terminal/diff_renderer.cr
# Purpose: Consumes Msg::ScreenDiff and Msg::Stop, applies ANSI sequences and cursor control
# to render changes to the output IO (which can be real STDOUT or injected IO for tests).
#
# The DiffRenderer runs in its own fiber and listens on a diff channel. It applies cursor moves,
# writes changed lines efficiently, and supports optional double-buffered or atomic flush modes.

require "../terminal/messages"
require "../terminal/cell"

class DiffRenderer
  getter io : IO
  getter cursor_chan : Channel(Terminal::Msg::Any)?  # optional, may be nil

  def initialize(@io : IO, @cursor_chan : Channel(Terminal::Msg::Any)? = nil)
  end

  def start(diff_chan : Channel(Terminal::Msg::Any))
    spawn do
      begin
        loop do
          msg = diff_chan.receive
          case msg
          when Terminal::Msg::ScreenDiff
            render_diff(msg)
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
      when Array(Cell)
        cells.each { |cell| cell.to_ansi(@io) }
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
    @io.print "\e[0m\e[?25h" # reset attributes and show cursor
    @io.flush
  end
end