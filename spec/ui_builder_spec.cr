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
    app = Terminal.app(width: 20, height: 6) do |ui|
      ui.layout do |layout|
        layout.horizontal do
          layout.widget "left", Terminal::UI::Constraint.percent(50)
          layout.widget "right", Terminal::UI::Constraint.percent(50)
        end
      end

      ui.mount "left", SimpleWidget.new("left", 'L')
      ui.mount "right", SimpleWidget.new("right", 'R')
    end

    manager = app.widget_manager
    grid = manager.compose(20, 6)
    left_chars = grid.map { |row| row[0, 10].map(&.char) }.flatten.uniq
    right_chars = grid.map { |row| row[10, 10].map(&.char) }.flatten.uniq

    left_chars.flatten.compact.should contain('L')
    right_chars.flatten.compact.should contain('R')
  end
end
