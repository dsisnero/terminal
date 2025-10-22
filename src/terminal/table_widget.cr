# File: src/terminal/table_widget.cr
# A simple, styled table widget with columns, borders, colors, and sort arrows.
#
# DSL:
#   Terminal::TableWidget.new("t")
#     .col("Name", :name, 12, :left, :cyan)
#     .col("Age",  :age,   5, :right)
#     .sort_by(:age, asc: true)
#     .rows([{"name" => "Alice", "age" => "30"}])
#
# Notes:
# - Fits headers/rows within inner width and truncates with padding
# - Sorted column shows ▲/▼ depending on asc flag

require "../terminal/widget"
require "../terminal/cell"
require "../terminal/messages"

module Terminal
  class TableWidget
    include Widget

    struct Column
      getter label : String
      getter key : String
      getter width : Int32
      getter align : Symbol
      getter fg : String

      def initialize(@label : String, key : String | Symbol, @width : Int32, @align : Symbol = :left, fg : Symbol | String = :default)
        @key = key.to_s
        @fg = fg.is_a?(Symbol) ? (ColorDSL::COLOR_NAMES[fg]? || fg.to_s) : fg
      end
    end

    getter id : String
    property current_row : Int32 = 0

    @columns = [] of Column
    @rows = [] of Hash(String, String)
    @border : Symbol = :thin
    @sort_key : String? = nil
    @sort_asc : Bool = true

    def initialize(@id : String)
      @can_focus = true
    end

    def col(label : String, key : String | Symbol, width : Int32, align : Symbol = :left, fg : Symbol | String = :default) : self
      @columns << Column.new(label, key, width, align, fg)
      self
    end

    def rows(data : Array(Hash(String, String))) : self
      @rows = data
      @current_row = 0 if @current_row >= data.size
      self
    end

    # Calculate minimum width needed for the table based on column widths
    def calculate_min_width : Int32
      return 2 if @columns.empty? # Just borders

      # Sum column widths + separators + borders
      content_width = @columns.sum(&.width)
      separators = [@columns.size - 1, 0].max # spaces between columns
      border_width = 2                        # left and right borders

      content_width + separators + border_width
    end

    # Calculate maximum reasonable width - for tables, this is usually the min width
    # unless columns need to expand to fit content better
    def calculate_max_width : Int32
      # For now, tables use fixed column widths so max = min
      # Could be enhanced later to allow column expansion
      calculate_min_width
    end

    # Calculate minimum height needed for table content
    def calculate_min_height : Int32
      return 3 if @rows.empty? # Header + borders minimum

      # Header + borders + at least one data row
      header_lines = 1
      border_lines = 2                 # top and bottom
      data_lines = [@rows.size, 1].min # At least show one row if data exists

      header_lines + border_lines + data_lines
    end

    # Calculate maximum reasonable height for table
    def calculate_max_height : Int32
      return calculate_min_height if @rows.empty?

      # Header + borders + all data rows (but cap at reasonable size)
      header_lines = 1
      border_lines = 2
      all_data_lines = @rows.size

      # Cap at 25 rows to prevent huge tables
      {header_lines + border_lines + all_data_lines, 25}.min
    end

    # Calculate minimum height needed for the table
    def calculate_min_height : Int32
      return 3 if @rows.empty? # Header + borders

      header_height = 1
      data_height = @rows.size
      border_height = 2 # top and bottom borders

      header_height + data_height + border_height
    end

    def border(style : Symbol) : self
      @border = style
      self
    end

    def sort_by(key : String | Symbol, asc : Bool = true) : self
      @sort_key = key.to_s
      @sort_asc = asc
      self
    end

    def handle(msg : Terminal::Msg::Any)
      # Try common navigation first
      return if handle_navigation(msg)

      # Handle table-specific messages here if needed
    end

    # Override navigation methods for table-specific behavior
    def handle_up_key
      @current_row = [@current_row - 1, 0].max if @rows.size > 0
    end

    def handle_down_key
      @current_row = [@current_row + 1, [@rows.size - 1, 0].max].min if @rows.size > 0
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      # Use content-based width - only take what we need
      min_width = calculate_min_width
      actual_width = min_width # Always use minimum needed width

      grid = [] of Array(Terminal::Cell)
      # Borders: top line
      grid << border_line(actual_width)

      inner_width = actual_width - 2
      # Header line
      header_cells = compose_header(inner_width)
      grid << line_with_borders(header_cells)

      # Body rows (respect height - 2 border lines - 1 header)
      body_height = {0, height - 2 - 1}.max
      each_row_sorted.first(body_height).each_with_index do |row, idx|
        cells = compose_row(row, inner_width, idx) # Pass index for highlighting
        grid << line_with_borders(cells)
      end

      # Fill remaining lines if needed
      while grid.size < height - 1
        grid << line_with_borders(Array.new(inner_width) { Terminal::Cell.new(' ') })
      end

      # Bottom border
      grid << border_line(actual_width)

      grid
    end

    private def each_row_sorted
      arr = @rows.dup
      if key = @sort_key
        arr.sort! do |a, b|
          va = a[key]? || ""
          vb = b[key]? || ""
          if @sort_asc
            va <=> vb
          else
            vb <=> va
          end
        end
      end
      arr
    end

    private def compose_header(inner_width : Int32) : Array(Terminal::Cell)
      cells = [] of Terminal::Cell
      remaining = inner_width

      @columns.each_with_index do |col, idx|
        break if remaining <= 0

        # Add separator before column (except first)
        if idx > 0 && remaining > 0
          cells << Terminal::Cell.new(' ')
          remaining -= 1
        end

        break if remaining <= 0

        # Calculate actual width for this column
        actual_width = {col.width, remaining}.min

        label = col.label
        # Add sort arrow if this is sorted column
        if @sort_key && @sort_key == col.key
          arrow = @sort_asc ? "▲" : "▼"
          # Fit arrow within column width
          if label.size + 2 <= actual_width
            label = "#{label} #{arrow}"
          else
            label = truncate_with_ellipsis(label, {actual_width - 2, 0}.max) + " #{arrow}"
          end
        end

        # Ensure exactly actual_width characters
        text = if label.size > actual_width
                 truncate_with_ellipsis(label, actual_width)
               else
                 case col.align
                 when :right
                   label.rjust(actual_width)
                 when :center
                   label.center(actual_width)
                 else # :left
                   label.ljust(actual_width)
                 end
               end

        # Add characters to cells
        text.each_char do |ch|
          cells << Terminal::Cell.new(ch, col.fg)
        end
        remaining -= actual_width
      end

      # pad remaining space
      while cells.size < inner_width
        cells << Terminal::Cell.new(' ')
      end
      cells[0...inner_width]
    end

    private def compose_row(row : Hash(String, String), inner_width : Int32, row_index : Int32 = -1) : Array(Terminal::Cell)
      cells = [] of Terminal::Cell
      remaining = inner_width

      # Determine if this row should be highlighted
      is_current = @focused && (row_index == @current_row)
      bg_color = is_current ? "white" : "default"
      text_color = is_current ? "black" : "white"

      @columns.each_with_index do |col, idx|
        break if remaining <= 0

        # Add separator before column (except first)
        if idx > 0 && remaining > 0
          cells << Terminal::Cell.new(' ', text_color, bg_color)
          remaining -= 1
        end

        break if remaining <= 0

        # Calculate actual width for this column
        actual_width = {col.width, remaining}.min

        raw = row[col.key]? || ""

        # Ensure exactly actual_width characters
        text = if raw.size > actual_width
                 truncate_with_ellipsis(raw, actual_width)
               else
                 case col.align
                 when :right
                   raw.rjust(actual_width)
                 when :center
                   raw.center(actual_width)
                 else # :left
                   raw.ljust(actual_width)
                 end
               end

        # Add characters to cells with highlighting colors
        text.each_char do |ch|
          cells << Terminal::Cell.new(ch, text_color, bg_color)
        end
        remaining -= actual_width
      end

      # pad remaining space
      while cells.size < inner_width
        cells << Terminal::Cell.new(' ', text_color, bg_color)
      end
      cells[0...inner_width]
    end

    private def border_line(width : Int32) : Array(Terminal::Cell)
      Array.new(width) { Terminal::Cell.new('-') }
    end

    private def line_with_borders(inner_cells : Array(Terminal::Cell)) : Array(Terminal::Cell)
      [Terminal::Cell.new('|')] + inner_cells + [Terminal::Cell.new('|')]
    end
  end
end
