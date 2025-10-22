# Frame for managing terminal rendering surface
# Inspired by Ratatui's Frame component

require "./layout"
require "./block"

module Terminal
  # Terminal frame for coordinated rendering
  class Frame
    getter width : Int32
    getter height : Int32
    getter buffer : IO::Memory

    def initialize(@width : Int32 = 80, @height : Int32 = 24)
      @buffer = IO::Memory.new
      clear_screen
    end

    # Get the full terminal area
    def area : Rect
      Rect.new(0, 0, @width, @height)
    end

    # Clear the screen and reset cursor
    def clear_screen
      @buffer.clear
      @buffer << "\e[2J\e[H" # Clear screen and move to top-left
    end

    # Render content to a specific area
    def render(area : Rect, & : Rect, IO::Memory ->)
      yield area, @buffer
    end

    # Render a block (bordered panel) in an area
    def render_block(area : Rect, block : Block, & : Rect, IO::Memory ->)
      inner_area = block.render(area, @buffer)
      yield inner_area, @buffer
    end

    # Render a widget in an area
    def render_widget(area : Rect, widget : Widget)
      # Move to area position
      @buffer << "\e[#{area.y + 1};#{area.x + 1}H"

      # Get widget content
      widget_buffer = IO::Memory.new
      widget.render(area.width, area.height, widget_buffer)

      # Split widget content into lines and position each
      content = widget_buffer.to_s
      lines = content.split('\n')

      lines.each_with_index do |line, index|
        break if index >= area.height
        @buffer << "\e[#{area.y + index + 1};#{area.x + 1}H"

        # Truncate line if too long
        if line.size > area.width
          @buffer << line[0...area.width]
        else
          @buffer << line
        end
      end
    end

    # Present the frame to terminal
    def present
      print @buffer.to_s
      @buffer.clear
    end

    # Get terminal dimensions
    def self.terminal_size : {Int32, Int32}
      # Try to get actual terminal size
      if ENV.has_key?("COLUMNS") && ENV.has_key?("LINES")
        width = ENV["COLUMNS"]?.try(&.to_i?) || 80
        height = ENV["LINES"]?.try(&.to_i?) || 24
        {width, height}
      else
        # Default fallback
        {80, 24}
      end
    end

    # Create frame with actual terminal size
    def self.new_with_terminal_size
      width, height = terminal_size
      new(width, height)
    end
  end
end
