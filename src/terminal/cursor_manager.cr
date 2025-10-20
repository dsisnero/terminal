# File: src/terminal/cursor_manager.cr
# Purpose: Manages cursor visibility, position, and emits ANSI sequences for control.
# It listens to cursor-related messages from a channel and writes to injected IO.
# This component ensures consistent cursor handling and graceful restoration on Stop.

require "../terminal/messages"

class CursorManager
  def initialize(@io : IO)
    @visible = true
    @row = 0
    @col = 0
  end

  def start(cursor_chan : Channel(Terminal::Msg::Any))
    spawn do
      begin
        loop do
          msg = cursor_chan.receive
          case msg
          when Terminal::Msg::CursorHide
            hide
          when Terminal::Msg::CursorShow
            show
          when Terminal::Msg::CursorMove
            move_to(msg.row, msg.col)
          when Terminal::Msg::Stop
            restore
            break
          else
            # ignore
          end
        end
      rescue ex : Exception
        STDERR.puts "CursorManager fatal: #{ex.message}\n#{ex.backtrace.join("\n")}"
        restore
      end
    end
  end

  private def hide
    return unless @visible
    @io.print "\e[?25l"
    @io.flush
    @visible = false
  end

  private def show
    return if @visible
    @io.print "\e[?25h"
    @io.flush
    @visible = true
  end

  private def move_to(row : Int32, col : Int32)
    @row = row
    @col = col
    @io.print "\e[#{row + 1};#{col + 1}H"
    @io.flush
  end

  private def restore
    show if !@visible
    @io.print "\e[0m"
    @io.flush
  end
end