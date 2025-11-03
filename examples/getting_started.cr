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

# -----------------------------------------------------------------------------
# 1. Build a tiny dashboard with the UI builder
# -----------------------------------------------------------------------------

puts "╔════════════════════════════════════════════╗"
puts "║       Terminal Widgets - Getting Started   ║"
puts "╚════════════════════════════════════════════╝"
puts

puts "1. Terminal.app — Compose a simple dashboard"

app = Terminal.app(width: 40, height: 10) do |builder|
  builder.layout do |layout|
    layout.vertical do
      layout.widget "header", Terminal::UI::Constraint.length(3)
      layout.horizontal do
        layout.widget "left", Terminal::UI::Constraint.percent(50)
        layout.widget "right"
      end
    end
  end

  builder.text_box "header" do |text_box|
    text_box.set_text("Widgets in action")
  end

  builder.text_box "left" do |text_box|
    text_box.set_text("Left pane")
  end

  builder.text_box "right" do |text_box|
    text_box.set_text("Right pane")
  end
end

grid = app.widget_manager.compose(40, 10)
render_and_show("UI Builder", grid)

puts "2. Individual widgets — render directly"

# 2a. Simple Table
puts "  • TableWidget"
table = Terminal::TableWidget.new("users")
  .col("Name", :name, 10, :left, :white)
  .col("Age", :age, 3, :right, :white)
  .rows([
    {"name" => "Alice", "age" => "28"},
    {"name" => "Bob", "age" => "35"},
  ])

render_and_show("Table", table.render(50, 6))

# 2b. Simple Input
puts "  • InputWidget"
input = Terminal::InputWidget.new("username", "Enter name:")
input.handle(Terminal::Msg::InputEvent.new('J', Time::Span::ZERO))
input.handle(Terminal::Msg::InputEvent.new('o', Time::Span::ZERO))
input.handle(Terminal::Msg::InputEvent.new('h', Time::Span::ZERO))
input.handle(Terminal::Msg::InputEvent.new('n', Time::Span::ZERO))

render_and_show("Input", input.render(30, 5))

# 2c. Simple Dropdown
puts "  • DropdownWidget"
dropdown = Terminal::DropdownWidget.new(
  "color",
  ["Red", "Green", "Blue"],
  "Choose color:"
)

render_and_show("Dropdown", dropdown.render(30, 5))

# 2d. Simple Form
puts "  • FormWidget"
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
puts "• Try the interactive demo: crystal run examples/interactive_builder_demo.cr"
puts "• See comprehensive_demo.cr for advanced examples"
puts "• Check the API documentation for all widget options"
