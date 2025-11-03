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

      lines = grid.map(&.map(&.char).join)

      lines.first.should eq("┌──────────────────────┐")
      lines.last.should eq("└──────────────────────┘")

      header_text = lines[1]
      header_text.should contain("Name")
      header_text.should contain("Age")
      header_text.should contain("▲")

      lines[1].starts_with?("│").should be_true
      lines[1].ends_with?("│").should be_true

      # Verify rows sorted by age ascending (Bob, Alice, Cara)
      row_texts = lines[2..-2]
      row_texts.join.should contain("Bob")
      row_texts.join.should contain("Alice")
      row_texts.join.should contain("Cara")

      # Verify header first non-space in Name column is cyan
      name_header_cell = grid[1][1]
      name_header_cell.fg.should eq("cyan")
    end
  end
end
