# Simple layout concepts demo
# Shows basic layout splitting without widgets

require "../src/terminal/frame"
require "../src/terminal/layout"
require "./support/block"

puts "Layout Concepts Demo"
puts "This shows how screen space can be divided into regions"
puts "Press Enter to continue..."
gets

# Create frame
frame = Terminal::Frame.new_with_terminal_size

# Example 1: Simple vertical split
puts "Example 1: Vertical Split (50/50)"
sleep 2.seconds

frame.clear_screen

layout1 = Terminal::Layout.new(
  Terminal::Direction::Vertical,
  [
    Terminal::Constraint::Percentage.new(50),
    Terminal::Constraint::Percentage.new(50),
  ]
)

areas1 = layout1.split(frame.area)

# Render colored regions
frame.render(areas1[0]) do |area, buffer|
  (0...area.height).each do |row|
    buffer << "\e[#{area.y + row + 1};#{area.x + 1}H"
    buffer << "\e[41m" # Red background
    buffer << " " * area.width
    buffer << "\e[0m"
  end

  # Add label
  buffer << "\e[#{area.y + area.height // 2 + 1};#{area.x + area.width // 2 - 3}H"
  buffer << "\e[1;37m" # Bold white
  buffer << "TOP HALF"
  buffer << "\e[0m"
end

frame.render(areas1[1]) do |area, buffer|
  (0...area.height).each do |row|
    buffer << "\e[#{area.y + row + 1};#{area.x + 1}H"
    buffer << "\e[44m" # Blue background
    buffer << " " * area.width
    buffer << "\e[0m"
  end

  # Add label
  buffer << "\e[#{area.y + area.height // 2 + 1};#{area.x + area.width // 2 - 5}H"
  buffer << "\e[1;37m" # Bold white
  buffer << "BOTTOM HALF"
  buffer << "\e[0m"
end

frame.present
sleep 3.seconds

# Example 2: Horizontal split with borders
puts "Example 2: Horizontal Split with Borders"
sleep 2.seconds

frame.clear_screen

layout2 = Terminal::Layout.new(
  Terminal::Direction::Horizontal,
  [
    Terminal::Constraint::Length.new(30), # Fixed left panel
    Terminal::Constraint::Ratio.new(1),   # Remaining space
  ]
)

areas2 = layout2.split(frame.area)

left_block = Terminal::Block.new("Menu", Terminal::BorderType::Double, "\e[32m")
right_block = Terminal::Block.new("Content", Terminal::BorderType::Rounded, "\e[35m")

# Render left panel with border
frame.render_block(areas2[0], left_block) do |inner_area, buffer|
  menu_items = ["Home", "Settings", "About", "Exit"]
  menu_items.each_with_index do |item, index|
    buffer << "\e[#{inner_area.y + index + 1};#{inner_area.x + 2}H"
    buffer << "#{index + 1}. #{item}"
  end
end

# Render right panel with border
frame.render_block(areas2[1], right_block) do |inner_area, buffer|
  content_lines = [
    "Welcome to the content area!",
    "",
    "This demonstrates how layout",
    "can create complex interfaces",
    "with multiple regions.",
    "",
    "Each region can contain:",
    "- Tables",
    "- Forms",
    "- Menus",
    "- Any custom content",
  ]

  content_lines.each_with_index do |line, index|
    break if index >= inner_area.height
    buffer << "\e[#{inner_area.y + index + 1};#{inner_area.x + 2}H"
    buffer << line
  end
end

frame.present
sleep 3.seconds

# Example 3: Complex nested layout
puts "Example 3: Nested Layout (Header/Sidebar/Content/Footer)"
sleep 2.seconds

frame.clear_screen

# Main layout: Header, Content, Footer
main_layout = Terminal::Layout.new(
  Terminal::Direction::Vertical,
  [
    Terminal::Constraint::Length.new(3), # Header
    Terminal::Constraint::Ratio.new(1),  # Content area
    Terminal::Constraint::Length.new(2), # Footer
  ]
)

main_areas = main_layout.split(frame.area)

# Content layout: Sidebar + Main content
content_layout = Terminal::Layout.new(
  Terminal::Direction::Horizontal,
  [
    Terminal::Constraint::Length.new(20), # Sidebar
    Terminal::Constraint::Ratio.new(1),   # Main content
  ]
)

content_areas = content_layout.split(main_areas[1])

# Create blocks
header_block = Terminal::Block.new("Application Header", Terminal::BorderType::Thick, "\e[33m")
sidebar_block = Terminal::Block.new("Navigation", Terminal::BorderType::Plain, "\e[36m")
main_block = Terminal::Block.new("Main Content", Terminal::BorderType::Rounded, "\e[37m")
footer_block = Terminal::Block.new("Status", Terminal::BorderType::Plain, "\e[90m")

# Render all sections
frame.render_block(main_areas[0], header_block) do |area, buffer|
  buffer << "\e[#{area.y + 1};#{area.x + 2}H"
  buffer << "\e[1mMyApp v1.0\e[0m"
end

frame.render_block(content_areas[0], sidebar_block) do |area, buffer|
  nav_items = ["Dashboard", "Users", "Reports", "Settings"]
  nav_items.each_with_index do |item, index|
    buffer << "\e[#{area.y + index + 1};#{area.x + 1}H"
    selected = index == 0 ? "\e[7m" : "" # Reverse video for first item
    buffer << "#{selected}► #{item}\e[0m"
  end
end

frame.render_block(content_areas[1], main_block) do |area, buffer|
  buffer << "\e[#{area.y + 1};#{area.x + 2}H"
  buffer << "This is where your main application"
  buffer << "\e[#{area.y + 2};#{area.x + 2}H"
  buffer << "content would be displayed."
  buffer << "\e[#{area.y + 4};#{area.x + 2}H"
  buffer << "The layout system makes it easy to"
  buffer << "\e[#{area.y + 5};#{area.x + 2}H"
  buffer << "create complex interfaces."
end

frame.render_block(main_areas[2], footer_block) do |area, buffer|
  buffer << "\e[#{area.y + 1};#{area.x + 2}H"
  buffer << "Ready | Connected | #{Time.local.to_s("%H:%M:%S")}"
end

frame.present

puts "\nLayout system ready! Press Enter to exit..."
gets
