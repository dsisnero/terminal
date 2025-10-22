# Simple Full Screen Four Quadrant Visual Demo
# Shows widgets actually rendered on screen in their quadrants

require "../src/terminal/concurrent_layout"
require "../src/terminal/table_widget"

# Screen control functions
def clear_screen
  print "\e[2J\e[H"
end

def move_to(x : Int32, y : Int32)
  print "\e[#{y + 1};#{x + 1}H"
end

def draw_border(x : Int32, y : Int32, width : Int32, height : Int32, title : String)
  # Top border with title
  move_to(x, y)
  print "┌─ #{title} "
  print "─" * (width - title.size - 5)
  print "┐"

  # Side borders
  (1...height - 1).each do |row|
    move_to(x, y + row)
    print "│"
    move_to(x + width - 1, y + row)
    print "│"
  end

  # Bottom border
  move_to(x, y + height - 1)
  print "└"
  print "─" * (width - 2)
  print "┘"
end

# Get terminal size (fallback to 80x24)
terminal_width = 80
terminal_height = 24

begin
  if cols = `tput cols 2>/dev/null`.strip.to_i?
    terminal_width = cols
  end
  if lines = `tput lines 2>/dev/null`.strip.to_i?
    terminal_height = lines
  end
rescue
  # Use defaults
end

# Clear screen and start
clear_screen
puts "🔲 Full Screen Four Quadrant Layout Demo"
puts "Terminal: #{terminal_width} × #{terminal_height}"
puts "Press Enter to start..."
gets

clear_screen

# Create layout for full terminal
factory = Terminal::Layout::LayoutFactory.create_with_engine(2)
terminal_area = Terminal::Geometry::Rect.new(0, 0, terminal_width, terminal_height)

# Split screen into 4 quadrants
# First: vertical split (top/bottom)
main_layout = factory.vertical
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

regions = main_layout.split_sync(terminal_area)
top_half = regions[0]    # Top 50%
bottom_half = regions[1] # Bottom 50%

# Split top half horizontally (left/right)
top_layout = factory.horizontal
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

top_regions = top_layout.split_sync(top_half)
top_left = top_regions[0]  # Top-left quadrant
top_right = top_regions[1] # Top-right quadrant

# Split bottom half horizontally (left/right)
bottom_layout = factory.horizontal
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

bottom_regions = bottom_layout.split_sync(bottom_half)
bottom_left = bottom_regions[0]  # Bottom-left quadrant
bottom_right = bottom_regions[1] # Bottom-right quadrant

# Draw the quadrant borders
draw_border(top_left.x, top_left.y, top_left.width, top_left.height, "📊 TABLE")
draw_border(top_right.x, top_right.y, top_right.width, top_right.height, "📄 TEXT")
draw_border(bottom_left.x, bottom_left.y, bottom_left.width, bottom_left.height, "⚡ PROGRESS")
draw_border(bottom_right.x, bottom_right.y, bottom_right.width, bottom_right.height, "📁 FILES")

# === QUADRANT 1: TABLE (Top-Left) ===
sales_data = [
  ["Product", "Sales", "Revenue"],
  ["MacBook Pro", "1,234", "$1.8M"],
  ["iPhone 15", "4,567", "$3.6M"],
  ["iPad Air", "2,890", "$1.7M"],
  ["Apple Watch", "1,876", "$750K"],
  ["AirPods Pro", "3,245", "$811K"],
]

content_y = top_left.y + 1
sales_data.each_with_index do |row, i|
  break if content_y + i >= top_left.y + top_left.height - 1

  move_to(top_left.x + 2, content_y + i)

  if i == 0       # Header
    print "\e[1m" # Bold
  end

  # Format columns
  product = row[0].ljust(12)[0, 12]
  sales = row[1].rjust(8)[0, 8]
  revenue = row[2].rjust(10)[0, 10]

  available_width = top_left.width - 4
  if available_width >= 30
    print "#{product} #{sales} #{revenue}"
  elsif available_width >= 20
    print "#{product} #{sales}"
  else
    print product
  end

  if i == 0
    print "\e[0m" # Reset bold
  end
end

# === QUADRANT 2: TEXT (Top-Right) ===
doc_text = <<-TEXT
Terminal Layout System

This demonstrates a full-screen four-quadrant layout using the Crystal terminal layout engine.

Features:
• Responsive to your terminal size
• Concurrent layout calculations
• Widget integration
• ANSI-aware text processing

Each quadrant automatically sizes its content based on available space.

Perfect for dashboards, monitoring tools, and interactive applications.
TEXT

content_y = top_right.y + 1
content_width = top_right.width - 4

lines = Terminal::TextMeasurement.wrap_text(doc_text, content_width)
lines.each_with_index do |line, i|
  break if content_y + i >= top_right.y + top_right.height - 1

  move_to(top_right.x + 2, content_y + i)
  truncated = Terminal::TextMeasurement.truncate_text(line, content_width)
  print truncated
end

# === QUADRANT 3: PROGRESS (Bottom-Left) ===
tasks = [
  {name: "Database Sync", progress: 85},
  {name: "API Tests", progress: 67},
  {name: "Build Process", progress: 92},
  {name: "Deploy Pipeline", progress: 43},
  {name: "Cache Warming", progress: 100},
]

content_y = bottom_left.y + 1
content_width = bottom_left.width - 4

tasks.each_with_index do |task, i|
  break if content_y + i >= bottom_left.y + bottom_left.height - 1

  move_to(bottom_left.x + 2, content_y + i)

  # Task name
  name = Terminal::TextMeasurement.truncate_text(task[:name], 12)

  # Progress bar
  if content_width >= 25
    bar_width = content_width - 18 # Reserve space for name and percentage
    filled = (bar_width * task[:progress] / 100).to_i
    bar = "█" * filled + "░" * (bar_width - filled)
    print "#{name.ljust(12)} │#{bar}│ #{task[:progress].to_s.rjust(3)}%"
  else
    print "#{name} #{task[:progress]}%"
  end
end

# === QUADRANT 4: FILES (Bottom-Right) ===
project_files = [
  "📁 src/",
  "  📄 geometry.cr",
  "  📄 layout.cr",
  "  📄 widget.cr",
  "📁 examples/",
  "  📄 quadrant_demo.cr",
  "  📄 dashboard.cr",
  "📁 spec/",
  "  📄 layout_spec.cr",
  "📄 shard.yml",
  "📄 README.md",
]

content_y = bottom_right.y + 1
content_width = bottom_right.width - 4

project_files.each_with_index do |file, i|
  break if content_y + i >= bottom_right.y + bottom_right.height - 1

  move_to(bottom_right.x + 2, content_y + i)
  truncated = Terminal::TextMeasurement.truncate_text(file, content_width)
  print truncated
end

# Status bar at bottom
move_to(0, terminal_height - 1)
print "\e[7m" # Reverse video
status = " Four Quadrant Layout Demo • #{terminal_width}×#{terminal_height} • Press Enter to exit "
print status.ljust(terminal_width)[0, terminal_width]
print "\e[0m" # Reset

# Wait for user input
move_to(0, terminal_height)
gets

# Clean up
clear_screen
factory.stop_engine

puts "✅ Four Quadrant Layout Demo Complete!"
puts ""
puts "Layout Results:"
puts "  Terminal Size: #{terminal_width} × #{terminal_height}"
puts "  Top-Left (Table): #{top_left.width}×#{top_left.height} at (#{top_left.x}, #{top_left.y})"
puts "  Top-Right (Text): #{top_right.width}×#{top_right.height} at (#{top_right.x}, #{top_right.y})"
puts "  Bottom-Left (Progress): #{bottom_left.width}×#{bottom_left.height} at (#{bottom_left.x}, #{bottom_left.y})"
puts "  Bottom-Right (Files): #{bottom_right.width}×#{bottom_right.height} at (#{bottom_right.x}, #{bottom_right.y})"
puts ""
puts "🚀 Ready for production terminal applications!"
