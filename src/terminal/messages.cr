# File: src/terminal/messages.cr
# Purpose: Define immutable message structs used for actor communication.
# Each message is a simple struct. Channels in the system carry Msg::Any.
require "./cell"
module Terminal
module Msg
  # Alias for union-like usage — we use concrete types in channels throughout the codebase.
  alias Any = Stop | InputEvent | Command | ResizeEvent |
              ScreenUpdate | ScreenDiff | RenderRequest | RenderFrame |
              CursorMove | CursorHide | CursorShow | CursorPosition |
              WidgetEvent

  alias Payload = String | Array(Cell)

  struct Stop
    getter reason : String?

    def initialize(@reason : String? = nil); end
  end

  struct InputEvent
    getter char : Char
    getter time : Time::Span

    def initialize(@char : Char, @time : Time::Span); end
  end

  struct Command
    getter name : String
    getter payload : String?

    def initialize(@name : String, @payload : String? = nil); end
  end

  struct ResizeEvent
    getter cols : Int32
    getter rows : Int32

    def initialize(@cols : Int32, @rows : Int32); end
  end

  # Screen-level messages: either plain lines (Array(String)) or cells depending on pipeline stage.
  struct ScreenUpdate
    # content can be Array(String) or Array(Array(Cell)) depending on usage.
    getter content : Array(String) | Array(Array(Cell))

    def initialize(@content : Array); end
  end

  struct ScreenDiff
    # list of {row_index (0-based), payload}
    # payload: String (line) or Array(Cell) depending on pipeline

    getter changes : Array(Tuple(Int32, Payload))

    def initialize(@changes : Array(Tuple(Int32, Payload))); end
  end

  struct RenderRequest
    getter reason : String
    getter content : String

    def initialize(@reason : String, @content : String); end
  end

  struct RenderFrame
    getter seq : Int32
    getter content : String

    def initialize(@seq : Int32, @content : String); end
  end

  # Cursor control messages
  struct CursorMove
    getter row : Int32
    getter col : Int32

    def initialize(@row : Int32, @col : Int32); end
  end

  struct CursorHide; end

  struct CursorShow; end

  struct CursorPosition
    getter row : Int32
    getter col : Int32

    def initialize(@row : Int32, @col : Int32); end
  end

  # Widget-specific event wrapper
  struct WidgetEvent
    getter widget_id : String
    getter payload : Payload

    def initialize(@widget_id : String, @payload : Payload); end
  end
end
end