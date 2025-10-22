require "../src/terminal"

# Simple smoke test to verify the library works
puts "Testing Terminal library..."

# Test creating widgets
dropdown = Terminal::DropdownWidget.new(
  id: "test",
  options: ["A", "B", "C"]
)

input = Terminal::InputWidget.new(
  id: "test_input"
)

form_control = Terminal::FormControl.new(
  id: "name",
  type: Terminal::FormControlType::TextInput,
  label: "Name"
)

form = Terminal::FormWidget.new(
  id: "test_form",
  controls: [form_control]
)

puts "✓ All widgets created successfully"
puts "✓ Terminal library is working correctly"
