require "spec"
require "../src/terminal/prelude"

module Terminal
  # Helper class to expose protected helper methods for testing
  class HelperWidget
    include Widget

    def id : String
      "helper"
    end

    def handle(msg); end

    def render(width : Int32, height : Int32) : Array(Array(Cell))
      # return an empty grid of given size
      lines = [] of Array(Cell)
      height.times do
        row = [] of Cell
        width.times { row << Cell.new(' ') }
        lines << row
      end
      lines
    end

    def call_wrap_words(content, inner_width, inner_height = 0)
      wrap_words(content, inner_width, inner_height)
    end

    def call_truncate(s, width)
      truncate_with_ellipsis(s, width)
    end

    def call_align(text, width, align)
      align_text_in_line(text, width, align)
    end

    def call_pad(s, width)
      pad_string(s, width)
    end

    def call_center(text, width)
      center_text_in_line(text, width)
    end

    def call_create_full_grid(width, height, content_lines)
      create_full_grid(width, height, content_lines)
    end

    # Implement required Measurable methods for test helper
    def calculate_min_size : Terminal::Geometry::Size
      Terminal::Geometry::Size.new(1, 1) # Minimal test widget
    end

    def calculate_max_size : Terminal::Geometry::Size
      Terminal::Geometry::Size.new(100, 100) # Reasonable test bounds
    end
  end

  describe Widget do
    it "wraps words without breaking small words" do
      h = HelperWidget.new
      lines = h.call_wrap_words("Hello World", 5)
      lines.should eq ["Hello", "World"]
    end

    it "respects inner_height when provided" do
      h = HelperWidget.new
      lines = h.call_wrap_words("Hello big world", 5, 2)
      # Should only return up to 2 lines
      lines.size.should eq 2
      lines[0].should eq "Hello"
    end

    it "truncates with ellipsis when needed" do
      h = HelperWidget.new
      h.call_truncate("abcdefg", 5).should eq "ab..."
      h.call_truncate("abc", 3).should eq "abc"
      h.call_truncate("abcd", 3).should eq "abc"
    end

    it "aligns text left/right/center" do
      h = HelperWidget.new
      h.call_align("hi", 6, :left).should eq "hi    "
      h.call_align("hi", 6, :right).should eq "    hi"
      h.call_align("hi", 6, :center).should eq "  hi  "
    end

    it "pads strings correctly and centers" do
      h = HelperWidget.new
      h.call_pad("ab", 5).should eq "ab   "
      h.call_center("xy", 5).should eq " xy  "
    end

    it "creates a full bordered grid from content lines" do
      h = HelperWidget.new
      grid = h.call_create_full_grid(6, 4, ["ABCD", "EFGH"]) # inner 4x2
      lines = grid.map(&.map(&.char).join)
      lines[0].should eq "------"
      lines[1].should eq "|ABCD|"
      lines[2].should eq "|EFGH|"
      lines[3].should eq "------"
    end
  end
end
