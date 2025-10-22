# File: src/terminal/spinner_widget.cr
# Simple spinner widget that animates via RenderRequest messages.
#
# Contract:
# - Callers can use EventLoop's ticker to periodically broadcast RenderRequest
# - Spinner increments frame index on each RenderRequest
# - Render returns a bordered, single-line spinner + label centered horizontally

require "../terminal/widget"
require "../terminal/cell"
require "../terminal/messages"
require "../terminal/color_dsl"

module Terminal
  class SpinnerWidget
    include Widget
    include ColorDSL

    getter id : String

    def initialize(@id : String, @label : String = "")
      @frames = ["-", "\\", "|", "/"]
      @index = 0
    end

    def handle(msg : Msg::Any)
      case msg
      when Msg::RenderRequest
        @index = (@index + 1) % @frames.size
      end
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      lines = [] of Array(Terminal::Cell)
      # one-line spinner centered horizontally
      text = "#{@frames[@index]} #{@label}"
      left_pad = {0, (width - text.size) // 2}.max
      line = [] of Cell
      (0...width).each do |i|
        ch = if i >= left_pad && i < left_pad + text.size
               text[i - left_pad]
             else
               ' '
             end
        if ch == @frames[@index]
          # Color the spinner glyph for visibility
          line << Terminal::Cell.new(ch, "cyan", "default", true, false)
        else
          line << Terminal::Cell.new(ch)
        end
      end
      lines << line
      # fill remaining lines with spaces
      (1...height).each do |_|
        lines << Array.new(width) { Terminal::Cell.new(' ') }
      end
      lines
    end
  end
end
