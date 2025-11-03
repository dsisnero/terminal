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
      actual_height = {height, 1}.max
      actual_width = {width, calculate_min_size.width}.max

      text = "#{@frames[@index]} #{@label}".ljust(actual_width)
      line = Array.new(actual_width) do |i|
        ch = text[i]
        if ch == @frames[@index]
          Terminal::Cell.new(ch, "cyan", "default", true, false)
        else
          Terminal::Cell.new(ch)
        end
      end

      result = [line]
      (1...actual_height).each { result << Array.new(actual_width) { Terminal::Cell.new(' ') } }
      result
    end

    # Implement required Measurable methods
    def calculate_min_size : Terminal::Geometry::Size
      min_width = 2 + Terminal::TextMeasurement.text_width(@label)
      Terminal::Geometry::Size.new(min_width, 1)
    end

    def calculate_max_size : Terminal::Geometry::Size
      # Spinner should stay compact
      max_width = 2 + Terminal::TextMeasurement.text_width(@label)
      Terminal::Geometry::Size.new([max_width, 40].min, 1) # Single line widget
    end
  end
end
