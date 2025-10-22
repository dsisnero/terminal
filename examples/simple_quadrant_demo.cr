# Simple Four Quadrant Layout Example
# Demonstrates basic 4-pane layout: table, text, progress, directory

require "../src/terminal/concurrent_layout"
require "../src/terminal/table_widget"

# Create layout factory
factory = Terminal::Layout::LayoutFactory.create_with_engine(2)

# Terminal dimensions (80x24 for standard terminal)
terminal_area = Terminal::Geometry::Rect.new(0, 0, 80, 24)

puts "Four Quadrant Layout - 80x24 Terminal"
puts "╭────────────────────────────────────────╮"
puts "│ TABLE (Sales)    │ TEXT (Documentation) │"
puts "│                  │                      │"
puts "├────────────────────────────────────────┤"
puts "│ PROGRESS (Tasks) │ TREE (Files)         │"
puts "│                  │                      │"
puts "╰────────────────────────────────────────╯"
puts ""

# Step 1: Split terminal vertically (top/bottom)
main_layout = factory.vertical
  .percentage(50) # Top half
  .percentage(50) # Bottom half
  .build(factory.@engine)

main_areas = main_layout.split_sync(terminal_area)
top_area = main_areas[0]    # Top half: 80x12
bottom_area = main_areas[1] # Bottom half: 80x12

puts "Main split: Top=#{top_area.width}x#{top_area.height}, Bottom=#{bottom_area.width}x#{bottom_area.height}"

# Step 2: Split top horizontally (table | text)
top_layout = factory.horizontal
  .percentage(50) # Left: Table
  .percentage(50) # Right: Text
  .build(factory.@engine)

top_areas = top_layout.split_sync(top_area)
table_area = top_areas[0] # Top-left: 40x12
text_area = top_areas[1]  # Top-right: 40x12

# Step 3: Split bottom horizontally (progress | directory)
bottom_layout = factory.horizontal
  .percentage(50) # Left: Progress
  .percentage(50) # Right: Directory
  .build(factory.@engine)

bottom_areas = bottom_layout.split_sync(bottom_area)
progress_area = bottom_areas[0]  # Bottom-left: 40x12
directory_area = bottom_areas[1] # Bottom-right: 40x12

puts ""
puts "Quadrants:"
puts "  Top-Left (Table): #{table_area.width}x#{table_area.height} at (#{table_area.x},#{table_area.y})"
puts "  Top-Right (Text): #{text_area.width}x#{text_area.height} at (#{text_area.x},#{text_area.y})"
puts "  Bottom-Left (Progress): #{progress_area.width}x#{progress_area.height} at (#{progress_area.x},#{progress_area.y})"
puts "  Bottom-Right (Directory): #{directory_area.width}x#{directory_area.height} at (#{directory_area.x},#{directory_area.y})"
puts ""

# Content for each quadrant

# 1. TABLE: Sales data
puts "📊 TOP-LEFT: Sales Table"
sales_data = [
  {"Product" => "Laptop", "Sales" => "1,234", "Revenue" => "$123K"},
  {"Product" => "Phone", "Sales" => "2,567", "Revenue" => "$256K"},
  {"Product" => "Tablet", "Sales" => "890", "Revenue" => "$89K"},
]

table = Terminal::TableWidget.new("sales")
  .col("Product", :Product, 10)
  .col("Sales", :Sales, 8)
  .col("Revenue", :Revenue, 8)
  .rows(sales_data)

table_size = table.calculate_optimal_size
puts "  Optimal size: #{table_size.width}x#{table_size.height}"
puts "  Available: #{table_area.width}x#{table_area.height}"
puts "  Fits: #{table.size_fits?(table_size, table_area.size)}"

# 2. TEXT: Documentation
puts ""
puts "📄 TOP-RIGHT: Documentation"
doc_text = "Welcome to the Terminal Layout System! This demonstrates four-quadrant layouts with tables, text, progress indicators, and directory trees."

wrapped_lines = Terminal::TextMeasurement.wrap_text(doc_text, text_area.width - 2)
puts "  Text width: #{Terminal::TextMeasurement.text_width(doc_text)} chars"
puts "  Wrapped to: #{wrapped_lines.size} lines"
puts "  Available: #{text_area.width}x#{text_area.height}"

# 3. PROGRESS: Task indicators
puts ""
puts "⚡ BOTTOM-LEFT: Progress Indicators"
tasks = [
  {name: "Build", progress: 75},
  {name: "Test", progress: 45},
  {name: "Deploy", progress: 30},
]

puts "  Area: #{progress_area.width}x#{progress_area.height}"
tasks.each do |task|
  bar_width = progress_area.width - 15
  filled = (bar_width * task[:progress] / 100).to_i
  bar = "█" * filled + "░" * (bar_width - filled)
  puts "  #{task[:name]}: │#{bar}│ #{task[:progress]}%"
end

# 4. DIRECTORY: File tree
puts ""
puts "📁 BOTTOM-RIGHT: Directory Tree"
files = [
  "src/",
  "  terminal/",
  "    geometry.cr",
  "    layout.cr",
  "    widget.cr",
  "spec/",
  "  layout_spec.cr",
  "README.md",
]

puts "  Area: #{directory_area.width}x#{directory_area.height}"
max_lines = [files.size, directory_area.height - 1].min
files.first(max_lines).each do |file|
  truncated = Terminal::TextMeasurement.truncate_text(file, directory_area.width - 2)
  puts "  #{truncated}"
end

puts ""
puts "✅ Four Quadrant Layout Complete!"
puts "   Each quadrant calculated independently and can contain different content types."
puts "   Layout system handles: sizing, positioning, text wrapping, and widget integration."

# Clean up
factory.stop_engine
