require "spec"
require "../src/terminal/geometry"

describe Terminal::TextMeasurement do
  describe "#text_width" do
    it "calculates width of plain text" do
      Terminal::TextMeasurement.text_width("Hello").should eq(5)
    end

    it "ignores ANSI escape sequences" do
      text_with_ansi = "\e[31mHello\e[0m"
      Terminal::TextMeasurement.text_width(text_with_ansi).should eq(5)
    end

    it "handles empty string" do
      Terminal::TextMeasurement.text_width("").should eq(0)
    end

    it "handles complex ANSI sequences" do
      text = "\e[1;31;40mBold Red on Black\e[0m"
      Terminal::TextMeasurement.text_width(text).should eq(17)
    end
  end

  describe "#max_text_width" do
    it "finds maximum width from array" do
      texts = ["short", "medium text", "very long text here"]
      Terminal::TextMeasurement.max_text_width(texts).should eq(19)
    end

    it "handles empty array" do
      Terminal::TextMeasurement.max_text_width([] of String).should eq(0)
    end

    it "handles array with ANSI sequences" do
      texts = ["\e[31mRed\e[0m", "\e[32mLonger green text\e[0m"]
      Terminal::TextMeasurement.max_text_width(texts).should eq(17)
    end
  end

  describe "#wrap_text" do
    it "wraps text at word boundaries" do
      text = "This is a long line that needs wrapping"
      result = Terminal::TextMeasurement.wrap_text(text, 20)

      result.should eq(["This is a long line", "that needs wrapping"])
    end

    it "handles text that fits on one line" do
      text = "Short text"
      result = Terminal::TextMeasurement.wrap_text(text, 20)

      result.should eq(["Short text"])
    end

    it "handles zero width" do
      text = "Any text"
      result = Terminal::TextMeasurement.wrap_text(text, 0)

      result.should eq(["Any text"])
    end

    it "handles single long word" do
      text = "verylongwordthatdoesntfit"
      result = Terminal::TextMeasurement.wrap_text(text, 10)

      result.should eq(["verylongwordthatdoesntfit"])
    end

    it "handles empty string" do
      result = Terminal::TextMeasurement.wrap_text("", 10)
      result.should eq([""])
    end
  end

  describe "#truncate_text" do
    it "truncates long text with ellipsis" do
      text = "This is a very long text that should be truncated"
      result = Terminal::TextMeasurement.truncate_text(text, 20)

      result.should eq("This is a very lo...")
      Terminal::TextMeasurement.text_width(result).should eq(20)
    end

    it "returns original text if it fits" do
      text = "Short text"
      result = Terminal::TextMeasurement.truncate_text(text, 20)

      result.should eq("Short text")
    end

    it "handles width smaller than ellipsis" do
      text = "Long text"
      result = Terminal::TextMeasurement.truncate_text(text, 2)

      result.should eq("...")
    end

    it "handles custom ellipsis" do
      text = "Long text here"
      result = Terminal::TextMeasurement.truncate_text(text, 8, ">>")

      result.should eq("Long t>>")
    end
  end

  describe "#center_text" do
    it "centers text within width" do
      text = "Hello"
      result = Terminal::TextMeasurement.center_text(text, 11)

      result.should eq("   Hello   ")
    end

    it "handles odd padding" do
      text = "Hi"
      result = Terminal::TextMeasurement.center_text(text, 7)

      result.should eq("  Hi   ")
    end

    it "returns original text if width is too small" do
      text = "Long text"
      result = Terminal::TextMeasurement.center_text(text, 5)

      result.should eq("Long text")
    end

    it "handles custom padding character" do
      text = "Test"
      result = Terminal::TextMeasurement.center_text(text, 10, '*')

      result.should eq("***Test***")
    end
  end

  describe "#align_text" do
    it "aligns text left (default)" do
      text = "Hello"
      result = Terminal::TextMeasurement.align_text(text, 10)

      result.should eq("Hello     ")
    end

    it "aligns text right" do
      text = "Hello"
      result = Terminal::TextMeasurement.align_text(text, 10, :right)

      result.should eq("     Hello")
    end

    it "centers text" do
      text = "Hello"
      result = Terminal::TextMeasurement.align_text(text, 11, :center)

      result.should eq("   Hello   ")
    end

    it "handles unknown alignment as left" do
      text = "Hello"
      result = Terminal::TextMeasurement.align_text(text, 10, :unknown)

      result.should eq("Hello     ")
    end

    it "returns original text if width is too small" do
      text = "Long text"
      result = Terminal::TextMeasurement.align_text(text, 5, :right)

      result.should eq("Long text")
    end

    it "handles custom padding character" do
      text = "Test"
      result = Terminal::TextMeasurement.align_text(text, 8, :right, '*')

      result.should eq("****Test")
    end
  end
end
