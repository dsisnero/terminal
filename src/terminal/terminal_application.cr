# File: src/terminal/terminal_application.cr
require "./prelude"

module Terminal
  # Generic TerminalApplication that can work with any widget type T that implements Widget
  class TerminalApplication(T)
    private def self.check_type
      {% begin %}
        {% unless T < Terminal::Widget %}
          {{ raise "Type parameter T must include Terminal::Widget" }}
        {% end %}
      {% end %}
    end

    # Create a TerminalApplication with sensible defaults. You can provide:
    # - service_provider: a ServiceProvider or Container-like object to register/resolve services
    # - io: IO to render to (defaults to STDOUT)
    # - input_provider: InputProvider implementation (defaults to ConsoleInputProvider)
    # - widget_manager: WidgetManager instance (defaults to a WidgetManager with no widgets)
    # - width/height: initial terminal size
    @input_provider : InputProvider
    @widget_manager : WidgetManager(T)
    @service_provider : ServiceProvider
    @event_loop : EventLoop(T)
    @diff_renderer : DiffRenderer
    @cursor_manager : CursorManager
    @screen_buffer : ScreenBuffer
    @dispatcher : Dispatcher(T)

    # Channels are owned/wired by EventLoop; do not create separate ones here

    getter widget_manager

    def initialize(service_provider : ServiceProvider? = nil, @io : IO = STDOUT, input_provider : InputProvider? = nil, widget_manager : WidgetManager(T)? = nil, @width : Int32 = 80, @height : Int32 = 24)
      @service_provider = service_provider || ServiceProvider.new
      # prefer raw input provider by default if available
      @input_provider = input_provider || InputProvider.default
      @widget_manager = widget_manager || WidgetManager(T).new([] of T)

      # compose subsystems; channels will be provided by EventLoop on start
      use_alt_screen = @io.responds_to?(:tty?) ? @io.tty? : false
      @diff_renderer = DiffRenderer.new(@io, use_alternate_screen: use_alt_screen)
      @cursor_manager = CursorManager.new(@io)
      @screen_buffer = ScreenBuffer.new
      @dispatcher = Dispatcher(T).new(@widget_manager, @width, @height)
      # buffer channel will be provided when starting the event loop

      # EventLoop expects its own channels; to keep wiring consistent we provide components
      # that will read/write to the channels EventLoop creates internally. Simpler: pass
      # the components and let EventLoop create channels it needs. We'll set channels on
      # the subcomponents to the ones we created above by starting EventLoop and letting
      # it wire channels on start.
      @event_loop = EventLoop(T).new(@input_provider, @dispatcher, @screen_buffer, @diff_renderer, @widget_manager, @cursor_manager)
    end

    # Start the application event loop
    def start
      # Start the event loop; it will handle initial rendering as it receives events
      @event_loop.start
    end

    # Stop the application and ensure clean shutdown
    def stop
      # Stop event loop and wait for cleanup with timeout
      unless @event_loop.stop
        STDERR.puts "Warning: application stop timeout"
      end
    end

    # Expose service provider for registration/resolve convenience
    def service_provider : ServiceProvider
      @service_provider
    end

    def message_channel : Channel(Terminal::Msg::Any)
      @event_loop.main_channel
    end

    def dispatch(msg : Terminal::Msg::Any)
      @event_loop.dispatch(msg)
    end
  end
end
