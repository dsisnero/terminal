#!/usr/bin/env crystal

# Interactive Accessible Form Demo
# Real keyboard navigation with tab/arrow keys

require "../src/terminal"

# Setup terminal for raw input
def setup_raw_terminal
  system("stty raw -echo")
  print "\e[?1049h" # Alternative screen buffer
  print "\e[2J\e[H" # Clear screen and go to top
  print "\e[?25l"   # Hide cursor
  STDOUT.flush
end

def restore_terminal
  print "\e[0m"     # Reset attributes
  print "\e[?25h"   # Show cursor
  print "\e[?1049l" # Exit alternative screen
  system("stty sane")
  STDOUT.flush
end

# Signal handlers for clean exit
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

def display_help
  puts "╔══════════════════════════════════════════════════════════════════════╗"
  puts "║                    Interactive Accessible Form Demo                 ║"
  puts "║                                                                      ║"
  puts "║  TAB / Shift+TAB  - Navigate between form fields                    ║"
  puts "║  ENTER            - Activate dropdown / Submit form                 ║"
  puts "║  ↑↓ Arrow Keys    - Navigate dropdown options                       ║"
  puts "║  SPACE            - Toggle checkbox                                  ║"
  puts "║  ESC              - Exit demo                                        ║"
  puts "║                                                                      ║"
  puts "║  Colors: WHITE text on dark background (colorblind friendly)        ║"
  puts "╚══════════════════════════════════════════════════════════════════════╗"
  puts
end

def render_grid(grid : Array(Array(Terminal::Cell)), width : Int32, height : Int32)
  print "\e[H" # Go to top-left

  grid.each_with_index do |line, row|
    break if row >= height
    line.each_with_index do |cell, col|
      break if col >= width
      cell.to_ansi(STDOUT)
    end
    puts if line.size > 0
  end
  STDOUT.flush
end

def read_key
  char = STDIN.read_char
  return nil unless char

  if char == '\e' # Escape sequence
    char2 = STDIN.read_char
    return "escape" if char2.nil?

    if char2 == '['
      char3 = STDIN.read_char
      case char3
      when 'A' then "up"
      when 'B' then "down"
      when 'C' then "right"
      when 'D' then "left"
      when 'Z' then "shift_tab"
      else          nil
      end
    else
      "escape"
    end
  else
    case char
    when '\t'           then "tab"
    when '\r', '\n'     then "enter"
    when ' '            then "space"
    when '\u{7f}', '\b' then "backspace"
    else                     char.to_s
    end
  end
end

begin
  setup_raw_terminal
  display_help

  # Create accessible form
  form = Terminal::FormWidget.new(
    id: "demo_form",
    title: "User Registration (Press TAB to navigate)",
    submit_label: "Submit Registration"
  )

  # Add form controls
  form.add_control(Terminal::FormControl.new(
    id: "name",
    type: Terminal::FormControlType::TextInput,
    label: "Full Name:",
    required: true
  ))

  email_validator = ->(val : String) { val.includes?("@") && val.includes?(".") }
  form.add_control(Terminal::FormControl.new(
    id: "email",
    type: Terminal::FormControlType::TextInput,
    label: "Email:",
    required: true,
    validator: email_validator
  ))

  form.add_control(Terminal::FormControl.new(
    id: "country",
    type: Terminal::FormControlType::Dropdown,
    label: "Country:",
    options: ["United States", "Canada", "United Kingdom", "Germany", "France"],
    value: "United States"
  ))

  form.add_control(Terminal::FormControl.new(
    id: "newsletter",
    type: Terminal::FormControlType::Checkbox,
    label: "Subscribe to newsletter",
    value: "false"
  ))

  form.on_submit do |data|
    restore_terminal
    puts "\n═══ FORM SUBMITTED SUCCESSFULLY ═══"
    data.each do |key, value|
      puts "#{key}: #{value}"
    end
    puts "\nDemo completed!"
    exit(0)
  end

  submitted = false

  loop do
    # Render form - it will use optimal size internally
    grid = form.render(70, 25)  # Widget will use optimal size internally
    render_grid(grid, 70, 25)

    # Show current status
    print "\e[26;1H" # Move to bottom area
    puts "Current field: #{form.focused_index} | ESC to exit | TAB to navigate"
    STDOUT.flush

    # Handle input
    key = read_key
    next unless key

    case key
    when "escape"
      break
    when "tab"
      form.handle(Terminal::Msg::KeyPress.new("tab"))
    when "shift_tab"
      # Shift+Tab for reverse navigation
      form.handle(Terminal::Msg::KeyPress.new("shift+tab"))
    when "enter"
      form.handle(Terminal::Msg::KeyPress.new("enter"))
    when "space"
      form.handle(Terminal::Msg::KeyPress.new("space"))
    when "up"
      form.handle(Terminal::Msg::KeyPress.new("up"))
    when "down"
      form.handle(Terminal::Msg::KeyPress.new("down"))
    when "backspace"
      form.handle(Terminal::Msg::KeyPress.new("backspace"))
    else
      if key.is_a?(String) && key.size == 1
        form.handle(Terminal::Msg::InputEvent.new(key[0], Time::Span::ZERO))
      end
    end
  end
ensure
  restore_terminal
  puts "\nDemo exited. Terminal restored."
end
