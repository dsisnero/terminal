module Terminal
  class BasicWidget
    include Terminal::Widget
    getter id : String
    @content : String

    def initialize(@id : String, @content : String = "Hello")
    end

    def handle(msg : Terminal::Msg::Any)
      case msg
      when Terminal::Msg::InputEvent
        @content += msg.char
      when Terminal::Msg::Command
        if msg.name == "clear"
          @content = ""
        end
      end
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      return [Array.new(width) { |i| Terminal::Cell.new(@content[i]? || ' ') }] if height <= 1

      inner_width, inner_height = inner_dimensions(width, height)
      text_lines = wrap_words(@content, inner_width, inner_height)
      formatted_lines = text_lines.map do |line|
        Array.new(line.size) { |idx| Terminal::Cell.new(line[idx]) }
      end

      build_bordered_cell_grid(width, height, 0, formatted_lines)
    end

    # Implement required Measurable methods
    def calculate_min_size : Terminal::Geometry::Size
      # Minimum size is content length + border (if applicable)
      content_width = Terminal::TextMeasurement.text_width(@content)
      Terminal::Geometry::Size.new([content_width + 2, 10].max, 3) # Min width for content + borders, min height 3
    end

    def calculate_max_size : Terminal::Geometry::Size
      # Maximum size is reasonable bounds
      content_width = Terminal::TextMeasurement.text_width(@content)
      Terminal::Geometry::Size.new([content_width + 2, 80].min, 20) # Max reasonable size
    end
  end
end
