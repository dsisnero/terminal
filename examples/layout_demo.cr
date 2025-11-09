# Multi-panel layout demo
# Shows multiple widgets in different screen regions simultaneously

require "../src/terminal/frame"
require "../src/terminal/layout"
require "../src/terminal/table_widget"
require "../src/terminal/form_widget"

# Create some sample data
table_data = [
  ["Name", "Age", "City"],
  ["Alice", "25", "NYC"],
  ["Bob", "30", "LA"],
  ["Carol", "28", "Chicago"],
]

form_controls = [
  Terminal::FormControl.text_input("name", "Name:", ""),
  Terminal::FormControl.text_input("email", "Email:", ""),
  Terminal::FormControl.dropdown("role", "Role:", ["Admin", "User", "Guest"]),
]

# Create widgets
table = Terminal::TableWidget.new(table_data)
form = Terminal::FormWidget.new("User Registration", form_controls)

# Create frame
frame = Terminal::Frame.new_with_terminal_size

puts "Multi-Panel Layout Demo"
puts "Press Enter to continue..."
gets

# Main layout: split screen vertically
main_layout = Terminal::Layout.new(
  Terminal::Direction::Vertical,
  [
    Terminal::Constraint::Length.new(1), # Header
    Terminal::Constraint::Ratio.new(1),  # Content area
    Terminal::Constraint::Length.new(3), # Footer
  ]
)

# Content layout: split horizontally
content_layout = Terminal::Layout.new(
  Terminal::Direction::Horizontal,
  [
    Terminal::Constraint::Percentage.new(60), # Table area
    Terminal::Constraint::Percentage.new(40), # Form area
  ]
)

frame.clear_screen

# Split main areas
main_areas = main_layout.split(frame.area)
header_area = main_areas[0]
content_area = main_areas[1]
footer_area = main_areas[2]

# Split content area
content_areas = content_layout.split(content_area)
table_area = content_areas[0]
form_area = content_areas[1]

# Render header
frame.render(header_area) do |area, buffer|
  buffer << "\e[#{area.y + 1};#{area.x + 1}H"
  buffer << "\e[1;33m" # Bold yellow
  title = "Multi-Panel Terminal Application"
  padding = (area.width - title.size) // 2
  buffer << " " * padding + title
  buffer << "\e[0m"
end

# Render table with border
frame.render_block(table_area, table_block) do |inner_area, _|
  frame.render_widget(inner_area, table)
end

# Render form with border
frame.render_block(form_area, form_block) do |inner_area, _|
  frame.render_widget(inner_area, form)
end

# Render footer
frame.render(footer_area) do |area, buffer|
  buffer << "\e[#{area.y + 1};#{area.x + 1}H"
  buffer << "\e[36m" # Cyan
  buffer << "Navigation: Tab/Shift+Tab between panels | Arrow keys within panels | ESC to exit"
  buffer << "\e[0m"

  buffer << "\e[#{area.y + 2};#{area.x + 1}H"
  buffer << "\e[90m" # Gray
  buffer << "Status: Table (#{table_data.size - 1} rows) | Form (#{form_controls.size} fields)"
  buffer << "\e[0m"
end

frame.present

puts "\nPress Enter to exit..."
gets
