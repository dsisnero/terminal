# File: src/terminal/event_loop.cr
# Purpose: Central async coordinator connecting all terminal subsystems.
# It wires together the InputProvider, Dispatcher, ScreenBuffer, DiffRenderer,
# WidgetManager, and CursorManager, running them concurrently with Channels.
# Implements a DI-friendly architecture for flexible testing and extension.

require "../terminal/messages"
require "../terminal/input_provider"
require "../terminal/dispatcher"
require "../terminal/screen_buffer"
require "../terminal/diff_renderer"
require "../terminal/widget_manager"
require "../terminal/cursor_manager"

class EventLoop
  def initialize(
    @input_provider : InputProvider,
    @dispatcher : Dispatcher,
    @screen_buffer : ScreenBuffer,
    @diff_renderer : DiffRenderer,
    @widget_manager : WidgetManager,
    @cursor_manager : CursorManager,
  )
    @main_chan = Channel(Terminal::Msg::Any).new
    @diff_chan = Channel(Terminal::Msg::Any).new
    @cursor_chan = Channel(Terminal::Msg::Any).new
    @stop = Channel(Bool).new(1)
  end

  def start
    # Launch all subsystems
    @input_provider.start(@main_chan)
    @dispatcher.start(@main_chan, @diff_chan)
    @screen_buffer.start(@diff_chan, @main_chan)
    @diff_renderer.start(@diff_chan, @cursor_chan)
    @cursor_manager.start(@cursor_chan)

    spawn do
      run
    end
  end

  def stop
    broadcast_stop(@main_chan)
    broadcast_stop(@diff_chan)
    broadcast_stop(@cursor_chan)
    @stop.send(true)
  end

  private def broadcast_stop(chan : Channel(Terminal::Msg::Any))
    spawn { chan.send(Terminal::Msg::Stop.new) }
  end

  private def run
    select
    when done = @stop.receive
      cleanup
    end
  end

  private def cleanup
    @cursor_manager.send(Terminal::Msg::Stop.new)
  rescue ex : Exception
    STDERR.puts "EventLoop cleanup error: #{ex.message}"
  end
end