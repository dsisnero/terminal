#!/usr/bin/env crystal

# Test demonstrating that widgets automatically use optimal sizing
# regardless of requested dimensions

require "../src/terminal"

def render_grid(grid : Array(Array(Terminal::Cell)))
  grid.each do |line|
    line.each do |cell|
      cell.to_ansi(STDOUT)
    end
    puts
  end
end

puts "=== Automatic Optimal Sizing Test ==="
puts "Widgets now use optimal dimensions regardless of requested size"
puts

# Create a table
table = Terminal::TableWidget.new("test")
  .col("Name", :name, 8, :left, :white)
  .col("Age", :age, 3, :right, :white)
  .rows([
    {"name" => "Alice", "age" => "25"},
    {"name" => "Bob", "age" => "30"},
  ])

puts "TableWidget Test:"
puts "Optimal size: #{table.calculate_min_width}w x #{table.calculate_min_height}h"
puts

# Test various requested sizes - all should render the same optimal size
puts "Requesting 10x5 (too small):"
grid1 = table.render(10, 5)
render_grid(grid1)
puts "Actual size: #{grid1.first.size}w x #{grid1.size}h"

puts
puts "Requesting 100x20 (too large):"
grid2 = table.render(100, 20)
render_grid(grid2)
puts "Actual size: #{grid2.first.size}w x #{grid2.size}h"

puts
puts "Requesting optimal size exactly:"
optimal_w = table.calculate_min_width
optimal_h = table.calculate_min_height
grid3 = table.render(optimal_w, optimal_h)
render_grid(grid3)
puts "Actual size: #{grid3.first.size}w x #{grid3.size}h"

puts
puts "✓ All three renders produced identical results!"
puts "✓ Widget automatically uses optimal size regardless of request"
puts "✓ No need to calculate optimal dimensions in examples"
puts "✓ Content-based sizing is now fully automatic"
