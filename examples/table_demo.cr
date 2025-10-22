#!/usr/bin/env crystal

# Table Widget Interactive Demo
# Features:
# - Arrow keys (up/down) to navigate rows
# - Current row highlighted with background color
# - ESC key to exit
# - Sample data with multiple rows

require "../src/terminal"

# Enhanced table widget with navigation
class NavigableTable < Terminal::TableWidget
  property current_row : Int32 = 0
  property max_rows : Int32 = 0

  def initialize(id : String)
    super(id)
  end

  def set_data(rows : Array(Hash(String, String)))
    @rows = rows
    @max_rows = rows.size
    @current_row = 0
    self
  end

  def handle(msg : Terminal::Msg::Any)
    case msg
    when Terminal::Msg::KeyPress
      handle_key(msg.key)
    end
  end

  private def handle_key(key : String)
    case key
    when "up"
      @current_row = [@current_row - 1, 0].max
    when "down"
      @current_row = [@current_row + 1, @max_rows - 1].min
    when "escape"
      restore_terminal
      puts "\nExiting table demo..."
      exit(0)
    end
  end

  # Override compose_row to highlight current row with accessible colors
  private def compose_row(row : Hash(String, String), inner_width : Int32, row_index : Int32 = -1) : Array(Terminal::Cell)
    cells = [] of Terminal::Cell
    remaining = inner_width
    is_current = (row_index == @current_row)
    # Use high contrast colors: white background with black text for selected row
    bg_color = is_current ? "white" : "default"
    text_color = is_current ? "black" : "white"

    @columns.each do |col|
      break if remaining <= 0

      raw = row[col.key]? || ""
      text = align_text_in_line(raw, col.width, col.align)
      text = text[0...{col.width, remaining}.min]
      text.each_char do |ch|
        cells << Terminal::Cell.new(ch, text_color, bg_color)
      end
      remaining -= text.size
    end
    while cells.size < inner_width
      cells << Terminal::Cell.new(' ', text_color, bg_color)
    end
    cells[0...inner_width]
  end

  # Override render to pass row index for highlighting
  def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
    grid = [] of Array(Terminal::Cell)
    # Borders: top line
    grid << border_line(width)

    inner_width = width - 2
    # Header line
    header_cells = compose_header(inner_width)
    grid << line_with_borders(header_cells)

    # Body rows (respect height - 2 border lines - 1 header)
    body_height = {0, height - 2 - 1}.max
    each_row_sorted.first(body_height).each_with_index do |row, idx|
      cells = compose_row(row, inner_width, idx)
      grid << line_with_borders(cells)
    end

    # Fill remaining lines if needed
    while grid.size < height - 1
      grid << line_with_borders(Array.new(inner_width) { Terminal::Cell.new(' ') })
    end

    # Bottom border
    grid << border_line(width)

    grid
  end
end

def clear_screen
  print "\e[2J\e[H"
end

def setup_terminal
  # Enable alternative screen buffer and hide cursor
  print "\e[?1049h" # Alternative screen buffer
  print "\e[?25l"   # Hide cursor
  STDOUT.flush
end

def restore_terminal
  # Reset all attributes and restore normal terminal
  print "\e[0m"     # Reset all attributes
  print "\e[?25h"   # Show cursor
  print "\e[?1049l" # Exit alternative screen buffer
  STDOUT.flush
end

def render_grid(grid : Array(Array(Terminal::Cell)))
  grid.each do |line|
    line.each do |cell|
      cell.to_ansi(STDOUT)
    end
    puts
  end
end

def main
  # Setup signal handlers for clean terminal restoration
  Process.on_terminate do
    restore_terminal
    puts "\nDemo interrupted. Terminal restored."
    exit(0)
  end

  Process.on_terminate do
    restore_terminal
    puts "\nDemo terminated. Terminal restored."
    exit(0)
  end

  setup_terminal
  # Sample data for the table
  sample_data = [
    {"name" => "Alice Johnson", "age" => "28", "city" => "New York", "role" => "Engineer"},
    {"name" => "Bob Smith", "age" => "35", "city" => "San Francisco", "role" => "Manager"},
    {"name" => "Carol Davis", "age" => "42", "city" => "Chicago", "role" => "Designer"},
    {"name" => "David Wilson", "age" => "31", "city" => "Boston", "role" => "Developer"},
    {"name" => "Eve Brown", "age" => "29", "city" => "Seattle", "role" => "Analyst"},
    {"name" => "Frank Miller", "age" => "38", "city" => "Denver", "role" => "Architect"},
    {"name" => "Grace Lee", "age" => "26", "city" => "Portland", "role" => "Designer"},
    {"name" => "Henry Taylor", "age" => "44", "city" => "Austin", "role" => "Manager"},
    {"name" => "Iris Chen", "age" => "33", "city" => "Miami", "role" => "Engineer"},
    {"name" => "Jack White", "age" => "27", "city" => "Phoenix", "role" => "Developer"},
  ]

  # Create the navigable table with accessible colors
  table = NavigableTable.new("employee_table")
    .col("Name", :name, 15, :left, :white) # White text for dark backgrounds
    .col("Age", :age, 5, :right, :white)   # White instead of yellow
    .col("City", :city, 12, :left, :white) # White instead of green (colorblind friendly)
    .col("Role", :role, 12, :left, :white) # White instead of magenta
    .sort_by(:name, asc: true)
    .set_data(sample_data)

  # Focus the table for navigation
  table.focus

  begin
    # Instructions
    clear_screen
    puts "╔═══════════════════════════════════════════════════════════════════╗"
    puts "║                 Accessible Interactive Table Demo                ║"
    puts "╠═══════════════════════════════════════════════════════════════════╣"
    puts "║  Navigation:                                                      ║"
    puts "║    ↑/↓ Arrow keys - Navigate up/down                             ║"
    puts "║    ESC - Exit demo                                                ║"
    puts "║                                                                   ║"
    puts "║  Accessibility Features:                                          ║"
    puts "║  • High contrast white text on dark background                   ║"
    puts "║  • Selected row: white background with black text                ║"
    puts "║  • No red/green colors (colorblind friendly)                     ║"
    puts "║  • Proper terminal state restoration on exit                     ║"
    puts "╚═══════════════════════════════════════════════════════════════════╝"
    puts
    puts "Press any key to start..."
    STDIN.raw &.read_char

    # Enable raw terminal input for arrow keys
    STDIN.raw do |input|
      loop do
        clear_screen

        # Show instructions at the top
        puts "Accessible Table Demo - Use ↑/↓ to navigate, ESC to exit"
        puts "Current row: #{table.current_row + 1}/#{table.max_rows}"
        if table.max_rows > 0
          current_person = sample_data[table.current_row]
          puts "Selected: #{current_person["name"]} (#{current_person["role"]})"
        end
        puts

        # Render the table
        grid = table.render(60, 15)
        render_grid(grid)

        puts
        puts "High contrast mode: White text on dark background"
        puts "Selected row uses white background for maximum visibility"

        # Wait for input
        case input.read_char
        when '\e'                   # Escape sequence
          if input.read_char == '[' # CSI
            case input.read_char
            when 'A' # Up arrow
              table.handle(Terminal::Msg::KeyPress.new("up"))
            when 'B' # Down arrow
              table.handle(Terminal::Msg::KeyPress.new("down"))
            end
          else
            # Just ESC key
            table.handle(Terminal::Msg::KeyPress.new("escape"))
          end
        when '\u{3}' # Ctrl+C
          restore_terminal
          puts "\nExiting..."
          break
        when 'q', 'Q' # Alternative quit
          restore_terminal
          puts "\nExiting..."
          break
        end
      end
    end
  ensure
    # Always restore terminal state
    restore_terminal
  end
end

main
