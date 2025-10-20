# File: src/terminal/screen_buffer.cr
# Purpose: Maintains a representation of the terminal's current screen contents.
# Receives Msg::ScreenUpdate, computes diffs with the previous frame, and emits Msg::ScreenDiff.
# This actor ensures backpressure safety and async processing.

require "../terminal/messages"
require "../terminal/cell"

class ScreenBuffer
  @previous : Array(Array(Cell))

  def initialize(@diff_chan : Channel(Terminal::Msg::Any))
    # store previous content as an array of arrays of Cell
    @previous = [] of Array(Cell)
  end

  def start(buffer_chan : Channel(Terminal::Msg::Any))
    spawn do
      begin
        loop do
          msg = buffer_chan.receive
          case msg
          when Terminal::Msg::ScreenUpdate
            content = normalize_content(msg.content)
            diffs = compute_diff(@previous, content)
            if diffs.size > 0
              @diff_chan.send(Terminal::Msg::ScreenDiff.new(diffs))
              @previous = content
            end
          when Terminal::Msg::Stop
            begin
              @diff_chan.send(msg)
            rescue
            end
            break
          else
            # ignore other messages
          end
        end
      rescue ex : Exception
        STDERR.puts "ScreenBuffer fatal error: #{ex.message}\n#{ex.backtrace.join("\n")}"
        begin
          @diff_chan.send(Terminal::Msg::Stop.new("screen_buffer fatal: #{ex.message}"))
        rescue
        end
      end
    end
  end

  private def normalize_content(content : Array)
    # If lines are strings, convert to arrays of Cells
    if content.size == 0
      return [] of Array(Cell)
    end

    if content.first.is_a?(String)
      content.map do |line|
        (line.as(String).chars.map { |ch| Cell.new(ch) }).to_a
      end
    elsif content.first.is_a?(Array(Cell))
      content.as(Array(Array(Cell)))
    else
      raise "ScreenUpdate content not recognized: #{content.class}"
    end
  end

  private def compute_diff(prev : Array(Array(Cell)), curr : Array(Array(Cell))) : Array(Tuple(Int32, Terminal::Msg::Payload))
    diffs = [] of Tuple(Int32, Terminal::Msg::Payload)
    max_rows = [prev.size, curr.size].max
    (0...max_rows).each do |i|
      row_prev = prev[i]? || [] of Cell
      row_curr = curr[i]? || [] of Cell
      if row_prev != row_curr
        diffs << {i, row_curr.as(Terminal::Msg::Payload)}
      end
    end
    diffs
  end
end