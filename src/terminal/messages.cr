# File: src/terminal/messages.cr
# Purpose: Define immutable message structs used for actor communication.
#
# Contract:
# - All messages are simple, immutable structs.
# - Channels in the system carry Msg::Any (a union of all message types).
# - Clipboard: CopyToClipboard uses OSC 52 (handled by DiffRenderer)
# - Paste: PasteEvent is produced when bracketed paste mode is enabled.
require "./cell"

module Terminal
  module Msg
    # Alias for union-like usage — we use concrete types in channels throughout the codebase.
    alias Any = Stop | InputEvent | KeyPress | Command | ResizeEvent |
                ScreenUpdate | ScreenDiff | RenderRequest | RenderFrame |
                CursorMove | CursorHide | CursorShow | CursorPosition |
                WidgetEvent | PasteEvent | CopyToClipboard

    alias Payload = String | Array(Terminal::Cell)

    struct Stop
      getter reason : String?

      def initialize(@reason : String? = nil); end
    end

    struct InputEvent
      getter char : Char
      getter time : Time::Span

      def initialize(@char : Char, @time : Time::Span); end
    end

    struct KeyPress
      getter key : String

      def initialize(@key : String); end
    end

    struct Command
      getter name : String
      getter payload : String?

      def initialize(@name : String, @payload : String? = nil); end
    end

    # Paste event: emitted by RawInputProvider when bracketed paste is enabled
    # via ESC[?2004h and the terminal sends ESC[200~ <data> ESC[201~.
    struct PasteEvent
      getter content : String

      def initialize(@content : String); end
    end

    struct ResizeEvent
      getter cols : Int32
      getter rows : Int32

      def initialize(@cols : Int32, @rows : Int32); end
    end

    # Screen-level messages: either plain lines (Array(String)) or cells depending on pipeline stage.
    struct ScreenUpdate
      # content can be Array(String) or Array(Array(Terminal::Cell)) depending on usage.
      getter content : Array(String) | Array(Array(Terminal::Cell))

      def initialize(@content : Array); end
    end

    struct ScreenDiff
      # list of {row_index (0-based), payload}
      # payload: String (line) or Array(Terminal::Cell) depending on pipeline

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

    # Copy request: handled by DiffRenderer which emits OSC 52 sequences to copy
    # the provided text to the terminal clipboard (support varies by terminal).
    struct CopyToClipboard
      getter text : String

      def initialize(@text : String); end
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
