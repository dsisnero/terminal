# File: src/terminal/input_widget.cr
# Purpose: Input widget with styled prompt and input area

module Terminal
  class InputWidget
    include Terminal::Widget

    getter id : String
    property value : String
    property cursor_pos : Int32

    @prompt : String
    @prompt_bg : String
    @input_bg : String
    @max_length : Int32?
    @on_submit : Proc(String, Nil)?
    @on_change : Proc(String, Nil)?

    def initialize(
      @id : String,
      @prompt : String = "> ",
      @value : String = "",
      @prompt_bg : String = "blue",
      @input_bg : String = "default",
      @max_length : Int32? = nil,
    )
      @cursor_pos = @value.size
      @on_submit = nil
      @on_change = nil
    end

    def prompt(text : String, bg : String = @prompt_bg)
      @prompt = text
      @prompt_bg = bg
    end

    def on_submit(&block : String -> Nil)
      @on_submit = block
    end

    def on_change(&block : String -> Nil)
      @on_change = block
    end

    def clear
      @value = ""
      @cursor_pos = 0
    end

    def handle(msg : Terminal::Msg::Any)
      # Try navigation first
      unless handle_navigation(msg)
        case msg
        when Terminal::Msg::KeyPress
          handle_key(msg.key)
        when Terminal::Msg::InputEvent
          if msg.char.printable? || msg.char == ' '
            insert_char(msg.char)
          end
        end
      end
    end

    # Override navigation for input-specific behavior
    def handle_enter_key
      @on_submit.try(&.call(@value))
    end

    def handle_left_key
      @cursor_pos = [@cursor_pos - 1, 0].max
    end

    def handle_right_key
      @cursor_pos = [@cursor_pos + 1, @value.size].min
    end

    private def handle_key(key : String)
      case key
      when "backspace"
        if @cursor_pos > 0
          @value = @value[0...(@cursor_pos - 1)] + @value[@cursor_pos..]
          @cursor_pos -= 1
          @on_change.try(&.call(@value))
        end
      when "delete"
        if @cursor_pos < @value.size
          @value = @value[0...@cursor_pos] + @value[(@cursor_pos + 1)..]
          @on_change.try(&.call(@value))
        end
      when "home"
        @cursor_pos = 0
      when "end"
        @cursor_pos = @value.size
      end
    end

    private def insert_char(ch : Char)
      if max_len = @max_length
        return if @value.size >= max_len
      end

      @value = @value[0...@cursor_pos] + ch.to_s + @value[@cursor_pos..]
      @cursor_pos += 1
      @on_change.try(&.call(@value))
    end

    # Calculate minimum width needed for input
    def calculate_min_width : Int32
      # Prompt + reasonable input space
      prompt_width = text_width(@prompt) + 1        # prompt + space
      min_input_width = {@max_length || 50, 20}.min # At least 20 chars or max length

      prompt_width + min_input_width
    end

    # Calculate maximum width for input
    def calculate_max_width : Int32
      # Prompt + full input capacity
      prompt_width = text_width(@prompt) + 1
      max_input_width = {@max_length || 50, 50}.min # Cap at reasonable width

      prompt_width + max_input_width
    end

    # Input widgets are always single line
    def calculate_min_height : Int32
      1
    end

    def calculate_max_height : Int32
      1
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      actual_width = {width, 1}.max
      actual_height = {height, 1}.max
      result = Array.new(actual_height) { Array.new(actual_width) { Terminal::Cell.new(' ') } }

      line = result[0]

      # Render prompt
      x = 0
      @prompt.each_char do |ch|
        break if x >= actual_width
        line[x] = Terminal::Cell.new(ch, fg: "white", bg: @prompt_bg, bold: true)
        x += 1
      end

      # Render input value
      input_start = x
      @value.chars.each_with_index do |ch, i|
        break if x >= actual_width
        position = input_start + i
        is_cursor = (position == input_start + @cursor_pos)
        line[x] = Terminal::Cell.new(
          ch,
          fg: "white",
          bg: @input_bg,
          underline: is_cursor
        )
        x += 1
      end

      # Render cursor if at end
      if input_start + @cursor_pos == x && x < actual_width
        line[x] = Terminal::Cell.new(' ', bg: @input_bg, underline: true)
      end

      (input_start...actual_width).each do |idx|
        cell = line[idx]
        next unless cell.bg == "default"
        line[idx] = Terminal::Cell.new(cell.char, cell.fg, @input_bg, cell.bold, cell.underline)
      end

      result
    end

    # Implement required Measurable methods
    def calculate_min_size : Terminal::Geometry::Size
      # Input needs prompt + reasonable input space
      prompt_width = Terminal::TextMeasurement.text_width(@prompt)
      min_input_width = 10 # Minimum space for input
      min_width = prompt_width + min_input_width
      Terminal::Geometry::Size.new(min_width, 1) # Single line widget
    end

    def calculate_max_size : Terminal::Geometry::Size
      # Input should not be too wide
      prompt_width = Terminal::TextMeasurement.text_width(@prompt)
      max_input_width = @max_length || 50 # Use max_length or reasonable default
      max_width = prompt_width + max_input_width
      Terminal::Geometry::Size.new([max_width, 80].min, 1) # Single line widget
    end
  end
end
