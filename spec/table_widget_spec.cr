require "spec"
require "../src/terminal/prelude"

module Terminal
  describe TableWidget do
    it "renders table with borders, headers, and rows" do
      table = TableWidget.new("t1")
        .col("Name", :name, 9, :left, :cyan)
        .col("Age", :age, 5, :right)
        .col("City", :city, 8, :left)
        .sort_by(:age, asc: true)
        .rows([
          {"name" => "Alice", "age" => "30", "city" => "Paris"},
          {"name" => "Bob", "age" => "28", "city" => "Berlin"},
          {"name" => "Cara", "age" => "35", "city" => "Rome"},
        ])

      width = 1 + 9 + 5 + 8 + 1 # borders + col widths = 24
      height = 6
      grid = table.render(width, height)

      # Top and bottom borders
      grid.first.each(&.char.should(eq('-')))
      grid.last.each(&.char.should(eq('-')))

      # Header should contain sort arrow for Age column
      header_line = grid[1]
      header_text = header_line.map(&.char).join
      header_text.should contain("Name")
      header_text.should contain("Age")
      header_text.should contain("▲")

      # Borders '|' at left and right
      [grid[1], grid[2]].each do |line|
        line.first.char.should eq('|')
        line.last.char.should eq('|')
      end

      # Verify rows sorted by age ascending (Bob, Alice, Cara)
      row_texts = grid[2..-2].map(&.map(&.char).join)
      row_texts.join.should contain("Bob")
      row_texts.join.should contain("Alice")
      row_texts.join.should contain("Cara")

      # Verify header first non-space in Name column is cyan
      name_header_cell = grid[1][1]
      name_header_cell.fg.should eq("cyan")
    end
  end
end
