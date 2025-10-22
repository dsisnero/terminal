#!/usr/bin/env crystal

require "../src/terminal"

def render_grid(grid : Array(Array(Terminal::Cell)))
  grid.each do |line|
    line.each do |cell|
      cell.to_ansi(STDOUT)
    end
    puts
  end
end

def main
  # Simple test data
  test_data = [
    {"name" => "Alice", "age" => "28", "city" => "NYC"},
    {"name" => "Bob", "age" => "35", "city" => "SF"},
    {"name" => "Carol", "age" => "42", "city" => "Chicago"},
  ]

  # Create a basic table without custom overrides
  table = Terminal::TableWidget.new("test")
    .col("Name", :name, 10, :left, :cyan)
    .col("Age", :age, 5, :right, :yellow)
    .col("City", :city, 10, :left, :green)
    .rows(test_data)

  puts "Basic Table Test:"
  puts "Width: 30, Height: 8"
  puts

  # Render the table
  grid = table.render(30, 8)
  render_grid(grid)

  puts
  puts "Debug info:"
  puts "Grid size: #{grid.size} rows"
  if grid.size > 0
    puts "First row size: #{grid[0].size} cells"
  end
end

main
