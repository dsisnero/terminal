require "./spec_helper"

class BorderProbeWidget
  include Terminal::Widget

  getter id : String

  def initialize(@id : String)
  end

  def handle(msg : Terminal::Msg::Any)
  end

  def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
    inner_width = {width - 2 - 2, 0}.max
    content_line = Array.new(inner_width) { Terminal::Cell.new('X') }
    build_bordered_cell_grid(width, height, 1, [content_line])
  end
end

describe "Widget border helpers" do
  it "draws borders with padding" do
    widget = BorderProbeWidget.new("probe")
    grid = widget.render(8, 4)

    grid.map(&.map(&.char).join).should eq([
      "┌──────┐",
      "│      │",
      "│ XXXX │",
      "└──────┘",
    ])
  end
end
