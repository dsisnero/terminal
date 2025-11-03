require "./spec_helper"

describe Terminal::DropdownWidget do
  describe "#initialize" do
    it "creates dropdown with options" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["Option 1", "Option 2", "Option 3"]
      )
      dropdown.id.should eq("dropdown1")
      dropdown.options.size.should eq(3)
      dropdown.selected_index.should eq(0)
      dropdown.expanded.should be_false
    end

    it "accepts custom prompt" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B"],
        prompt: "Choose:"
      )
      grid = dropdown.render(30, 5)
      # Prompt line should contain custom prompt
      first_line_text = grid[0].map(&.char).join
      first_line_text.should contain("Choose:")
    end
  end

  describe "#handle" do
    it "toggles expanded on enter" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B", "C"]
      )
      dropdown.expanded.should be_false

      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      dropdown.expanded.should be_true

      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      dropdown.expanded.should be_false
    end

    it "navigates down through options when expanded" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B", "C"]
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand
      dropdown.selected_index.should eq(0)

      dropdown.handle(Terminal::Msg::KeyPress.new("down"))
      dropdown.selected_index.should eq(1)

      dropdown.handle(Terminal::Msg::KeyPress.new("down"))
      dropdown.selected_index.should eq(2)

      dropdown.handle(Terminal::Msg::KeyPress.new("down"))
      dropdown.selected_index.should eq(2) # Can't go past last
    end

    it "navigates up through options when expanded" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B", "C"],
        selected_index: 2
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand

      dropdown.handle(Terminal::Msg::KeyPress.new("up"))
      dropdown.selected_index.should eq(1)

      dropdown.handle(Terminal::Msg::KeyPress.new("up"))
      dropdown.selected_index.should eq(0)

      dropdown.handle(Terminal::Msg::KeyPress.new("up"))
      dropdown.selected_index.should eq(0) # Can't go below 0
    end

    it "collapses on escape" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B"]
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand
      dropdown.expanded.should be_true

      dropdown.handle(Terminal::Msg::KeyPress.new("escape"))
      dropdown.expanded.should be_false
    end

    it "filters options by typing" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["Apple", "Banana", "Cherry", "Apricot"]
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand

      dropdown.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))
      dropdown.handle(Terminal::Msg::InputEvent.new('p', Time::Span::ZERO))
      dropdown.filter.should eq("ap")

      # Rendering should show filtered results
      grid = dropdown.render(30, 10)
      # Should show Apple and Apricot, not Banana/Cherry
      lines = grid.map(&.map(&.char).join)
      lines.any?(&.includes?("Apple")).should be_true
      lines.any?(&.includes?("Apricot")).should be_true
      lines.any?(&.includes?("Banana")).should be_false
      lines.any?(&.includes?("Cherry")).should be_false
    end

    it "clamps selection to filtered options" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["Apple", "Banana", "Cherry"],
        selected_index: 2
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      dropdown.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))

      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))

      dropdown.expanded.should be_false
      dropdown.selected_index.should eq(0)
      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      grid = dropdown.render(30, 10)
      lines = grid.map(&.map(&.char).join)
      lines.first.should contain("Apple")
    end

    it "navigates filtered list using arrow keys" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["Alpha", "Beta", "Gamma", "Delta"],
        selected_index: 1
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      dropdown.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))

      dropdown.handle(Terminal::Msg::KeyPress.new("down"))
      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))

      dropdown.expanded.should be_false
      dropdown.selected_index.should eq(dropdown.options.index("Gamma"))
    end

    it "calls on_select callback when selecting" do
      selected_value = nil
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B", "C"]
      )
      dropdown.on_select { |val| selected_value = val }

      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand
      dropdown.handle(Terminal::Msg::KeyPress.new("down"))  # Select B
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Confirm

      selected_value.should eq("B")
      dropdown.expanded.should be_false
    end

    it "clears filter after confirming selection" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["Alpha", "Beta", "Gamma"]
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      dropdown.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))
      dropdown.filter.should eq("a")

      dropdown.handle(Terminal::Msg::KeyPress.new("enter"))
      dropdown.filter.should eq("")
    end
  end

  describe "#render" do
    it "renders prompt line in collapsed state" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["Option 1", "Option 2"],
        prompt: "Select:"
      )
      grid = dropdown.render(40, 5)

      # Widget now uses optimal height (1 when collapsed)
      grid.size.should eq(1)
      first_line = grid[0].map(&.char).join
      first_line.should contain("Select:")
      first_line.should contain("Option 1")
      first_line.should contain("▼")
    end

    it "renders options when expanded" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B", "C"]
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand

      grid = dropdown.render(30, 10)

      # Should have prompt + 3 options (widget uses optimal height)
      grid.size.should eq(4) # 1 prompt + 3 options

      # Check that options appear
      lines_text = grid.map(&.map(&.char).join)
      lines_text.any?(&.includes?("A")).should be_true
      lines_text.any?(&.includes?("B")).should be_true
      lines_text.any?(&.includes?("C")).should be_true
    end

    it "highlights selected option" do
      dropdown = Terminal::DropdownWidget.new(
        id: "dropdown1",
        options: ["A", "B", "C"],
        selected_index: 1
      )
      dropdown.handle(Terminal::Msg::KeyPress.new("enter")) # Expand

      grid = dropdown.render(30, 10)

      # Check for selection marker
      lines_text = grid.map(&.map(&.char).join)
      lines_text.any?(&.includes?("> B")).should be_true
    end
  end
end
