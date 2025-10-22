# Visual Four Quadrant Demo - Full Screen Rendering
# Actually displays widgets in their calculated positions on screen

require "../src/terminal/concurrent_layout"
require "../src/terminal/table_widget"

# ANSI escape codes for screen control
CLEAR_SCREEN = "\e[2J"
HIDE_CURSOR  = "\e[?25l"
SHOW_CURSOR  = "\e[?25h"
RESET_CURSOR = "\e[H"

def move_cursor(x : Int32, y : Int32)
  "\e[#{y + 1};#{x + 1}H"
end

def draw_box(x : Int32, y : Int32, width : Int32, height : Int32, title : String)
  result = ""

  # Top border with title
  result += move_cursor(x, y)
  title_text = " #{title} "
  title_len = Terminal::TextMeasurement.text_width(title_text)
  border_len = width - title_len - 2
  left_border = border_len // 2
  right_border = border_len - left_border

  result += "┌" + "─" * left_border + title_text + "─" * right_border + "┐"

  # Side borders
  (1...height - 1).each do |row|
    result += move_cursor(x, y + row)
    result += "│" + " " * (width - 2) + "│"
  end

  # Bottom border
  result += move_cursor(x, y + height - 1)
  result += "└" + "─" * (width - 2) + "┘"

  result
end

def render_table_in_area(area : Terminal::Geometry::Rect, data : Array(Hash(String, String)))
  result = ""
  content_x = area.x + 1
  content_y = area.y + 1
  content_width = area.width - 2
  content_height = area.height - 2

  # Table headers
  result += move_cursor(content_x, content_y)
  result += "\e[1m" # Bold
  result += "Product".ljust(12)[0, 12]
  result += "Sales".rjust(8)[0, 8] if content_width > 20
  result += "Revenue".rjust(10)[0, 10] if content_width > 30
  result += "\e[0m" # Reset

  # Separator line
  if content_height > 1
    result += move_cursor(content_x, content_y + 1)
    result += "─" * [content_width, 30].min
  end

  # Data rows
  visible_rows = [data.size, content_height - 2].min
  data.first(visible_rows).each_with_index do |row, i|
    next if content_y + 2 + i >= area.y + area.height - 1

    result += move_cursor(content_x, content_y + 2 + i)

    product = Terminal::TextMeasurement.truncate_text(row["product"], 12)
    result += product.ljust(12)[0, 12]

    if content_width > 20
      sales = Terminal::TextMeasurement.truncate_text(row["sales"], 8)
      result += sales.rjust(8)[0, 8]
    end

    if content_width > 30
      revenue = Terminal::TextMeasurement.truncate_text(row["revenue"], 10)
      result += revenue.rjust(10)[0, 10]
    end
  end

  result
end

def render_text_in_area(area : Terminal::Geometry::Rect, text : String)
  result = ""
  content_x = area.x + 1
  content_y = area.y + 1
  content_width = area.width - 2
  content_height = area.height - 2

  lines = Terminal::TextMeasurement.wrap_text(text, content_width)
  visible_lines = [lines.size, content_height].min

  lines.first(visible_lines).each_with_index do |line, i|
    result += move_cursor(content_x, content_y + i)
    truncated = Terminal::TextMeasurement.truncate_text(line, content_width)
    result += truncated
  end

  result
end

def render_progress_in_area(area : Terminal::Geometry::Rect, tasks : Array(NamedTuple(name: String, progress: Int32)))
  result = ""
  content_x = area.x + 1
  content_y = area.y + 1
  content_width = area.width - 2
  content_height = area.height - 2

  visible_tasks = [tasks.size, content_height].min

  tasks.first(visible_tasks).each_with_index do |task, i|
    next if content_y + i >= area.y + area.height - 1

    result += move_cursor(content_x, content_y + i)

    # Task name (truncated to fit)
    name_width = [content_width // 2, 15].min
    name = Terminal::TextMeasurement.truncate_text(task[:name], name_width)
    result += name.ljust(name_width)

    # Progress bar
    bar_width = content_width - name_width - 6 # Reserve space for percentage
    if bar_width > 5
      filled = (bar_width * task[:progress] // 100)
      bar = "█" * filled + "░" * (bar_width - filled)
      result += " │#{bar}│ #{task[:progress].to_s.rjust(3)}%"
    else
      result += " #{task[:progress]}%"
    end
  end

  result
end

def render_directory_in_area(area : Terminal::Geometry::Rect, files : Array(String))
  result = ""
  content_x = area.x + 1
  content_y = area.y + 1
  content_width = area.width - 2
  content_height = area.height - 2

  visible_files = [files.size, content_height].min

  files.first(visible_files).each_with_index do |file, i|
    result += move_cursor(content_x, content_y + i)
    truncated = Terminal::TextMeasurement.truncate_text(file, content_width)
    result += truncated
  end

  result
end

# Get terminal size
def get_terminal_size
  # Try to get actual terminal size
  if tty = Process.run("tput", ["cols"], output: Process::Redirect::Pipe, error: Process::Redirect::Close).output.gets_to_end.strip.to_i?
    width = tty
  else
    width = 80 # Default
  end

  if tty = Process.run("tput", ["lines"], output: Process::Redirect::Pipe, error: Process::Redirect::Close).output.gets_to_end.strip.to_i?
    height = tty
  else
    height = 24 # Default
  end

  {width, height}
rescue
  {80, 24} # Fallback
end

# === MAIN DEMO ===

# Clear screen and hide cursor
print CLEAR_SCREEN + HIDE_CURSOR + RESET_CURSOR

# Get actual terminal dimensions
terminal_width, terminal_height = get_terminal_size
terminal_area = Terminal::Geometry::Rect.new(0, 0, terminal_width, terminal_height)

puts "🖥️  Full Screen Four Quadrant Demo (#{terminal_width}×#{terminal_height})"
sleep 1

# Clear screen again for the actual demo
print CLEAR_SCREEN + RESET_CURSOR

# Create layout factory
factory = Terminal::Layout::LayoutFactory.create_with_engine(2)

# Create the four quadrant layout
main_layout = factory.vertical
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

main_regions = main_layout.split_sync(terminal_area)
top_region = main_regions[0]
bottom_region = main_regions[1]

# Top split: Table | Documentation
top_layout = factory.horizontal
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

top_regions = top_layout.split_sync(top_region)
table_area = top_regions[0]
docs_area = top_regions[1]

# Bottom split: Progress | Directory
bottom_layout = factory.horizontal
  .percentage(50)
  .percentage(50)
  .build(factory.@engine)

bottom_regions = bottom_layout.split_sync(bottom_region)
progress_area = bottom_regions[0]
directory_area = bottom_regions[1]

# Sample data
sales_data = [
  {"product" => "MacBook Pro", "sales" => "1,234", "revenue" => "$1,851K"},
  {"product" => "iPhone 15", "sales" => "4,567", "revenue" => "$3,654K"},
  {"product" => "iPad Air", "sales" => "2,890", "revenue" => "$1,734K"},
  {"product" => "Apple Watch", "sales" => "1,876", "revenue" => "$750K"},
  {"product" => "AirPods Pro", "sales" => "3,245", "revenue" => "$811K"},
  {"product" => "Mac Studio", "sales" => "432", "revenue" => "$863K"},
  {"product" => "HomePod", "sales" => "987", "revenue" => "$296K"},
]

documentation = <<-DOC
Terminal Layout System

This four-quadrant layout demonstrates advanced terminal UI capabilities:

• Responsive design adapting to your terminal size
• Concurrent layout calculations using Crystal channels
• Widget integration with automatic content sizing
• ANSI-aware text processing and measurement

The system supports percentage-based constraints, ratio distributions, and fixed-length sizing. Each quadrant calculates its optimal content based on available space.

Perfect for dashboards, monitoring tools, file managers, and interactive terminal applications.
DOC

tasks = [
  {name: "Database Sync", progress: 85},
  {name: "API Tests", progress: 67},
  {name: "Build Process", progress: 92},
  {name: "Deploy Pipeline", progress: 43},
  {name: "Cache Warming", progress: 100},
  {name: "SSL Renewal", progress: 28},
]

files = [
  "📁 src/",
  "  📁 terminal/",
  "    📄 geometry.cr",
  "    📄 layout.cr",
  "    📄 widget.cr",
  "    📄 table_widget.cr",
  "  📁 examples/",
  "    📄 four_quadrant_demo.cr",
  "    📄 dashboard_demo.cr",
  "📁 spec/",
  "  📄 geometry_spec.cr",
  "  📄 layout_spec.cr",
  "📄 shard.yml",
  "📄 README.md",
]

# Render the complete interface
output = ""

# Draw all quadrant boxes
output += draw_box(table_area.x, table_area.y, table_area.width, table_area.height, "📊 SALES DASHBOARD")
output += draw_box(docs_area.x, docs_area.y, docs_area.width, docs_area.height, "📚 DOCUMENTATION")
output += draw_box(progress_area.x, progress_area.y, progress_area.width, progress_area.height, "⚡ BUILD PROGRESS")
output += draw_box(directory_area.x, directory_area.y, directory_area.width, directory_area.height, "📁 PROJECT FILES")

# Render content in each quadrant
output += render_table_in_area(table_area, sales_data)
output += render_text_in_area(docs_area, documentation)
output += render_progress_in_area(progress_area, tasks)
output += render_directory_in_area(directory_area, files)

# Print everything at once for smooth rendering
print output

# Add status line at bottom
status_y = terminal_height - 1
print move_cursor(0, status_y)
print "\e[7m" # Reverse video
status_text = " Four Quadrant Layout • #{terminal_width}×#{terminal_height} • Press Ctrl+C to exit "
status_padded = status_text.ljust(terminal_width)[0, terminal_width]
print status_padded
print "\e[0m" # Reset

# Position cursor at bottom right
print move_cursor(terminal_width - 1, terminal_height - 1)

# Animation loop - update progress bars
spawn do
  loop do
    sleep 500.milliseconds

    # Update progress bars with animation
    updated_output = ""

    # Animate progress (simple increment)
    animated_tasks = tasks.map do |task|
      new_progress = task[:progress] < 100 ? task[:progress] + 1 : task[:progress]
      {name: task[:name], progress: new_progress}
    end

    updated_output += render_progress_in_area(progress_area, animated_tasks)
    print updated_output

    # Update the tasks for next iteration
    tasks.each_with_index do |task, i|
      if tasks[i][:progress] < 100
        tasks[i] = {name: task[:name], progress: task[:progress] + 1}
      end
    end
  end
end

# Keep the demo running until interrupted
begin
  sleep
rescue Interrupt
  # Clean exit
  print CLEAR_SCREEN + RESET_CURSOR + SHOW_CURSOR
  puts "\n👋 Four Quadrant Demo Complete!"
  puts "   Layout calculated for #{terminal_width}×#{terminal_height} terminal"
  puts "   Widgets rendered in their respective quadrants"
  puts "   Ready for production use!"
ensure
  factory.stop_engine
end
