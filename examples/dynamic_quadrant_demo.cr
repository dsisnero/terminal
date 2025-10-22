# Dynamic Resize Demo for Four Quadrant Layout
# Shows how layouts adapt to different terminal sizes

require "../src/terminal/concurrent_layout"
require "../src/terminal/table_widget"

def create_quadrant_layout(width : Int32, height : Int32)
  factory = Terminal::Layout::LayoutFactory.create_with_engine(2)
  terminal_area = Terminal::Geometry::Rect.new(0, 0, width, height)

  # Main vertical split
  main_layout = factory.vertical.percentage(50).percentage(50).build(factory.@engine)
  main_areas = main_layout.split_sync(terminal_area)

  # Top horizontal split
  top_layout = factory.horizontal.percentage(45).percentage(55).build(factory.@engine)
  top_areas = top_layout.split_sync(main_areas[0])

  # Bottom horizontal split
  bottom_layout = factory.horizontal.percentage(55).percentage(45).build(factory.@engine)
  bottom_areas = bottom_layout.split_sync(main_areas[1])

  result = {
    table:     top_areas[0],    # Top-left
    text:      top_areas[1],    # Top-right
    progress:  bottom_areas[0], # Bottom-left
    directory: bottom_areas[1], # Bottom-right
  }

  factory.stop_engine
  result
end

puts "🔄 Dynamic Four Quadrant Layout Demo"
puts "Shows how layout adapts to different terminal sizes"
puts ""

# Test different terminal sizes
sizes = [
  {name: "Small", width: 60, height: 16},
  {name: "Medium", width: 80, height: 24},
  {name: "Large", width: 120, height: 30},
  {name: "Wide", width: 160, height: 24},
  {name: "Tall", width: 80, height: 40},
]

sizes.each do |size|
  puts "📐 #{size[:name]} Terminal: #{size[:width]}×#{size[:height]}"

  layout = create_quadrant_layout(size[:width], size[:height])

  puts "  ┌─────────────────────────────────────────────────────────────┐"
  puts "  │ Quadrant    │ Size       │ Position   │ Aspect Ratio       │"
  puts "  ├─────────────────────────────────────────────────────────────┤"

  layout.each do |name, area|
    ratio = (area.width.to_f / area.height).round(2)
    size_str = "#{area.width}×#{area.height}"
    pos_str = "(#{area.x},#{area.y})"

    printf "  │ %-11s │ %-10s │ %-10s │ %-18s │\n",
      name.to_s.capitalize, size_str, pos_str, ratio
  end

  puts "  └─────────────────────────────────────────────────────────────┘"

  # Show content adaptation
  table_area = layout[:table]
  text_area = layout[:text]

  # Sample table check
  sales_data = [
    {"Product" => "Laptop Pro Max", "Sales" => "1,234", "Revenue" => "$1,234,000"},
    {"Product" => "Phone", "Sales" => "2,567", "Revenue" => "$512,400"},
    {"Product" => "Tablet", "Sales" => "890", "Revenue" => "$267,000"},
  ]

  table = Terminal::TableWidget.new("sales")
    .col("Product", :Product, 15)
    .col("Sales", :Sales, 8)
    .col("Revenue", :Revenue, 12)
    .rows(sales_data)

  table_size = table.calculate_optimal_size
  table_fits = table.size_fits?(table_size, table_area.size)

  # Sample text check
  sample_text = "This is sample documentation text that needs to be wrapped based on the available width in the text quadrant area."
  wrapped_lines = Terminal::TextMeasurement.wrap_text(sample_text, text_area.width - 4)

  puts "  Content Adaptation:"
  puts "    Table: #{table_fits ? "✅" : "⚠️"} (needs #{table_size.width}×#{table_size.height}, has #{table_area.width}×#{table_area.height})"
  puts "    Text: #{wrapped_lines.size} lines (width #{text_area.width - 4})"
  puts ""
end

# Show layout constraints in action
puts "🎯 Layout Constraint Comparison"
puts ""

terminal_width = 100
constraints_examples = [
  {
    name:        "Equal Split",
    top:         [50, 50],
    bottom:      [50, 50],
    description: "Perfect symmetry - all quadrants equal",
  },
  {
    name:        "Table Focus",
    top:         [60, 40],
    bottom:      [30, 70],
    description: "Emphasize table and directory areas",
  },
  {
    name:        "Text Heavy",
    top:         [30, 70],
    bottom:      [40, 60],
    description: "More space for text and directory content",
  },
  {
    name:        "Progress Focus",
    top:         [40, 60],
    bottom:      [60, 40],
    description: "Highlight progress monitoring area",
  },
]

constraints_examples.each do |example|
  puts "#{example[:name]}: #{example[:description]}"

  # Calculate widths for 100-char terminal
  top_left = (terminal_width * example[:top][0] / 100).to_i
  top_right = terminal_width - top_left
  bottom_left = (terminal_width * example[:bottom][0] / 100).to_i
  bottom_right = terminal_width - bottom_left

  puts "  Top:    Table(#{top_left}) | Text(#{top_right})"
  puts "  Bottom: Progress(#{bottom_left}) | Directory(#{bottom_right})"
  puts ""
end

# Demonstrate responsive layout principles
puts "📱 Responsive Layout Principles"
puts ""
puts "1. Minimum Sizes:"
puts "   • Table widget needs 30×6 minimum for headers + data"
puts "   • Text area needs 20×3 minimum for readable content"
puts "   • Progress bars need 25×1 minimum per indicator"
puts "   • Directory tree needs 15×5 minimum for useful display"
puts ""

puts "2. Adaptive Behavior:"
puts "   • Small screens: Stack vertically or reduce content"
puts "   • Wide screens: Use extra space for text wrapping"
puts "   • Tall screens: Show more table rows/directory entries"
puts ""

puts "3. Content Overflow:"
puts "   • Tables: Scroll or paginate when rows exceed height"
puts "   • Text: Word wrap and vertical scroll as needed"
puts "   • Progress: Abbreviate task names if width constrained"
puts "   • Directory: Truncate deep paths, show scroll indicators"
puts ""

# Final layout showcase
puts "🎨 Production Layout Example (80×24)"
puts ""

layout = create_quadrant_layout(80, 24)

# Create visual representation
puts "┌" + "─" * 38 + "┬" + "─" * 39 + "┐"
puts "│" + " TABLE: Sales Dashboard".ljust(38) + "│" + " TEXT: Documentation".ljust(39) + "│"
puts "│" + " - Product listings".ljust(38) + "│" + " - Feature explanations".ljust(39) + "│"
puts "│" + " - Sales metrics".ljust(38) + "│" + " - Usage examples".ljust(39) + "│"
puts "│" + " - Revenue tracking".ljust(38) + "│" + " - API references".ljust(39) + "│"
puts "│" + " Size: #{layout[:table].width}×#{layout[:table].height}".ljust(38) + "│" + " Size: #{layout[:text].width}×#{layout[:text].height}".ljust(39) + "│"
puts "├" + "─" * 38 + "┼" + "─" * 39 + "┤"
puts "│" + " PROGRESS: Build Status".ljust(38) + "│" + " DIRECTORY: Project Files".ljust(39) + "│"
puts "│" + " - Compile progress".ljust(38) + "│" + " - Source code tree".ljust(39) + "│"
puts "│" + " - Test execution".ljust(38) + "│" + " - Asset organization".ljust(39) + "│"
puts "│" + " - Deploy status".ljust(38) + "│" + " - Build artifacts".ljust(39) + "│"
puts "│" + " Size: #{layout[:progress].width}×#{layout[:progress].height}".ljust(38) + "│" + " Size: #{layout[:directory].width}×#{layout[:directory].height}".ljust(39) + "│"
puts "└" + "─" * 38 + "┴" + "─" * 39 + "┘"

puts ""
puts "🚀 Ready for Integration!"
puts "   The four quadrant system provides:"
puts "   • Flexible responsive layouts that adapt to terminal size"
puts "   • Content-aware sizing with minimum constraints"
puts "   • Concurrent calculation for smooth performance"
puts "   • Modular design for easy customization"
puts "   • Type-safe geometry operations"
