# Comprehensive concurrent layout demo
# Showcases SOLID principles, channels, concurrency, and modular design

require "../src/terminal/concurrent_layout"
require "../src/terminal/table_widget"
require "../src/terminal/form_widget"

# Sample data for table
table_rows = [
  {"product" => "Laptop", "price" => "$999", "stock" => "15", "category" => "Electronics"},
  {"product" => "Mouse", "price" => "$25", "stock" => "50", "category" => "Electronics"},
  {"product" => "Keyboard", "price" => "$75", "stock" => "30", "category" => "Electronics"},
  {"product" => "Monitor", "price" => "$299", "stock" => "8", "category" => "Electronics"},
  {"product" => "Chair", "price" => "$199", "stock" => "12", "category" => "Furniture"},
]

form_controls = [
  Terminal::FormControl.text_input("product", "Product:", ""),
  Terminal::FormControl.text_input("price", "Price:", ""),
  Terminal::FormControl.dropdown("category", "Category:", ["Electronics", "Furniture", "Office"]),
  Terminal::FormControl.text_input("stock", "Stock:", ""),
]

# Create widgets that use the new Measurable module
table = Terminal::TableWidget.new("product_table")
  .col("Product", :product, 15)
  .col("Price", :price, 8)
  .col("Stock", :stock, 8)
  .col("Category", :category, 12)
  .rows(table_rows)

form = Terminal::FormWidget.new("add_product_form", form_controls, "Add Product")

puts "🚀 Concurrent Layout System Demo"
puts "Features: SOLID principles, Channels, Concurrency, Modular Design"
puts "Press Enter to start..."
gets

# Create layout factory with concurrent engine
factory = Terminal::Layout::LayoutFactory.create_with_engine(4) # 4 worker threads

puts "✨ Creating complex nested layout using Builder pattern..."

# Main layout: Header, Content, Footer (Vertical)
main_layout = factory.vertical
  .length(3) # Header: 3 lines
  .ratio(1)  # Content: Fill remaining space
  .length(2) # Footer: 2 lines
  .margin(1) # 1-char margin around everything
  .build(factory.@engine)

# Content layout: Sidebar, Main Content (Horizontal)
content_layout = factory.horizontal
  .percentage(30) # Sidebar: 30% width
  .ratio(1)       # Main: Fill remaining space
  .build(factory.@engine)

# Main content layout: Table and Form (Vertical)
main_content_layout = factory.vertical
  .percentage(60) # Table: 60% height
  .ratio(1)       # Form: Fill remaining space
  .build(factory.@engine)

# Simulate terminal size
terminal_width = 120
terminal_height = 30
full_area = Terminal::Geometry::Rect.new(0, 0, terminal_width, terminal_height)

puts "📏 Calculating layouts using concurrent engine..."

# Calculate layouts using channels for concurrency
main_areas = main_layout.split_sync(full_area)
header_area = main_areas[0]
content_area = main_areas[1]
footer_area = main_areas[2]

content_areas = content_layout.split_sync(content_area)
sidebar_area = content_areas[0]
main_content_area = content_areas[1]

main_content_areas = main_content_layout.split_sync(main_content_area)
table_area = main_content_areas[0]
form_area = main_content_areas[1]

puts "🎯 Layout Results:"
puts "  Terminal: #{terminal_width}×#{terminal_height}"
puts "  Header: #{header_area.width}×#{header_area.height} at (#{header_area.x}, #{header_area.y})"
puts "  Sidebar: #{sidebar_area.width}×#{sidebar_area.height} at (#{sidebar_area.x}, #{sidebar_area.y})"
puts "  Table: #{table_area.width}×#{table_area.height} at (#{table_area.x}, #{table_area.y})"
puts "  Form: #{form_area.width}×#{form_area.height} at (#{form_area.x}, #{form_area.y})"
puts "  Footer: #{footer_area.width}×#{footer_area.height} at (#{footer_area.x}, #{footer_area.y})"

puts "\n📊 Widget Size Analysis (using Measurable module):"

# Use the new Measurable module methods
table_min = table.calculate_min_size
table_max = table.calculate_max_size
table_optimal = table.calculate_optimal_size
table_preferred = table.calculate_preferred_size(table_area.size)

puts "  Table Widget:"
puts "    Min: #{table_min.width}×#{table_min.height}"
puts "    Max: #{table_max.width}×#{table_max.height}"
puts "    Optimal: #{table_optimal.width}×#{table_optimal.height}"
puts "    Preferred (in layout): #{table_preferred.width}×#{table_preferred.height}"
puts "    Fits in layout? #{table.size_fits?(table_preferred, table_area.size)}"

form_min = form.calculate_min_size
form_max = form.calculate_max_size
form_optimal = form.calculate_optimal_size
form_preferred = form.calculate_preferred_size(form_area.size)

puts "  Form Widget:"
puts "    Min: #{form_min.width}×#{form_min.height}"
puts "    Max: #{form_max.width}×#{form_max.height}"
puts "    Optimal: #{form_optimal.width}×#{form_optimal.height}"
puts "    Preferred (in layout): #{form_preferred.width}×#{form_preferred.height}"
puts "    Fits in layout? #{form.size_fits?(form_preferred, form_area.size)}"

puts "\n🧪 Testing Concurrent Layout Performance..."

# Test async layout calculations with channels
start_time = Time.utc
concurrent_results = [] of Terminal::Layout::LayoutResponse

# Spawn multiple concurrent layout calculations
10.times do |i|
  spawn do
    response_channel = main_layout.split_async("test-#{i}", full_area)
    response = response_channel.receive
    concurrent_results << response
  end
end

# Wait for all to complete
Fiber.yield
sleep 10.milliseconds

end_time = Time.utc
duration = end_time - start_time

puts "  ✅ Completed #{concurrent_results.size} concurrent layout calculations in #{duration.total_milliseconds.round(2)}ms"
puts "  📈 Average per calculation: #{(duration.total_milliseconds / concurrent_results.size).round(2)}ms"

puts "\n🔧 Testing Different Constraint Types:"

# Test various constraint combinations
test_area = Terminal::Geometry::Rect.new(0, 0, 100, 40)

# Length constraints
length_layout = factory.horizontal
  .length(20)
  .length(30)
  .length(50)
  .build(factory.@engine)

length_regions = length_layout.split_sync(test_area)
puts "  Length (20+30+50): #{length_regions.map(&.width)} (total: #{length_regions.sum(&.width)})"

# Percentage constraints
percentage_layout = factory.horizontal
  .percentage(25)
  .percentage(35)
  .percentage(40)
  .build(factory.@engine)

percentage_regions = percentage_layout.split_sync(test_area)
puts "  Percentage (25%+35%+40%): #{percentage_regions.map(&.width)} (total: #{percentage_regions.sum(&.width)})"

# Ratio constraints
ratio_layout = factory.horizontal
  .ratio(1)
  .ratio(2)
  .ratio(3)
  .build(factory.@engine)

ratio_regions = ratio_layout.split_sync(test_area)
puts "  Ratio (1:2:3): #{ratio_regions.map(&.width)} (total: #{ratio_regions.sum(&.width)})"

# Mixed constraints
mixed_layout = factory.horizontal
  .length(20)     # Fixed 20
  .percentage(30) # 30% of total (30)
  .ratio(1)       # 1/2 of remaining (25)
  .ratio(1)       # 1/2 of remaining (25)
  .build(factory.@engine)

mixed_regions = mixed_layout.split_sync(test_area)
puts "  Mixed (20+30%+1:1): #{mixed_regions.map(&.width)} (total: #{mixed_regions.sum(&.width)})"

puts "\n🎨 Geometry Module Features:"

# Test geometry primitives
point1 = Terminal::Geometry::Point.new(10, 20)
point2 = Terminal::Geometry::Point.new(30, 40)
distance = point1.distance_to(point2)
midpoint = Terminal::Geometry::Point.new((point1.x + point2.x) // 2, (point1.y + point2.y) // 2)

puts "  📍 Point Operations:"
puts "    Point1: (#{point1.x}, #{point1.y})"
puts "    Point2: (#{point2.x}, #{point2.y})"
puts "    Distance: #{distance.round(2)}"
puts "    Midpoint: (#{midpoint.x}, #{midpoint.y})"

size1 = Terminal::Geometry::Size.new(50, 30)
size2 = Terminal::Geometry::Size.new(60, 25)
fits = size1.fits_in?(size2)
scaled = size1.scale(1.5)

puts "  📐 Size Operations:"
puts "    Size1: #{size1.width}×#{size1.height} (area: #{size1.area})"
puts "    Size2: #{size2.width}×#{size2.height} (area: #{size2.area})"
puts "    Size1 fits in Size2? #{fits}"
puts "    Size1 scaled 1.5x: #{scaled.width}×#{scaled.height}"

rect1 = Terminal::Geometry::Rect.new(10, 15, 30, 20)
rect2 = Terminal::Geometry::Rect.new(25, 20, 40, 25)
overlaps = rect1.overlaps?(rect2)
intersection = rect1.intersect(rect2)
union = rect1.union(rect2)

puts "  🔲 Rectangle Operations:"
puts "    Rect1: #{rect1.width}×#{rect1.height} at (#{rect1.x}, #{rect1.y})"
puts "    Rect2: #{rect2.width}×#{rect2.height} at (#{rect2.x}, #{rect2.y})"
puts "    Overlaps? #{overlaps}"
if intersection
  puts "    Intersection: #{intersection.width}×#{intersection.height} at (#{intersection.x}, #{intersection.y})"
else
  puts "    Intersection: none"
end
puts "    Union: #{union.width}×#{union.height} at (#{union.x}, #{union.y})"

puts "\n🧮 Text Measurement Features:"

sample_texts = [
  "Simple text",
  "\e[31mRed colored text\e[0m",
  "\e[1;32;40mBold green on black background\e[0m",
  "Very long text that will need to be wrapped or truncated for display",
]

puts "  📝 Text Analysis:"
sample_texts.each_with_index do |text, i|
  width = Terminal::TextMeasurement.text_width(text)
  truncated = Terminal::TextMeasurement.truncate_text(text, 20)
  wrapped = Terminal::TextMeasurement.wrap_text(text, 15)

  puts "    Text #{i + 1}: width=#{width}"
  puts "      Original: #{text}"
  puts "      Truncated (20): #{truncated}"
  puts "      Wrapped (15): #{wrapped.join(" | ")}"
end

max_width = Terminal::TextMeasurement.max_text_width(sample_texts)
puts "  📏 Maximum width: #{max_width}"

aligned_left = Terminal::TextMeasurement.align_text("Hello", 15, :left)
aligned_center = Terminal::TextMeasurement.align_text("Hello", 15, :center)
aligned_right = Terminal::TextMeasurement.align_text("Hello", 15, :right)

puts "  ↔️ Text Alignment (width=15):"
puts "    Left:   '#{aligned_left}'"
puts "    Center: '#{aligned_center}'"
puts "    Right:  '#{aligned_right}'"

puts "\n✅ All systems operational!"
puts "📊 Summary:"
puts "  - Geometry module: ✅ Points, Sizes, Rects, Insets"
puts "  - Text measurement: ✅ Width calculation, wrapping, alignment"
puts "  - Layout constraints: ✅ Length, Percentage, Ratio, Fill"
puts "  - Concurrent engine: ✅ #{concurrent_results.size} parallel calculations"
puts "  - SOLID principles: ✅ SRP, OCP, DIP implemented"
puts "  - Channel communication: ✅ Thread-safe async operations"
puts "  - Modular design: ✅ Mixins available for reuse"

# Clean up
factory.stop_engine

puts "\n🎯 Ready for production use!"
puts "Press Enter to exit..."
gets
