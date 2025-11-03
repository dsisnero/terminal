require "../terminal/color_dsl"

# File: src/terminal/widget.cr
# Common widget interface and rendering helpers.
#
# Implementations should:
# - Provide an id, handle(Msg::Any), and render(width,height)
# - Avoid side effects outside their owned state
# - Use helpers for wrapping, alignment, borders, and cell composition

module Terminal
  # Common widget interface and rendering helpers.
  module Widget
    include ::Terminal::ColorDSL

    abstract def id : String
    abstract def handle(msg : Terminal::Msg::Any)
    abstract def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))

    # Navigation properties - widgets can override these
    property focused : Bool = false
    property can_focus : Bool = true

    # Common navigation handling - widgets can call this or override
    def handle_navigation(msg : Terminal::Msg::Any) : Bool
      case msg
      when Terminal::Msg::KeyPress
        case msg.key
        when "up"
          handle_up_key
          return true
        when "down"
          handle_down_key
          return true
        when "left"
          handle_left_key
          return true
        when "right"
          handle_right_key
          return true
        when "tab"
          handle_tab_key
          return true
        when "enter"
          handle_enter_key
          return true
        when "escape"
          handle_escape_key
          return true
        end
      end
      false # Not handled
    end

    # Override these methods in widgets to provide navigation behavior
    def handle_up_key; end

    def handle_down_key; end

    def handle_left_key; end

    def handle_right_key; end

    def handle_tab_key; end

    def handle_enter_key; end

    def handle_escape_key; end

    # Focus management
    def focus
      @focused = true
    end

    def blur
      @focused = false
    end

    # Split content into fixed-width lines (character wrap) and pad each to inner_width
    protected def wrap_content(content : String, inner_width : Int32) : Array(String)
      lines = [] of String
      pos = 0
      while pos < content.size
        end_pos = {pos + inner_width, content.size}.min
        chunk = content[pos...end_pos].ljust(inner_width)
        lines << chunk
        pos += inner_width
      end
      lines
    end

    # Word-wrap content: try to keep words together when possible
    protected def wrap_words(content : String, inner_width : Int32, inner_height : Int32 = 0) : Array(String)
      return [] of String if inner_width <= 0
      return wrap_content(content, inner_width) if inner_width <= 1

      words = content.split(/(\s+)/) # keep whitespace as separate tokens
      lines = [] of String
      current = ""

      words.each do |word|
        next if word.empty?

        # If word is too long, force-split it
        if word.size > inner_width
          # Push current line if not empty
          lines << current.ljust(inner_width) if !current.empty?
          # Split long word into chunks
          pos = 0
          while pos < word.size
            chunk = word[pos...{pos + inner_width, word.size}.min]
            lines << chunk.ljust(inner_width)
            pos += inner_width
            break if inner_height > 0 && lines.size >= inner_height
          end
          current = ""
        else
          # Normal word processing
          if current.size + word.size <= inner_width
            current += word
          else
            lines << current.ljust(inner_width)
            current = word.strip
          end
        end

        break if inner_height > 0 && lines.size >= inner_height
      end

      # Add final line if needed and we have space
      lines << current.ljust(inner_width) if !current.empty? && (inner_height == 0 || lines.size < inner_height)

      # Ensure we don't exceed inner_height if specified
      lines = lines[0...inner_height] if inner_height > 0 && lines.size > inner_height
      lines
    end

    # Truncate string to width, append ellipsis if truncated
    protected def truncate_with_ellipsis(s : String, width : Int32) : String
      return s if s.size <= width
      return s[0...width] if width <= 3
      s[0...(width - 3)] + "..."
    end

    # Align text in a single line: :left, :right, :center
    protected def align_text_in_line(text : String, inner_width : Int32, align : Symbol = :left) : String
      case align
      when :left
        text.ljust(inner_width)
      when :right
        text.rjust(inner_width)
      when :center
        center_text_in_line(text, inner_width)
      else
        text.ljust(inner_width)
      end
    end

    # Convenience: create a full widget grid from a list of content lines (unpadded)
    protected def create_full_grid(width : Int32, height : Int32, content_lines : Array(String)) : Array(Array(Terminal::Cell))
      inner_width, inner_height = inner_dimensions(width, height)
      # prepare padded content lines up to inner_height
      padded = [] of String
      inner_height.times do |i|
        line = content_lines[i]? || ""
        padded << line.ljust(inner_width)
      end
      create_bordered_grid(width, height, padded)
    end

    # Create a bordered grid with the given content lines (content_lines are already padded)
    protected def create_bordered_grid(width : Int32, height : Int32, content_lines : Array(String)) : Array(Array(Terminal::Cell))
      inner_width = width - 2 # Account for borders
      lines = [] of Array(Terminal::Cell)

      height.times do |row|
        line = [] of Cell
        width.times do |col|
          char = if row == 0 || row == height - 1
                   '-' # Top/bottom border
                 elsif col == 0 || col == width - 1
                   '|' # Left/right border
                 elsif row - 1 < content_lines.size && col - 1 < inner_width
                   content_lines[row - 1][col - 1]
                 else
                   ' ' # Empty space
                 end
          line << Terminal::Cell.new(char)
        end
        lines << line
      end
      lines
    end

    protected def build_bordered_cell_grid(width : Int32, height : Int32, padding : Int32, content_lines : Array(Array(Terminal::Cell))) : Array(Array(Terminal::Cell))
      return Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } } if width <= 0 || height <= 0

      grid = Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } }
      draw_border!(grid)

      max_row = height - 1 - padding
      max_col = width - 1 - padding

      content_lines.each_with_index do |line, row_idx|
        target_row = 1 + padding + row_idx
        break if target_row > max_row

        line.each_with_index do |cell, col_idx|
          target_col = 1 + padding + col_idx
          break if target_col > max_col
          grid[target_row][target_col] = cell
        end
      end

      grid
    end

    protected def draw_border!(grid : Array(Array(Terminal::Cell)))
      height = grid.size
      width = grid.first?.try(&.size) || 0
      return if width <= 0 || height <= 0

      top = grid.first
      bottom = grid.last
      width.times do |col|
        char = (col.zero? || col == width - 1) ? '┌' : '─'
        top[col] = Terminal::Cell.new(char)
        char = (col.zero? || col == width - 1) ? '└' : '─'
        bottom[col] = Terminal::Cell.new(char)
      end

      (1...(height - 1)).each do |row|
        grid[row][0] = Terminal::Cell.new('│')
        grid[row][width - 1] = Terminal::Cell.new('│')
      end

      if width >= 2 && height >= 2
        grid[0][0] = Terminal::Cell.new('┌')
        grid[0][width - 1] = Terminal::Cell.new('┐')
        grid[height - 1][0] = Terminal::Cell.new('└')
        grid[height - 1][width - 1] = Terminal::Cell.new('┘')
      end
    end

    # Calculate minimum width needed for content - widgets should override this
    def calculate_min_width : Int32
      # Default implementation - widgets should provide their own
      20 # Reasonable default minimum width
    end

    # Calculate maximum reasonable width - widgets should override this
    def calculate_max_width : Int32
      # Default implementation - widgets should provide their own
      80 # Reasonable default maximum width
    end

    # Calculate optimal width within constraints - can be overridden
    def calculate_optimal_width(available_width : Int32? = nil) : Int32
      min_w = calculate_min_width
      max_w = calculate_max_width

      if available_width
        # Use available width but stay within min/max bounds
        {min_w, {available_width, max_w}.min}.max
      else
        # No constraint - use minimum needed
        min_w
      end
    end

    # Calculate minimum height needed for content - widgets should override this
    def calculate_min_height : Int32
      # Default implementation - widgets should provide their own
      3 # Reasonable default minimum height (border + content)
    end

    # Calculate maximum reasonable height - widgets should override this
    def calculate_max_height : Int32
      # Default implementation - widgets should provide their own
      20 # Reasonable default maximum height
    end

    # Calculate optimal height within constraints - can be overridden
    def calculate_optimal_height(available_height : Int32? = nil) : Int32
      min_h = calculate_min_height
      max_h = calculate_max_height

      if available_height
        # Use available height but stay within min/max bounds
        {min_h, {available_height, max_h}.min}.max
      else
        # No constraint - use minimum needed
        min_h
      end
    end

    # Convenience method: get optimal dimensions for content-based sizing
    def calculate_optimal_size(available_width : Int32? = nil, available_height : Int32? = nil) : {Int32, Int32}
      width = calculate_optimal_width(available_width)
      height = calculate_optimal_height(available_height)
      {width, height}
    end

    # Helper: calculate text width (useful for widgets with text content)
    protected def text_width(text : String) : Int32
      text.size
    end

    # Helper: calculate width needed for a list of strings (useful for dropdowns, lists)
    protected def max_text_width(strings : Array(String)) : Int32
      return 0 if strings.empty?
      strings.max_of(&.size)
    end

    # Helper: calculate width needed for label + content (useful for forms, inputs)
    protected def label_content_width(label : String, content_width : Int32) : Int32
      label.size + content_width + 2 # label + ": " + content
    end

    # Return inner width and height accounting for borders
    protected def inner_dimensions(width : Int32, height : Int32) : {Int32, Int32}
      {width - 2, height - 2}
    end

    # Utility: pad a string to a given width
    protected def pad_string(s : String, width : Int32) : String
      s.ljust(width)
    end

    # Utility: create an empty content grid of given inner dimensions
    protected def create_empty_content(inner_width : Int32, inner_height : Int32) : Array(String)
      ([] of String).tap do |lines|
        inner_height.times { lines << "".ljust(inner_width) }
      end
    end

    # Utility: center text in a line of inner_width
    protected def center_text_in_line(text : String, inner_width : Int32) : String
      return text.ljust(inner_width) if text.size >= inner_width
      left = ((inner_width - text.size) / 2).to_i
      right = inner_width - text.size - left
      (" " * left) + text + (" " * right)
    end
  end
end
