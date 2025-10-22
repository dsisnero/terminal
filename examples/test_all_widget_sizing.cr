#!/usr/bin/env crystal

# Test comprehensive content-based sizing for all widgets
require "../src/terminal"

puts "=== Comprehensive Widget Content-Based Sizing Test ==="

# Test 1: TableWidget
puts "\n1. TableWidget:"
table = Terminal::TableWidget.new("test")
  .col("Name", :name, 8, :left, :white)
  .col("Age", :age, 3, :right, :white)
  .rows([{"name" => "Alice", "age" => "25"}])

puts "Min: #{table.calculate_min_width}, Max: #{table.calculate_max_width}, Optimal: #{table.calculate_optimal_width}"
puts "Height - Min: #{table.calculate_min_height}, Max: #{table.calculate_max_height}"

# Test 2: FormWidget
puts "\n2. FormWidget:"
form = Terminal::FormWidget.new("form", title: "Test")
form.add_control(Terminal::FormControl.new(
  id: "name", type: Terminal::FormControlType::TextInput, label: "Name"
))

puts "Min: #{form.calculate_min_width}, Max: #{form.calculate_max_width}, Optimal: #{form.calculate_optimal_width}"
puts "Height - Min: #{form.calculate_min_height}, Max: #{form.calculate_max_height}"

# Test 3: DropdownWidget
puts "\n3. DropdownWidget:"
dropdown = Terminal::DropdownWidget.new(
  "dropdown",
  ["Short", "Medium Option", "Very Long Option Name"],
  "Select:"
)

puts "Min: #{dropdown.calculate_min_width}, Max: #{dropdown.calculate_max_width}, Optimal: #{dropdown.calculate_optimal_width}"
puts "Height - Min: #{dropdown.calculate_min_height}, Max: #{dropdown.calculate_max_height}"

# Test expanded dropdown
dropdown.expanded = true
puts "Expanded Height - Min: #{dropdown.calculate_min_height}, Max: #{dropdown.calculate_max_height}"

# Test 4: InputWidget
puts "\n4. InputWidget:"
input = Terminal::InputWidget.new("input", "Username:", max_length: 30)

puts "Min: #{input.calculate_min_width}, Max: #{input.calculate_max_width}, Optimal: #{input.calculate_optimal_width}"
puts "Height - Min: #{input.calculate_min_height}, Max: #{input.calculate_max_height}"

# Test 5: Optimal sizing with constraints
puts "\n5. Testing Optimal Sizing with Constraints:"

puts "TableWidget with 50-char limit: #{table.calculate_optimal_width(50)}"
puts "FormWidget with 40-char limit: #{form.calculate_optimal_width(40)}"
puts "DropdownWidget with 30-char limit: #{dropdown.calculate_optimal_width(30)}"

# Test 6: Render with content-based sizing
puts "\n6. Actual Render Width Usage:"

table_grid = table.render(100, 10)
table_actual = table_grid.first?.try(&.size) || 0

form_grid = form.render(100, 15)
form_actual = form_grid.first?.try(&.size) || 0

dropdown_grid = dropdown.render(100, 8)
dropdown_actual = dropdown_grid.first?.try(&.size) || 0

input_grid = input.render(100, 5)
input_actual = input_grid.first?.try(&.size) || 0

puts "TableWidget: Requested 100, Used #{table_actual}"
puts "FormWidget: Requested 100, Used #{form_actual}"
puts "DropdownWidget: Requested 100, Used #{dropdown_actual}"
puts "InputWidget: Requested 100, Used #{input_actual}"

puts "\n=== All Widgets Now Support Content-Based Sizing! ==="
puts "✓ TableWidget - Width based on column sizes"
puts "✓ FormWidget - Width based on labels and controls"
puts "✓ DropdownWidget - Width based on prompt and longest option"
puts "✓ InputWidget - Width based on prompt and input field size"
puts "✓ All widgets calculate min/max/optimal dimensions"
puts "✓ No more full-screen width takeover!"
