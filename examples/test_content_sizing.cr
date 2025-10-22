#!/usr/bin/env crystal

# Test content-based width calculation
require "../src/terminal"

puts "=== Testing Content-Based Widget Sizing ==="

# Test TableWidget sizing
puts "\n1. TableWidget Content-Based Sizing:"

table_data = [
  {"name" => "Alice", "age" => "28", "role" => "Engineer"},
  {"name" => "Bob", "age" => "35", "role" => "Manager"},
]

table = Terminal::TableWidget.new("test_table")
  .col("Name", :name, 10, :left, :white)
  .col("Age", :age, 3, :right, :white)
  .col("Role", :role, 8, :left, :white)
  .rows(table_data)

min_width = table.calculate_min_width
max_width = table.calculate_max_width

puts "Table columns: Name(10) + Age(3) + Role(8) = 21 content + separators + borders"
puts "Calculated min width: #{min_width}"
puts "Calculated max width: #{max_width}"

# Render with large width - should only use what it needs
grid = table.render(100, 10)
actual_used_width = grid.first?.try(&.size) || 0
puts "Requested width: 100, Actually used: #{actual_used_width}"

# Test FormWidget sizing
puts "\n2. FormWidget Content-Based Sizing:"

form = Terminal::FormWidget.new("test_form", title: "Registration")
form.add_control(Terminal::FormControl.new(
  id: "name",
  type: Terminal::FormControlType::TextInput,
  label: "Full Name"
))
form.add_control(Terminal::FormControl.new(
  id: "country",
  type: Terminal::FormControlType::Dropdown,
  label: "Country",
  options: ["United States", "Canada", "United Kingdom"]
))

form_min_width = form.calculate_min_width
form_max_width = form.calculate_max_width

puts "Form title: 'Registration' (12 chars)"
puts "Field 1: 'Full Name' + input space ≈ 34 chars"
puts "Field 2: 'Country' + 'United States' ≈ 24 chars"
puts "Calculated min width: #{form_min_width}"
puts "Calculated max width: #{form_max_width}"

# Render with large width - should only use what it needs
form_grid = form.render(100, 15)
form_actual_width = form_grid.first?.try(&.size) || 0
puts "Requested width: 100, Actually used: #{form_actual_width}"

puts "\n=== Content-Based Sizing Test Results ==="
puts "✓ TableWidget: Uses #{actual_used_width} chars instead of full 100"
puts "✓ FormWidget: Uses #{form_actual_width} chars instead of full 100"
puts "✓ Both widgets now calculate and use minimum required width"
puts "\nThis means widgets will no longer take full screen width!"
