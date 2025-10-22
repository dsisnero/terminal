require "spec"
require "../src/terminal/prelude"

module Terminal
  # Test widget implementation
  private class TestWidget
    include Widget

    getter id : String
    property content = ""

    def initialize(@id : String); end

    def handle(msg : Terminal::Msg::Any)
      case msg
      when Terminal::Msg::InputEvent
        @content += msg.char
      when Terminal::Msg::Command
        case msg.name
        when "clear"
          @content = ""
        end
      end
    end

    def render(width : Int32, height : Int32) : Array(Array(Cell))
      inner_width = inner_dimensions(width, height)[0]
      content_lines = wrap_content(@content, inner_width)
      create_bordered_grid(width, height, content_lines)
    end
  end

  describe WidgetManager do
    it "manages focus between multiple widgets" do
      w1 = TestWidget.new("w1")
      w2 = TestWidget.new("w2")
      w3 = TestWidget.new("w3")
      wm = WidgetManager(TestWidget).new([w1, w2, w3])

      # Initial focus should be on first widget
      wm.route_to_focused(Terminal::Msg::InputEvent.new('a', Time::Span.zero))
      w1.content.should eq "a"
      w2.content.should be_empty
      w3.content.should be_empty

      # Focus next widget
      wm.focus_next
      wm.route_to_focused(Terminal::Msg::InputEvent.new('b', Time::Span.zero))
      w1.content.should eq "a"
      w2.content.should eq "b"
      w3.content.should be_empty

      # Focus previous widget (back to first)
      wm.focus_prev
      wm.focus_prev # Need to focus twice to get back to first widget
      wm.route_to_focused(Terminal::Msg::InputEvent.new('c', Time::Span.zero))
      w1.content.should eq "a"
      w2.content.should eq "b" # Content should persist
      w3.content.should eq "c"
    end

    it "broadcasts commands to all widgets" do
      w1 = TestWidget.new("w1")
      w2 = TestWidget.new("w2")
      wm = WidgetManager(TestWidget).new([w1, w2])

      # Add some content
      wm.route_to_focused(Terminal::Msg::InputEvent.new('a', Time::Span.zero))
      wm.focus_next
      wm.route_to_focused(Terminal::Msg::InputEvent.new('b', Time::Span.zero))

      w1.content.should eq "a"
      w2.content.should eq "b"

      # Broadcast clear command
      wm.broadcast(Terminal::Msg::Command.new("clear"))

      w1.content.should be_empty
      w2.content.should be_empty
    end

    it "composes widget content into screen grid" do
      w = TestWidget.new("test")
      wm = WidgetManager(TestWidget).new([w])

      # Add single character content
      wm.route_to_focused(Terminal::Msg::InputEvent.new('x', Time::Span.zero))

      # Test 4x3 grid with single character
      grid = wm.compose(4, 3)
      lines = grid.map(&.map(&.char).join)

      puts "Single character output:"
      lines.each_with_index { |line, i| puts "Line #{i}: '#{line}'" }

      lines[0].should eq "----" # Top border
      lines[1].should eq "|x |" # Content with one space padding
      lines[2].should eq "----" # Bottom border
    end

    it "handles multi-line content in a larger grid" do
      w = TestWidget.new("test")
      wm = WidgetManager(TestWidget).new([w])

      # Add content that should wrap
      "Hello World".each_char do |ch|
        wm.route_to_focused(Terminal::Msg::InputEvent.new(ch, Time::Span.zero))
      end

      # Test in 6x5 grid - should show wrapped content
      grid = wm.compose(6, 5)
      lines = grid.map(&.map(&.char).join)

      puts "\nMulti-line content output:"
      lines.each_with_index { |line, i| puts "Line #{i}: '#{line}'" }

      # With a 6x5 grid (4 chars inner width) and "Hello World":
      lines[0].should eq "------" # Top border (width=6)
      lines[1].should eq "|Hell|" # First 4 chars
      lines[2].should eq "|o Wo|" # Next 4 chars
      lines[3].should eq "|rld |" # Last 3 chars + padding
      lines[4].should eq "------" # Bottom border
    end

    it "handles empty widget list gracefully" do
      wm = WidgetManager(TestWidget).new([] of TestWidget)

      # These should not raise
      wm.focus_next
      wm.focus_prev
      wm.route_to_focused(Terminal::Msg::InputEvent.new('x', Time::Span.zero))
      wm.broadcast(Terminal::Msg::Command.new("test"))

      # Empty composition should return empty grid
      wm.compose(1, 1).should be_empty
    end
  end
end
