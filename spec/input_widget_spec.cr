require "./spec_helper"

describe Terminal::InputWidget do
  describe "#initialize" do
    it "creates input with default values" do
      input = Terminal::InputWidget.new(id: "input1")
      input.id.should eq("input1")
      input.value.should eq("")
      input.cursor_pos.should eq(0)
    end

    it "creates input with initial value" do
      input = Terminal::InputWidget.new(
        id: "input1",
        value: "hello"
      )
      input.value.should eq("hello")
      input.cursor_pos.should eq(5)
    end

    it "accepts custom prompt and backgrounds" do
      input = Terminal::InputWidget.new(
        id: "input1",
        prompt: "Name: ",
        prompt_bg: "green",
        input_bg: "yellow"
      )
      grid = input.render(40, 1)
      # Visual inspection: cells should have appropriate backgrounds
    end
  end

  describe "#handle" do
    it "inserts characters at cursor position" do
      input = Terminal::InputWidget.new(id: "input1")

      input.handle(Terminal::Msg::InputEvent.new('h', Time::Span::ZERO))
      input.handle(Terminal::Msg::InputEvent.new('i', Time::Span::ZERO))

      input.value.should eq("hi")
      input.cursor_pos.should eq(2)
    end

    it "handles backspace to delete character before cursor" do
      input = Terminal::InputWidget.new(id: "input1", value: "hello")
      input.cursor_pos = 5

      input.handle(Terminal::Msg::KeyPress.new("backspace"))
      input.value.should eq("hell")
      input.cursor_pos.should eq(4)

      input.handle(Terminal::Msg::KeyPress.new("backspace"))
      input.value.should eq("hel")
      input.cursor_pos.should eq(3)
    end

    it "handles delete to remove character at cursor" do
      input = Terminal::InputWidget.new(id: "input1", value: "hello")
      input.cursor_pos = 2

      input.handle(Terminal::Msg::KeyPress.new("delete"))
      input.value.should eq("helo")
      input.cursor_pos.should eq(2)
    end

    it "moves cursor left and right" do
      input = Terminal::InputWidget.new(id: "input1", value: "hello")
      input.cursor_pos = 5

      input.handle(Terminal::Msg::KeyPress.new("left"))
      input.cursor_pos.should eq(4)

      input.handle(Terminal::Msg::KeyPress.new("left"))
      input.cursor_pos.should eq(3)

      input.handle(Terminal::Msg::KeyPress.new("right"))
      input.cursor_pos.should eq(4)
    end

    it "handles home and end keys" do
      input = Terminal::InputWidget.new(id: "input1", value: "hello")
      input.cursor_pos = 2

      input.handle(Terminal::Msg::KeyPress.new("home"))
      input.cursor_pos.should eq(0)

      input.handle(Terminal::Msg::KeyPress.new("end"))
      input.cursor_pos.should eq(5)
    end

    it "respects max_length constraint" do
      input = Terminal::InputWidget.new(
        id: "input1",
        max_length: 5
      )

      "hello world".each_char do |ch|
        input.handle(Terminal::Msg::InputEvent.new(ch, Time::Span::ZERO))
      end

      input.value.should eq("hello")
      input.value.size.should eq(5)
    end

    it "calls on_submit callback on enter" do
      submitted_value = nil
      input = Terminal::InputWidget.new(id: "input1", value: "test")
      input.on_submit { |val| submitted_value = val }

      input.handle(Terminal::Msg::KeyPress.new("enter"))

      submitted_value.should eq("test")
    end

    it "calls on_change callback on value modification" do
      change_count = 0
      last_value = ""
      input = Terminal::InputWidget.new(id: "input1")
      input.on_change do |val|
        change_count += 1
        last_value = val
      end

      input.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))
      change_count.should eq(1)
      last_value.should eq("a")

      input.handle(Terminal::Msg::InputEvent.new('b', Time::Span::ZERO))
      change_count.should eq(2)
      last_value.should eq("ab")

      input.handle(Terminal::Msg::KeyPress.new("backspace"))
      change_count.should eq(3)
      last_value.should eq("a")
    end
  end

  describe "#render" do
    it "renders prompt with distinct background" do
      input = Terminal::InputWidget.new(
        id: "input1",
        prompt: "Name: ",
        prompt_bg: "blue"
      )
      grid = input.render(30, 1)

      grid.size.should eq(1)
      # Widget now uses optimal width instead of requested width
      grid[0].size.should eq(input.calculate_min_width)

      # First few cells should have blue background for prompt
      grid[0][0].bg.should eq("blue")
      grid[0][1].bg.should eq("blue")
    end

    it "renders input value after prompt" do
      input = Terminal::InputWidget.new(
        id: "input1",
        prompt: "> ",
        value: "hello"
      )
      grid = input.render(30, 1)

      line_text = grid[0].map(&.char).join
      line_text.should contain(">")
      line_text.should contain("hello")
    end

    it "shows cursor position with underline" do
      input = Terminal::InputWidget.new(
        id: "input1",
        prompt: "> ",
        value: "hi"
      )
      input.cursor_pos = 1

      grid = input.render(30, 1)

      # Character at cursor should be underlined
      # Prompt is 2 chars, so cursor at position 1 is at index 2+1=3
      grid[0][3].underline.should be_true
    end
  end
end
