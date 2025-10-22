# File: examples/form_demo.cr
# Purpose: Demonstration of dropdown, input, and form widgets

require "../src/terminal"

# Example 1: Simple Dropdown
def dropdown_example
  puts "\n=== Dropdown Widget Example ==="
  puts "Use arrows to navigate, Enter to select, Escape to close"

  dropdown = Terminal::DropdownWidget.new(
    id: "color_picker",
    options: ["Red", "Green", "Blue", "Yellow", "Purple"],
    prompt: "Choose a color:"
  )

  dropdown.on_select do |color|
    puts "\nYou selected: #{color}"
  end

  # Simulate user interaction (in real use, would be driven by event loop)
  dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand
  dropdown.handle(Terminal::Msg::KeyPress.new("down"))  # Navigate to Green
  dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Select

  # Render final state
  grid = dropdown.render(40, 8)
  render_grid(grid)
end

# Example 2: Input Widget with Styling
def input_example
  puts "\n=== Input Widget Example ==="
  puts "Type text, use arrows to move cursor, Enter to submit"

  input = Terminal::InputWidget.new(
    id: "username_input",
    prompt: "Username: ",
    prompt_bg: "default", # Use default background for better contrast
    input_bg: "default",  # Default background works better on dark terminals
    max_length: 20
  )

  # Track final value only (reduce noise)
  final_value = ""
  input.on_change do |value|
    final_value = value
  end

  input.on_submit do |value|
    puts "\n✓ Submitted: #{value}"
  end

  # Simulate user typing
  puts "Simulating user typing 'JohnDoe'..."
  "JohnDoe".each_char do |ch|
    input.handle(Terminal::Msg::InputEvent.new(ch, Time::Span::ZERO))
  end

  puts "Final input value: #{final_value}"

  # Render
  puts "\nRendered widget:"
  grid = input.render(40, 1)
  render_grid(grid)
end

# Example 3: Complete Form with Multiple Controls
def form_example
  puts "\n=== Form Widget Example ==="
  puts "Tab to navigate, Space/Enter to interact, arrows for dropdowns"

  form = Terminal::FormWidget.new(
    id: "registration_form",
    title: "User Registration",
    submit_label: "Register"
  )

  # Add text input
  form.add_control(Terminal::FormControl.new(
    id: "full_name",
    type: Terminal::FormControlType::TextInput,
    label: "Full Name",
    required: true
  ))

  # Add email with validation
  email_validator = ->(val : String) {
    val.includes?("@") && val.includes?(".")
  }
  form.add_control(Terminal::FormControl.new(
    id: "email",
    type: Terminal::FormControlType::TextInput,
    label: "Email Address",
    required: true,
    validator: email_validator
  ))

  # Add country dropdown
  form.add_control(Terminal::FormControl.new(
    id: "country",
    type: Terminal::FormControlType::Dropdown,
    label: "Country",
    options: ["USA", "Canada", "UK", "Germany", "France", "Japan"],
    value: "USA"
  ))

  # Add interests checkboxes (simulated as separate controls)
  form.add_control(Terminal::FormControl.new(
    id: "newsletter",
    type: Terminal::FormControlType::Checkbox,
    label: "Subscribe to newsletter",
    value: "false"
  ))

  # Set up form submission handler
  form.on_submit do |data|
    puts "\n=== Form Submitted ==="
    data.each do |key, value|
      puts "#{key}: #{value}"
    end
  end

  # Simulate user filling out form
  puts "\nSimulating form completion..."
  puts "1. Entering name: 'John Smith'"

  # Type name
  "John Smith".each_char do |ch|
    form.handle(Terminal::Msg::InputEvent.new(ch, Time::Span::ZERO))
  end

  # Move to email field
  puts "2. Moving to email field, entering: 'john@example.com'"
  form.handle(Terminal::Msg::KeyPress.new("tab"))
  "john@example.com".each_char do |ch|
    form.handle(Terminal::Msg::InputEvent.new(ch, Time::Span::ZERO))
  end

  # Move to country dropdown
  puts "3. Selecting country: 'Canada'"
  form.handle(Terminal::Msg::KeyPress.new("tab"))
  form.handle(Terminal::Msg::KeyPress.new("enter")) # Expand
  form.handle(Terminal::Msg::KeyPress.new("down"))  # Select Canada
  form.handle(Terminal::Msg::KeyPress.new("enter")) # Confirm

  # Move to checkbox
  puts "4. Checking newsletter subscription"
  form.handle(Terminal::Msg::KeyPress.new("tab"))
  form.handle(Terminal::Msg::KeyPress.new("space")) # Check

  # Move to submit and submit
  puts "5. Moving to submit button"
  form.handle(Terminal::Msg::KeyPress.new("tab"))

  # Render form
  puts "\nCompleted form:"
  grid = form.render(60, 25)
  render_grid(grid)

  # Submit
  puts "\n6. Submitting form..."
  form.handle(Terminal::Msg::KeyPress.new("enter"))
end

# Example 4: Form with Validation Errors
def validation_example
  puts "\n=== Form Validation Example ==="

  form = Terminal::FormWidget.new(
    id: "login_form",
    title: "Login"
  )

  # Required field
  form.add_control(Terminal::FormControl.new(
    id: "username",
    type: Terminal::FormControlType::TextInput,
    label: "Username",
    required: true
  ))

  # Password with minimum length validation
  password_validator = ->(val : String) { val.size >= 6 }
  form.add_control(Terminal::FormControl.new(
    id: "password",
    type: Terminal::FormControlType::TextInput,
    label: "Password",
    required: true,
    validator: password_validator
  ))

  form.on_submit do |data|
    puts "\n✓ Login successful!"
    puts "Username: #{data["username"]}"
  end

  # Try to submit with empty fields (will fail)
  puts "\nAttempting to submit empty form (should fail)..."
  form.focused_index = 2 # Focus submit button
  form.handle(Terminal::Msg::KeyPress.new("enter"))

  # Render to show validation errors
  grid = form.render(50, 20)
  render_grid(grid)

  puts "\nNow filling with valid data..."
  puts "Username: 'alice', Password: 'secret123'"
  form.focused_index = 0
  "alice".each_char { |ch| form.handle(Terminal::Msg::InputEvent.new(ch, Time::Span::ZERO)) }

  form.handle(Terminal::Msg::KeyPress.new("tab"))
  "secret123".each_char { |ch| form.handle(Terminal::Msg::InputEvent.new(ch, Time::Span::ZERO)) }

  form.handle(Terminal::Msg::KeyPress.new("tab"))
  puts "Submitting valid form..."
  form.handle(Terminal::Msg::KeyPress.new("enter"))
end

# Example 5: Dropdown with Filtering
def dropdown_filter_example
  puts "\n=== Dropdown with Filtering Example ==="

  countries = [
    "United States", "United Kingdom", "Canada", "Mexico",
    "Germany", "France", "Spain", "Italy",
    "Japan", "China", "India", "Australia",
  ]

  dropdown = Terminal::DropdownWidget.new(
    id: "country_select",
    options: countries,
    prompt: "Select country:"
  )

  dropdown.on_select do |country|
    puts "\nSelected country: #{country}"
  end

  # Expand and filter by typing
  dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand

  # Type "uni" to filter
  dropdown.handle(Terminal::Msg::InputEvent.new('u', Time::Span::ZERO))
  dropdown.handle(Terminal::Msg::InputEvent.new('n', Time::Span::ZERO))
  dropdown.handle(Terminal::Msg::InputEvent.new('i', Time::Span::ZERO))

  puts "\nFiltering by 'uni' (should show United States, United Kingdom)..."
  grid = dropdown.render(50, 15)
  render_grid(grid)

  # Select first filtered result
  dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
end

# Helper to render a grid to the console
def render_grid(grid : Array(Array(Terminal::Cell)))
  grid.each do |line|
    line.each do |cell|
      cell.to_ansi(STDOUT)
    end
    puts
  end
end

# Add visual separators
def print_separator
  puts "\n" + "─" * 60
end

# Run all examples
puts "╔════════════════════════════════════════════════════════════╗"
puts "║         Terminal Form Widgets Demo                        ║"
puts "║    Showcasing dropdowns, inputs, forms & validation       ║"
puts "╚════════════════════════════════════════════════════════════╝"

dropdown_example
print_separator

input_example
print_separator

form_example
print_separator

validation_example
print_separator

dropdown_filter_example

puts "\n╔════════════════════════════════════════════════════════════╗"
puts "║                    ✓ All examples completed!               ║"
puts "╚════════════════════════════════════════════════════════════╝"
