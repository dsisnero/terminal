#!/usr/bin/env crystal

# Simple Accessible Table Demo - Uses Built-in Navigation
require "../src/terminal"

def setup_terminal
  print "\e[?1049h" # Alternative screen buffer
  print "\e[?25l"   # Hide cursor
  STDOUT.flush
end

def restore_terminal
  print "\e[0m"     # Reset attributes
  print "\e[?25h"   # Show cursor
  print "\e[?1049l" # Exit alternative screen
  STDOUT.flush
end

def clear_screen
  print "\e[2J\e[H"
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
  # Setup signal handlers
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

  begin
    # Sample data
    sample_data = [
      {"name" => "Alice Johnson", "age" => "28", "city" => "New York", "role" => "Engineer"},
      {"name" => "Bob Smith", "age" => "35", "city" => "San Francisco", "role" => "Manager"},
      {"name" => "Carol Davis", "age" => "42", "city" => "Chicago", "role" => "Designer"},
      {"name" => "David Wilson", "age" => "31", "city" => "Boston", "role" => "Developer"},
      {"name" => "Eve Brown", "age" => "29", "city" => "Seattle", "role" => "Analyst"},
    ]

    # Create simple accessible table using built-in functionality
    table = Terminal::TableWidget.new("accessible_table")
      .col("Name", :name, 15, :left, :white)
      .col("Age", :age, 5, :right, :white)
      .col("City", :city, 12, :left, :white)
      .col("Role", :role, 12, :left, :white)
      .sort_by(:name, asc: true)
      .rows(sample_data)

    # Focus the table to enable navigation and highlighting
    table.focus

    # Instructions
    clear_screen
    puts "╔═══════════════════════════════════════════════════════════════════╗"
    puts "║                    Accessible Table Demo                         ║"
    puts "║                   (Using Built-in Navigation)                    ║"
    puts "╠═══════════════════════════════════════════════════════════════════╣"
    puts "║  Navigation:                                                      ║"
    puts "║    ↑/↓ Arrow keys - Navigate up/down                             ║"
    puts "║    ESC or Q - Exit demo                                           ║"
    puts "║                                                                   ║"
    puts "║  Accessibility Features:                                          ║"
    puts "║  • High contrast white text on dark background                   ║"
    puts "║  • Selected row: white background with black text                ║"
    puts "║  • No red/green colors (colorblind friendly)                     ║"
    puts "║  • Auto-sized to content (not full screen)                       ║"
    puts "║  • Proper terminal state restoration on exit                     ║"
    puts "╚═══════════════════════════════════════════════════════════════════╝"
    puts
    puts "Press any key to start..."
    STDIN.raw &.read_char

    # Main interaction loop
    STDIN.raw do |input|
      loop do
        clear_screen

        # Show instructions
        puts "Accessible Table Demo - Use ↑/↓ to navigate, ESC/Q to exit"
        puts "Current row: #{table.current_row + 1}/#{sample_data.size}"
        if table.current_row < sample_data.size
          current_person = sample_data[table.current_row]
          puts "Selected: #{current_person["name"]} (#{current_person["role"]})"
        end
        puts
        puts "Table width: #{table.calculate_min_width} characters (content-based sizing)"
        puts

        # Render the table - it will auto-size itself
        grid = table.render(100, 15)  # Widget will use optimal size internally
        render_grid(grid)

        puts
        puts "✓ White text for high contrast on dark backgrounds"
        puts "✓ Selected row highlighted with white background"
        puts "✓ Arrow key navigation built into TableWidget"

        # Handle input
        case char = input.read_char
        when '\e' # Escape sequence
          next_char = input.read_char
          if next_char == '[' # CSI
            arrow_char = input.read_char
            case arrow_char
            when 'A' # Up arrow
              table.handle(Terminal::Msg::KeyPress.new("up"))
            when 'B' # Down arrow
              table.handle(Terminal::Msg::KeyPress.new("down"))
            end
          else
            # Just ESC key
            break
          end
        when '\u{3}', 'q', 'Q' # Ctrl+C or Q
          break
        when Nil
          # EOF or other issue
          break
        end
      end
    end
  ensure
    restore_terminal
    puts "\nExiting table demo..."
  end
end

main
