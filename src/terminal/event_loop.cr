# File: src/terminal/event_loop.cr
# Purpose: Central async coordinator connecting all terminal subsystems.
# It wires together the InputProvider, Dispatcher, ScreenBuffer, DiffRenderer,
# WidgetManager, and CursorManager, running them concurrently with Channels.
# Implements a DI-friendly architecture for flexible testing and extension.
#
# Features:
# - Owns system channels and starts each subsystem in a fiber
# - Optional ticker (RenderRequest) for animations at a fixed interval
# - Graceful shutdown via WaitGroup with timeout and cursor restoration

require "../terminal/messages"
require "../terminal/input_provider"
require "../terminal/dispatcher"
require "../terminal/screen_buffer"
require "../terminal/diff_renderer"
require "../terminal/widget_manager"
require "../terminal/cursor_manager"
require "../terminal/wait_group"

module Terminal
  class EventLoop(T)
    # Type constraint in macro
    private def self.check_type
      {% begin %}
      {% unless T < Terminal::Widget %}
        {{ raise "Type parameter T must include Terminal::Widget" }}
      {% end %}
    {% end %}
    end

    @input_provider : Terminal::InputProvider? = nil
    @dispatcher : Dispatcher(T)? = nil
    @screen_buffer : ScreenBuffer? = nil
    @diff_renderer : DiffRenderer? = nil
    @widget_manager : Terminal::WidgetManager(T)? = nil
    @cursor_manager : CursorManager? = nil
    @main_chan : Channel(Msg::Any) = Channel(Msg::Any).new
    @diff_chan : Channel(Msg::Any) = Channel(Msg::Any).new
    @cursor_chan : Channel(Msg::Any) = Channel(Msg::Any).new
    @stop : Channel(Bool) = Channel(Bool).new(1)
    @done : Channel(Bool) = Channel(Bool).new(1)
    # Local WaitGroup implementation (see src/terminal/wait_group.cr)
    @wait_group = WaitGroup.new
    @verbose = false
    @event_fiber : Fiber? = nil
    @ticker_interval : Time::Span? = nil

    def initialize(
      @input_provider,
      @dispatcher : Dispatcher(T),
      @screen_buffer : ScreenBuffer,
      @diff_renderer : DiffRenderer,
      @widget_manager : Terminal::WidgetManager(T),
      @cursor_manager,
      @verbose = false,
      @ticker_interval : Time::Span? = nil,
    )
      @main_chan = Channel(Msg::Any).new
      @diff_chan = Channel(Msg::Any).new
      @cursor_chan = Channel(Msg::Any).new
      @stop = Channel(Bool).new(1)
      @done = Channel(Bool).new(1)
    end

    def start
      # Launch all subsystems
      puts "Starting input provider..." if @verbose
      @wait_group.add
      spawn do
        @input_provider.not_nil!.start(@main_chan)
        @wait_group.done
      end

      puts "Starting dispatcher..." if @verbose
      @wait_group.add
      spawn do
        @dispatcher.not_nil!.start(@main_chan, @diff_chan)
        @wait_group.done
      end

      puts "Starting screen buffer..." if @verbose
      @wait_group.add
      spawn do
        # Use the same channel for incoming ScreenUpdate and outgoing ScreenDiff to keep pipeline simple
        @screen_buffer.not_nil!.start(@diff_chan, @diff_chan)
        @wait_group.done
      end

      puts "Starting diff renderer..." if @verbose
      @wait_group.add
      spawn do
        @diff_renderer.not_nil!.start(@diff_chan)
        @wait_group.done
      end

      puts "Starting cursor manager..." if @verbose
      @wait_group.add
      spawn do
        @cursor_manager.not_nil!.start(@cursor_chan)
        @wait_group.done
      end

      # Start main event loop fiber
      puts "Starting main event loop..." if @verbose
      @wait_group.add
      @event_fiber = spawn do
        run
        @wait_group.done
      end

      # Optional ticker for animations
      if interval = @ticker_interval
        @wait_group.add
        spawn do
          begin
            loop do
              ::sleep(interval)
              @main_chan.send(Terminal::Msg::RenderRequest.new("tick", ""))
            end
          rescue
          ensure
            @wait_group.done
          end
        end
      end
    end

    # Stop components and wait for cleanup. Returns true if successful, false if timed out.
    def stop : Bool
      return false unless @event_fiber

      # Signal main loop to exit first
      @stop.send(true)

      # Send stop to all channels
      @main_chan.send(Terminal::Msg::Stop.new)
      @diff_chan.send(Terminal::Msg::Stop.new)
      @cursor_chan.send(Terminal::Msg::Stop.new)

      # Wait for all subsystem fibers to finish (with timeout)
      success = @wait_group.wait(Time::Span.new(seconds: 2))
      STDERR.puts "Warning: EventLoop stop timeout" unless success

      # Allow scheduler to run any remaining work; then clear handle
      if fiber = @event_fiber
        Fiber.yield
        @event_fiber = nil
      end

      success
    end

    private def run
      select
      when done = @stop.receive
        cleanup
        @done.send(true)
      end
    end

    private def cleanup
      # Try to ensure cursor is shown
      @cursor_chan.send(Terminal::Msg::CursorShow.new)
    rescue ex : Exception
      STDERR.puts "EventLoop cleanup error: #{ex.message}"
    end

    def main_channel : Channel(Msg::Any)
      @main_chan
    end

    def dispatch(msg : Msg::Any)
      @main_chan.send(msg)
    rescue
    end
  end
end
