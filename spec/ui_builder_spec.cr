require "./spec_helper"

class SimpleWidget
  include Terminal::Widget

  getter id : String
  getter char : Char

  def initialize(@id : String, @char : Char)
  end

  def handle(msg : Terminal::Msg::Any); end

  def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
    Array.new(height) { Array.new(width) { Terminal::Cell.new(char) } }
  end
end

describe Terminal do
  it "builds application with layout builder" do
    app = Terminal.app(width: 20, height: 6) do |builder|
      builder.layout do |layout|
        layout.horizontal do
          layout.widget "left", Terminal::UI::Constraint.percent(50)
          layout.widget "right", Terminal::UI::Constraint.percent(50)
        end
      end

      builder.mount "left", SimpleWidget.new("left", 'L')
      builder.mount "right", SimpleWidget.new("right", 'R')
    end

    manager = app.widget_manager
    grid = manager.compose(20, 6)
    left_chars = grid.flat_map { |row| row[0, 10].map(&.char) }
    left_chars.uniq!
    right_chars = grid.flat_map { |row| row[10, 10].map(&.char) }
    right_chars.uniq!

    left_chars.flatten.compact.should contain('L')
    right_chars.flatten.compact.should contain('R')
  end

  it "raises when layout references unknown widget ids" do
    expect_raises(ArgumentError) do
      Terminal.app(width: 10, height: 4) do |builder|
        builder.layout do |layout|
          layout.widget "missing"
        end

        # no widget mounted for "missing"
      end
    end
  end

  it "raises when a widget id is mounted twice" do
    expect_raises(ArgumentError) do
      Terminal.app(width: 10, height: 4) do |builder|
        builder.text_box "logs" { }
        builder.text_box "logs" { }
      end
    end
  end

  it "raises when layout duplicates widget ids" do
    expect_raises(ArgumentError) do
      Terminal.app(width: 10, height: 4) do |builder|
        builder.layout do |layout|
          layout.vertical do
            layout.widget "one"
            layout.widget :one
          end
        end

        builder.text_box "one" { }
      end
    end
  end

  it "raises when layout omits mounted widgets" do
    expect_raises(ArgumentError) do
      Terminal.app(width: 10, height: 4) do |builder|
        builder.layout do |layout|
          layout.widget "primary"
        end

        builder.text_box "primary" { }
        builder.text_box "secondary" { }
      end
    end
  end
end
