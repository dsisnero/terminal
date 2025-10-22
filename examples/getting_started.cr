#!/usr/bin/env crystal

# Getting Started with Terminal Widgets
# Simple examples showing basic usage of each widget type

require "../src/terminal"

def render_and_show(widget_name : String, grid : Array(Array(Terminal::Cell)))
  puts "#{widget_name}:"
  grid.each do |line|
    line.each do |cell|
      cell.to_ansi(STDOUT)
    end
    puts
  end
  puts
end

puts "╔════════════════════════════════════════════╗"
puts "║       Terminal Widgets - Getting Started   ║"
puts "╚════════════════════════════════════════════╝"
puts

# 1. Simple Table
puts "1. TableWidget - Display tabular data with automatic sizing:"
table = Terminal::TableWidget.new("users")
  .col("Name", :name, 10, :left, :white)
  .col("Age", :age, 3, :right, :white)
  .rows([
    {"name" => "Alice", "age" => "28"},
    {"name" => "Bob", "age" => "35"}
  ])

render_and_show("Table", table.render(50, 10))

# 2. Simple Input
puts "2. InputWidget - Text input with prompt:"
input = Terminal::InputWidget.new("username", "Enter name:")
input.handle(Terminal::Msg::InputEvent.new('J', Time::Span::ZERO))
input.handle(Terminal::Msg::InputEvent.new('o', Time::Span::ZERO))
input.handle(Terminal::Msg::InputEvent.new('h', Time::Span::ZERO))
input.handle(Terminal::Msg::InputEvent.new('n', Time::Span::ZERO))

render_and_show("Input", input.render(30, 5))

# 3. Simple Dropdown
puts "3. DropdownWidget - Selection from options:"
dropdown = Terminal::DropdownWidget.new(
  "color",
  ["Red", "Green", "Blue"],
  "Choose color:"
)

render_and_show("Dropdown", dropdown.render(30, 5))

# 4. Simple Form
puts "4. FormWidget - Multiple controls together:"
form = Terminal::FormWidget.new("contact", title: "Contact Info")
form.add_control(Terminal::FormControl.new(
  id: "name",
  type: Terminal::FormControlType::TextInput,
  label: "Name"
))
form.add_control(Terminal::FormControl.new(
  id: "email",
  type: Terminal::FormControlType::TextInput,
  label: "Email"
))

render_and_show("Form", form.render(40, 10))

puts "Key Features:"
puts "✓ Automatic content-based sizing (no more full-screen width!)"
puts "✓ High contrast colors for accessibility"
puts "✓ Keyboard navigation (Tab, arrows, Enter, ESC)"
puts "✓ Proper terminal state management"
puts
puts "Next Steps:"
puts "• Try the interactive demos: ./interactive_accessible_form"
puts "• See comprehensive_demo.cr for advanced examples"
puts "• Check the API documentation for all widget options"