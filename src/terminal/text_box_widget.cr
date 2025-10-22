# File: src/terminal/text_box_widget.cr
# Purpose: Multi-line text display widget with automatic content sizing and scrolling

module Terminal
  class TextBoxWidget
    include Terminal::Widget
    include Terminal::ColorDSL

    getter id : String
    property content : String
    property auto_scroll : Bool

    @fg_color : Symbol | String
    @bg_color : Symbol | String
    @bold : Bool
    @padding : Int32
    @scroll_offset : Int32

    def initialize(
      @id : String,
      @content : String = "",
      @fg_color : Symbol | String = :default,
      @bg_color : Symbol | String = :default,
      @bold : Bool = false,
      @auto_scroll : Bool = true,
      @padding : Int32 = 1
    )
      @scroll_offset = 0
    end

    def append_text(text : String)
      @content += text
      auto_scroll_to_bottom if @auto_scroll
    end

    def set_text(text : String)
      @content = text
      @scroll_offset = 0
      auto_scroll_to_bottom if @auto_scroll
    end

    # Convenient aliases for dynamic updates
    def set_content(text : String)
      set_text(text)
    end

    def append_content(text : String)
      append_text(text)
    end

    def add_line(line : String)
      @content += "\n" unless @content.empty?
      @content += line
      auto_scroll_to_bottom if @auto_scroll
    end

    def clear
      @content = ""
      @scroll_offset = 0
    end

    def handle(msg : Terminal::Msg::Any)
      case msg
      when Terminal::Msg::KeyPress
        handle_key(msg.key)
      when Terminal::Msg::Command
        case msg.name
        when "clear"
          clear
        when "scroll_up"
          scroll_up
        when "scroll_down"
          scroll_down
        end
      end
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      return create_empty_grid(width, height) if @content.empty?

      if height == 1 # Single line mode - no borders
        render_single_line(width)
      else # Normal bordered mode
        render_multi_line(width, height)
      end
    end

    def calculate_min_size : Terminal::Geometry::Size
      if @content.empty?
        return Terminal::Geometry::Size.new(5, 3) # Minimum empty box
      end

      lines = @content.lines
      max_line_width = lines.map { |line| Terminal::TextMeasurement.text_width(line) }.max? || 0
      content_height = lines.size

      # Add borders and padding
      min_width = [max_line_width + (@padding * 2) + 2, 5].max
      min_height = [content_height + (@padding * 2) + 2, 3].max

      Terminal::Geometry::Size.new(min_width, min_height)
    end

    def calculate_max_size : Terminal::Geometry::Size
      # Reasonable maximum bounds
      Terminal::Geometry::Size.new(120, 50)
    end

    private def render_single_line(width : Int32) : Array(Array(Terminal::Cell))
      # Truncate content to fit in single line
      display_text = @content.gsub(/\s+/, " ").strip
      if display_text.size > width
        display_text = display_text[0, width - 3] + "..."
      end

      cells = style(display_text.ljust(width), @fg_color, @bg_color, @bold)
      [cells[0, width]]
    end

    private def render_multi_line(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      inner_width, inner_height = inner_dimensions(width, height)
      content_lines = wrap_and_format_content(inner_width, inner_height)
      create_full_grid(width, height, content_lines)
    end

    private def wrap_and_format_content(inner_width : Int32, inner_height : Int32) : Array(Array(Terminal::Cell))
      lines = @content.lines
      wrapped_lines = [] of String

      lines.each do |line|
        if line.empty?
          wrapped_lines << ""
        else
          # Wrap long lines
          while line.size > inner_width
            wrapped_lines << line[0, inner_width]
            line = line[inner_width..]
          end
          wrapped_lines << line if line.size > 0
        end
      end

      # Apply scrolling
      visible_lines = if wrapped_lines.size > inner_height
        start_idx = [@scroll_offset, 0].max
        end_idx = [start_idx + inner_height, wrapped_lines.size].min
        wrapped_lines[start_idx, end_idx - start_idx]
      else
        wrapped_lines[0, inner_height]
      end

      # Convert to styled cells
      visible_lines.map do |line|
        padded_line = line.ljust(inner_width)
        style(padded_line, @fg_color, @bg_color, @bold)
      end
    end

    private def inner_dimensions(width : Int32, height : Int32) : {Int32, Int32}
      inner_width = [(width - 2 - (@padding * 2)), 1].max
      inner_height = [(height - 2 - (@padding * 2)), 1].max
      {inner_width, inner_height}
    end

    private def create_full_grid(width : Int32, height : Int32, content_lines : Array(Array(Terminal::Cell))) : Array(Array(Terminal::Cell))
      grid = Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } }

      # Draw borders
      draw_border(grid, width, height)

      # Draw content with padding
      content_lines.each_with_index do |line, row_idx|
        content_row = row_idx + 1 + @padding
        next if content_row >= height - 1

        line.each_with_index do |cell, col_idx|
          content_col = col_idx + 1 + @padding
          next if content_col >= width - 1
          grid[content_row][content_col] = cell
        end
      end

      grid
    end

    private def create_empty_grid(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } }
    end

    private def draw_border(grid : Array(Array(Terminal::Cell)), width : Int32, height : Int32)
      # Top and bottom borders
      (0...width).each do |col|
        grid[0][col] = Terminal::Cell.new('─')
        grid[height - 1][col] = Terminal::Cell.new('─')
      end

      # Left and right borders
      (0...height).each do |row|
        grid[row][0] = Terminal::Cell.new('│')
        grid[row][width - 1] = Terminal::Cell.new('│')
      end

      # Corners
      grid[0][0] = Terminal::Cell.new('┌')
      grid[0][width - 1] = Terminal::Cell.new('┐')
      grid[height - 1][0] = Terminal::Cell.new('└')
      grid[height - 1][width - 1] = Terminal::Cell.new('┘')
    end

    private def handle_key(key : Terminal::Key)
      case key
      when .up?
        scroll_up
      when .down?
        scroll_down
      when .page_up?
        scroll_up(10)
      when .page_down?
        scroll_down(10)
      when .home?
        @scroll_offset = 0
      when .end?
        auto_scroll_to_bottom
      end
    end

    private def scroll_up(lines : Int32 = 1)
      @scroll_offset = [@scroll_offset - lines, 0].max
    end

    private def scroll_down(lines : Int32 = 1)
      max_lines = @content.lines.size
      @scroll_offset = [@scroll_offset + lines, max_lines - 1].min
    end

    private def auto_scroll_to_bottom
      lines = @content.lines
      @scroll_offset = [lines.size - 1, 0].max
    end
  end
end