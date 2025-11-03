# File: src/terminal/text_box_widget.cr
# Purpose: Multi-line text display widget with automatic content sizing and scrolling

module Terminal
  class TextBoxWidget
    include Terminal::Widget
    include Terminal::ColorDSL

    getter id : String
    property content : String
    property auto_scroll : Bool
    getter scroll_offset : Int32

    @fg_color : Symbol | String
    @bg_color : Symbol | String
    @bold : Bool
    @padding : Int32
    @scroll_offset : Int32
    @last_inner_width : Int32
    @last_inner_height : Int32
    @last_wrapped_lines : Int32
    @pending_auto_scroll : Bool

    def initialize(
      @id : String,
      @content : String = "",
      @fg_color : Symbol | String = :default,
      @bg_color : Symbol | String = :default,
      @bold : Bool = false,
      @auto_scroll : Bool = true,
      @padding : Int32 = 1,
    )
      @scroll_offset = 0
      @last_inner_width = 0
      @last_inner_height = 0
      @last_wrapped_lines = 0
      @pending_auto_scroll = false
    end

    def append_text(text : String)
      @content += text
      if @auto_scroll
        @pending_auto_scroll = true
        clamp_scroll_offset
      end
    end

    def set_text(text : String)
      @content = text
      @scroll_offset = 0
      if @auto_scroll
        @pending_auto_scroll = true
        clamp_scroll_offset
      end
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
      if @auto_scroll
        @pending_auto_scroll = true
        clamp_scroll_offset
      end
    end

    def clear
      @content = ""
      @scroll_offset = 0
      @pending_auto_scroll = false
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
      max_line_width = lines.max_of? { |line| Terminal::TextMeasurement.text_width(line) } || 0
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
      width = [width, 1].max
      # Truncate content to fit in single line
      display_text = @content.gsub(/\s+/, " ").strip
      if display_text.size > width
        display_text = if width > 3
                         display_text[0, width - 3] + "..."
                       else
                         display_text[0, width]
                       end
      end

      cells = style(display_text.ljust(width), @fg_color, @bg_color, @bold)
      @last_inner_width = width
      @last_inner_height = 1
      @last_wrapped_lines = 1
      @pending_auto_scroll = false if @scroll_offset <= 0
      [cells[0, width]]
    end

    private def render_multi_line(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      inner_width, inner_height = inner_dimensions(width, height)
      wrapped_lines = wrap_content_lines(inner_width)
      @last_inner_width = inner_width
      @last_inner_height = inner_height
      @last_wrapped_lines = wrapped_lines.size

      max_offset = current_max_scroll_offset

      if @pending_auto_scroll
        @scroll_offset = max_offset
        @pending_auto_scroll = false
      end

      @scroll_offset = {@scroll_offset, 0}.max
      @scroll_offset = {@scroll_offset, max_offset}.min

      visible_strings = select_visible_lines(wrapped_lines, inner_height)
      content_lines = visible_strings.map do |line|
        style(line.ljust(inner_width), @fg_color, @bg_color, @bold)
      end

      while content_lines.size < inner_height
        content_lines << style("".ljust(inner_width), @fg_color, @bg_color, @bold)
      end

      create_full_grid(width, height, content_lines)
    end

    private def wrap_content_lines(inner_width : Int32) : Array(String)
      inner_width = [inner_width, 1].max
      lines = @content.lines
      wrapped_lines = [] of String

      lines.each do |line|
        if line.empty?
          wrapped_lines << ""
        else
          # Wrap long lines
          slice = line.dup
          while slice.size > inner_width
            wrapped_lines << slice[0, inner_width]
            slice = slice[inner_width..]
          end
          wrapped_lines << slice if slice.size > 0
        end
      end

      wrapped_lines = [""] if wrapped_lines.empty?
      wrapped_lines
    end

    private def select_visible_lines(wrapped_lines : Array(String), inner_height : Int32) : Array(String)
      return [] of String if inner_height <= 0
      max_offset = [wrapped_lines.size - inner_height, 0].max
      offset = {@scroll_offset, 0}.max
      offset = {offset, max_offset}.min
      visible = wrapped_lines[offset, inner_height] || [] of String
      visible
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

    private def handle_key(key : String)
      case key
      when "up"
        scroll_up
      when "down"
        scroll_down
      when "page_up"
        scroll_up(10)
      when "page_down"
        scroll_down(10)
      when "home"
        @scroll_offset = 0
        @pending_auto_scroll = false
      when "end"
        auto_scroll_to_bottom
      end
      clamp_scroll_offset
    end

    private def scroll_up(lines : Int32 = 1)
      @scroll_offset = [@scroll_offset - lines, 0].max
      @pending_auto_scroll = false
    end

    private def scroll_down(lines : Int32 = 1)
      @scroll_offset += lines
      @pending_auto_scroll = false
      clamp_scroll_offset
    end

    private def auto_scroll_to_bottom
      @pending_auto_scroll = true
      clamp_scroll_offset
    end

    private def current_max_scroll_offset : Int32
      return 0 if @last_inner_height <= 0
      max_offset = @last_wrapped_lines - @last_inner_height
      max_offset = 0 if max_offset < 0
      max_offset
    end

    private def clamp_scroll_offset
      max_offset = current_max_scroll_offset
      @scroll_offset = [@scroll_offset, 0].max
      @scroll_offset = {@scroll_offset, max_offset}.min
    end
  end
end
