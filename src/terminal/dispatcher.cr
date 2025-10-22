# File: src/terminal/dispatcher.cr
# Purpose: Dispatcher actor that listens on the system channel and routes input/commands
# to the widget manager, composes frames and sends ScreenUpdate messages to the ScreenBuffer.
#
# Expected WidgetManager API (duck-typed):
# - route_to_focused(msg : Msg::Any)
# - broadcast(msg : Msg::Any)
# - compose(width : Int32, height : Int32) -> Array(String)  # or Array(Array(Terminal::Cell)) depending on pipeline

require "time"
require "../terminal/messages"

module Terminal
  class Dispatcher(T)
    private def self.check_type
      {% begin %}
      {% unless T < Terminal::Widget %}
        {{ raise "Type parameter T must include Terminal::Widget" }}
      {% end %}
    {% end %}
    end

    # widget_manager: object responding to route_to_focused, broadcast, compose
    def initialize(@widget_manager : WidgetManager(T), @width : Int32 = 80, @height : Int32 = 24)
      @buffer_chan = nil
    end

    # Attach or replace the buffer channel for screen updates
    def set_buffer_channel(channel : Channel(Terminal::Msg::Any))
      @buffer_chan = channel
    end

    # start listening on system_chan (Msg::Any) and optional buffer channel for screen updates
    def start(system_chan : Channel(Terminal::Msg::Any), buffer_chan : Channel(Terminal::Msg::Any)? = nil)
      # if a buffer_chan is provided override the configured @buffer_chan
      @buffer_chan = buffer_chan if buffer_chan
      spawn do
        begin
          loop do
            msg = system_chan.receive
            case msg
            when Terminal::Msg::InputEvent
              # route input to focused widget
              begin
                @widget_manager.route_to_focused(msg)
              rescue ex
                # If widget_manager raises, log and continue; ensure system remains stable
                STDERR.puts "Dispatcher: widget_manager.route_to_focused error: #{ex.message}"
              end

              # compose and push ScreenUpdate
              begin
                frame = @widget_manager.compose(@width, @height)
                @buffer_chan.not_nil!.send(Terminal::Msg::ScreenUpdate.new(frame))
              rescue ex
                STDERR.puts "Dispatcher: compose/send error: #{ex.message}"
              end
            when Terminal::Msg::Command
              case msg.name
              when "focus_next"
                begin
                  @widget_manager.focus_next
                  frame = @widget_manager.compose(@width, @height)
                  @buffer_chan.not_nil!.send(Terminal::Msg::ScreenUpdate.new(frame))
                rescue ex
                  STDERR.puts "Dispatcher: focus_next error: #{ex.message}"
                end
              when "focus_prev"
                begin
                  @widget_manager.focus_prev
                  frame = @widget_manager.compose(@width, @height)
                  @buffer_chan.not_nil!.send(Terminal::Msg::ScreenUpdate.new(frame))
                rescue ex
                  STDERR.puts "Dispatcher: focus_prev error: #{ex.message}"
                end
              else
                # broadcast command to widgets
                begin
                  @widget_manager.broadcast(msg)
                  frame = @widget_manager.compose(@width, @height)
                  @buffer_chan.not_nil!.send(Terminal::Msg::ScreenUpdate.new(frame))
                rescue ex
                  STDERR.puts "Dispatcher: command broadcast error: #{ex.message}"
                end
              end
            when Terminal::Msg::RenderRequest
              # periodic render tick for animations/spinners
              begin
                @widget_manager.broadcast(msg)
                frame = @widget_manager.compose(@width, @height)
                @buffer_chan.not_nil!.send(Terminal::Msg::ScreenUpdate.new(frame))
              rescue ex
                STDERR.puts "Dispatcher: render request error: #{ex.message}"
              end
            when Terminal::Msg::ResizeEvent
              # update width/height and request a recompose
              @width = msg.cols
              @height = msg.rows
              begin
                frame = @widget_manager.compose(@width, @height)
                @buffer_chan.not_nil!.send(Terminal::Msg::ScreenUpdate.new(frame))
              rescue ex
                STDERR.puts "Dispatcher: resize compose error: #{ex.message}"
              end
            when Terminal::Msg::Stop
              # forward stop to buffer to initiate shutdown sequence and break
              begin
                @buffer_chan.not_nil!.send(msg)
              rescue
              end
              break
            else
              # ignore unexpected messages
            end
          end
        rescue ex : Exception
          STDERR.puts "Dispatcher fatal error: #{ex.message}\n#{ex.backtrace.join("\n")}" if ex
          begin
            @buffer_chan.not_nil!.send(Terminal::Msg::Stop.new("dispatcher fatal: #{ex.message}"))
          rescue
          end
        end
      end
    end
  end
end
