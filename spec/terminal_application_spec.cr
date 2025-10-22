require "spec"
require "../src/terminal/messages"
require "../src/terminal/widget_manager"
require "../src/terminal/input_provider"
require "../src/terminal/event_loop"
require "../src/terminal/dispatcher"
require "../src/terminal/screen_buffer"
require "../src/terminal/diff_renderer"
require "../src/terminal/cursor_manager"
require "../src/terminal/service_provider"
require "../src/terminal/terminal_application"

module Terminal
  # Example widget for testing
  class TestWidget
    include Widget

    getter id : String
    @content : String

    def initialize(@id : String)
      @content = "test"
    end

    def handle(msg : Terminal::Msg::Any)
      case msg
      when Terminal::Msg::InputEvent
        @content += msg.char
      end
    end

    def render(width : Int32, height : Int32) : Array(Array(Cell))
      lines = [] of Array(Cell)
      height.times do |_|
        line = [] of Cell
        width.times do |j|
          char = j < @content.size ? @content[j] : ' '
          line << Cell.new(char)
        end
        lines << line
      end
      lines
    end

    # Implement required Measurable methods for test widget
    def calculate_min_size : Terminal::Geometry::Size
      Terminal::Geometry::Size.new([@content.size, 5].max, 1) # Content width or minimum 5, height 1
    end

    def calculate_max_size : Terminal::Geometry::Size
      Terminal::Geometry::Size.new([@content.size, 50].min, 10) # Reasonable bounds
    end
  end

  describe TerminalApplication do
    it "starts and stops with dummy input and IO::Memory" do
      io = IO::Memory.new
      input = DummyInputProvider.new("a")
      wm = WidgetManager(TestWidget).new([TestWidget.new("w1")])
      app = TerminalApplication(TestWidget).new(nil, io, input, wm, 10, 2)

      app.start
      sleep(Time::Span.new(nanoseconds: 100_000_000))
      app.stop

      # after stop, IO::Memory should contain some output sequences (escape codes)
      s = io.to_s
      s.should_not be_empty
    end
  end
end
