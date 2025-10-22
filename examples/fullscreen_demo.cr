# Immediate Full Screen Four Quadrant Visual Demo
# Shows widgets rendered on screen in their quadrants without prompts

require "../src/terminal/concurrent_layout"
require "../src/terminal/table_widget"

# Get terminal size with fallback
def get_terminal_size
  width, height = 80, 24 # Defaults

  begin
    if cols_output = `tput cols 2>/dev/null`.strip
      width = cols_output.to_i if cols_output.match(/^\d+$/)
    end
    if lines_output = `tput lines 2>/dev/null`.strip
      height = lines_output.to_i if lines_output.match(/^\d+$/)
    end
  rescue
    # Keep defaults
  end

  {width, height}
end

# Screen positioning
def move_to(x : Int32, y : Int32)
  "\e[#{y + 1};#{x + 1}H"
end

def clear_screen
  "\e[2J\e[H"
end

# Get actual terminal dimensions
terminal_width, terminal_height = get_terminal_size

# Clear screen and start immediately
print clear_screen

# Create layout factory and full terminal area
factory = Terminal::Layout::LayoutFactory.create_with_engine(2)
terminal_area = Terminal::Geometry::Rect.new(0, 0, terminal_width, terminal_height - 2) # Reserve 2 lines for status

# === CREATE FOUR QUADRANT LAYOUT ===

# Main vertical split (50/50)
main_layout = factory.vertical
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

main_regions = main_layout.split_sync(terminal_area)
top_half = main_regions[0]
bottom_half = main_regions[1]

# Top horizontal split (50/50)
top_layout = factory.horizontal
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

top_regions = top_layout.split_sync(top_half)
top_left = top_regions[0]  # TABLE quadrant
top_right = top_regions[1] # TEXT quadrant

# Bottom horizontal split (50/50)
bottom_layout = factory.horizontal
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

bottom_regions = bottom_layout.split_sync(bottom_half)
bottom_left = bottom_regions[0]  # PROGRESS quadrant
bottom_right = bottom_regions[1] # FILES quadrant

# === RENDER COMPLETE INTERFACE ===
output = ""

# Draw quadrant borders with titles
def draw_box_border(area, title)
  result = ""

  # Top border with title
  result += move_to(area.x, area.y)
  title_display = "─ #{title} "
  remaining = area.width - title_display.size - 1
  result += "┌#{title_display}"
  result += "─" * [remaining, 0].max
  result += "┐"

  # Side borders for middle rows
  (1...area.height - 1).each do |row|
    result += move_to(area.x, area.y + row)
    result += "│"
    result += move_to(area.x + area.width - 1, area.y + row)
    result += "│"
  end

  # Bottom border
  result += move_to(area.x, area.y + area.height - 1)
  result += "└"
  result += "─" * (area.width - 2)
  result += "┘"

  result
end

# Draw all borders
output += draw_box_border(top_left, "📊 SALES DASHBOARD")
output += draw_box_border(top_right, "📄 DOCUMENTATION")
output += draw_box_border(bottom_left, "⚡ BUILD PROGRESS")
output += draw_box_border(bottom_right, "📁 PROJECT FILES")

# === RENDER CONTENT ===

# TOP-LEFT: Sales table
sales_data = [
  ["Product", "Units", "Revenue"],
  ["MacBook Pro", "1,234", "$1.85M"],
  ["iPhone 15", "4,567", "$3.65M"],
  ["iPad Air", "2,890", "$1.73M"],
  ["Apple Watch", "1,876", "$750K"],
  ["AirPods Pro", "3,245", "$811K"],
  ["Mac Studio", "432", "$863K"],
]

content_y = top_left.y + 1
content_width = top_left.width - 2

sales_data.first([sales_data.size, top_left.height - 2].min).each_with_index do |row, i|
  output += move_to(top_left.x + 1, content_y + i)

  if i == 0           # Header row
    output += "\e[1m" # Bold
  end

  # Format based on available width
  if content_width >= 35
    product = row[0].ljust(14)[0, 14]
    units = row[1].rjust(8)[0, 8]
    revenue = row[2].rjust(10)[0, 10]
    output += "#{product} #{units} #{revenue}"
  elsif content_width >= 25
    product = row[0].ljust(12)[0, 12]
    revenue = row[2].rjust(10)[0, 10]
    output += "#{product} #{revenue}"
  else
    product = Terminal::TextMeasurement.truncate_text(row[0], content_width)
    output += product
  end

  if i == 0
    output += "\e[0m" # Reset bold
  end
end

# TOP-RIGHT: Documentation text
doc_text = <<-TEXT
Terminal Layout System v2.0

This full-screen demo shows four quadrants working together in your actual terminal size (#{terminal_width}×#{terminal_height}).

FEATURES:
• Automatic sizing based on terminal dimensions
• Concurrent layout calculations
• Widget integration with content adaptation
• ANSI-aware text processing
• Production-ready architecture

Each quadrant contains different content types that automatically adapt to the available space.

Perfect for dashboards, monitoring tools, file browsers, and interactive terminal applications.
TEXT

content_y = top_right.y + 1
content_width = top_right.width - 2

doc_lines = Terminal::TextMeasurement.wrap_text(doc_text, content_width)
visible_lines = [doc_lines.size, top_right.height - 2].min

doc_lines.first(visible_lines).each_with_index do |line, i|
  output += move_to(top_right.x + 1, content_y + i)
  output += line
end

# BOTTOM-LEFT: Progress indicators
progress_tasks = [
  {name: "Database Migration", progress: 87},
  {name: "API Tests", progress: 64},
  {name: "Frontend Build", progress: 95},
  {name: "Docker Deploy", progress: 41},
  {name: "SSL Certificate", progress: 78},
  {name: "Cache Warming", progress: 100},
]

content_y = bottom_left.y + 1
content_width = bottom_left.width - 2

visible_tasks = [progress_tasks.size, bottom_left.height - 2].min

progress_tasks.first(visible_tasks).each_with_index do |task, i|
  output += move_to(bottom_left.x + 1, content_y + i)

  if content_width >= 30
    # Full progress bar
    name = Terminal::TextMeasurement.truncate_text(task[:name], 14)
    bar_width = content_width - 22 # Reserve space for name + percentage
    filled = (bar_width * task[:progress] / 100).to_i

    bar = "█" * filled + "░" * (bar_width - filled)
    output += "#{name.ljust(14)} │#{bar}│ #{task[:progress].to_s.rjust(3)}%"
  elsif content_width >= 20
    # Compact version
    name = Terminal::TextMeasurement.truncate_text(task[:name], 10)
    output += "#{name.ljust(10)} #{task[:progress]}%"
  else
    # Minimal version
    name = Terminal::TextMeasurement.truncate_text(task[:name], content_width - 5)
    output += "#{name} #{task[:progress]}%"
  end
end

# BOTTOM-RIGHT: File browser
project_structure = [
  "📁 src/",
  "  📁 terminal/",
  "    📄 geometry.cr",
  "    📄 concurrent_layout.cr",
  "    📄 table_widget.cr",
  "    📄 text_measurement.cr",
  "  📁 examples/",
  "    📄 screen_demo.cr",
  "    📄 quadrant_demo.cr",
  "📁 spec/",
  "  📄 geometry_spec.cr",
  "  📄 layout_spec.cr",
  "📄 shard.yml",
  "📄 README.md",
]

content_y = bottom_right.y + 1
content_width = bottom_right.width - 2

visible_files = [project_structure.size, bottom_right.height - 2].min

project_structure.first(visible_files).each_with_index do |file, i|
  output += move_to(bottom_right.x + 1, content_y + i)
  truncated = Terminal::TextMeasurement.truncate_text(file, content_width)
  output += truncated
end

# Print the complete interface
print output

# Status line
status_y = terminal_height - 2
print move_to(0, status_y)
print "\e[7m" # Reverse video
status_text = " Four Quadrant Layout • #{terminal_width}×#{terminal_height} • Full Screen Demo "
status_line = status_text.ljust(terminal_width)[0, terminal_width]
print status_line
print "\e[0m" # Reset

# Summary line
print move_to(0, terminal_height - 1)
summary = "Layout: TL(#{top_left.width}×#{top_left.height}) TR(#{top_right.width}×#{top_right.height}) BL(#{bottom_left.width}×#{bottom_left.height}) BR(#{bottom_right.width}×#{bottom_right.height})"
summary_line = summary.ljust(terminal_width)[0, terminal_width]
print summary_line

# Position cursor at end
print move_to(0, terminal_height)

# Clean up
factory.stop_engine

puts ""
puts "✅ Full Screen Four Quadrant Layout Complete!"
puts ""
puts "Your terminal (#{terminal_width}×#{terminal_height}) was split into four equal quadrants:"
puts "  📊 Top-Left: Sales dashboard with product data table"
puts "  📄 Top-Right: Documentation with wrapped text content"
puts "  ⚡ Bottom-Left: Build progress with animated progress bars"
puts "  📁 Bottom-Right: Project file browser with directory tree"
puts ""
puts "Each quadrant automatically adapted its content to the available space."
puts "The layout system calculated optimal sizing for all widgets."
puts ""
puts "🚀 Ready for production terminal applications!"
