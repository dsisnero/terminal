require "./spec_helper"

describe Terminal::TextBoxWidget do
  it "renders bordered content with padding" do
    widget = Terminal::TextBoxWidget.new("txt", padding: 1)
    widget.set_text("Hello\nWorld")

    grid = widget.render(10, 6)
    lines = grid.map(&.map(&.char).join)

    lines.first.should eq("┌────────┐")
    lines.last.should eq("└────────┘")
    lines[2].should contain("Hello")
    lines[3].should contain("World")
  end

  it "scrolls through content with arrow keys" do
    widget = Terminal::TextBoxWidget.new("txt", auto_scroll: false)
    widget.set_text((1..10).map { |i| "Line #{i}" }.join("\n"))

    widget.render(16, 8) # establish layout metrics
    widget.handle(Terminal::Msg::KeyPress.new("down"))
    widget.scroll_offset.should eq(1)

    widget.handle(Terminal::Msg::KeyPress.new("page_down"))
    widget.scroll_offset.should be > 1

    widget.handle(Terminal::Msg::KeyPress.new("home"))
    widget.scroll_offset.should eq(0)
  end

  it "auto-scrolls to bottom when content grows" do
    widget = Terminal::TextBoxWidget.new("txt", auto_scroll: true)
    widget.set_text((1..5).map { |i| "Item #{i}" }.join("\n"))
    widget.render(12, 6)

    max_offset = widget.scroll_offset
    widget.add_line("Item 6")
    widget.render(12, 6)

    widget.scroll_offset.should be >= max_offset
  end
end
