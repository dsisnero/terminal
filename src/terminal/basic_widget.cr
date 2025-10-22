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
      if height == 1 # Single line mode - no borders
        [Array.new(width) { |i| Terminal::Cell.new(@content[i]? || ' ') }]
      else # Normal bordered mode
        inner_width, inner_height = inner_dimensions(width, height)
        content_lines = wrap_words(@content, inner_width, inner_height)
        create_full_grid(width, height, content_lines)
      end
    end
  end
end
