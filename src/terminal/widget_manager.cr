# File: src/terminal/widget_manager.cr
# Purpose: Manage multiple widgets, focus state, routing, and composition.
# Communicates only via immutable Msg::Any messages and channels.
# Each widget can have its own input channel and output updates.
#
# Responsibilities:
# - Manage list of widgets, their focus order, and per-widget channels.
# - Route input events to the focused widget.
# - Broadcast commands.
# - Compose full screen content by collecting from all widgets.

require "../terminal/messages"
require "../terminal/cell"

# Base interface for widgets.
module Widget
  abstract def id : String
  abstract def handle(msg : Terminal::Msg::Any)
  abstract def render(width : Int32, height : Int32) : Array(Array(Cell))
end

class WidgetManager(T)
  @widgets : Array(T)
  @focused_index = 0

  def initialize(widgets : Array(T))
    @widgets = widgets
  end

  def focus_next
    return if @widgets.empty?
    @focused_index = (@focused_index + 1) % @widgets.size
  end

  def focus_prev
    return if @widgets.empty?
    @focused_index = (@focused_index - 1) % @widgets.size
    @focused_index = 0 if @focused_index < 0
  end

  def route_to_focused(msg : Terminal::Msg::Any)
    return if @widgets.empty?
    focused = @widgets[@focused_index]
    focused.handle(msg)
  end

  def broadcast(msg : Terminal::Msg::Any)
    @widgets.each { |w| w.handle(msg) }
  end

  # Compose all widgets into a full 2D grid.
  # Currently simplistic: each widget's render fills the screen.
  # Later this can evolve into compositing or layout management.
  def compose(width : Int32, height : Int32) : Array(Array(Cell))
    return [] of Array(Cell) if @widgets.empty?

    # Currently, just render focused widget only (simplified)
    focused = @widgets[@focused_index]
    focused.render(width, height)
  end
end

# Example BasicWidget implementation for testing and demonstration.
class BasicWidget
  include Widget
  getter id : String
  @content : String

  def initialize(@id : String, @content : String = "Hello")
  end

  def handle(msg : Terminal::Msg::Any)
    case msg
    when Terminal::Msg::InputEvent
      # update content with char
      @content += msg.char
    when Terminal::Msg::Command
      if msg.name == "clear"
        @content = ""
      end
    end
  end

  def render(width : Int32, height : Int32) : Array(Array(Cell))
    text = @content.ljust(width * height).chars.first(width * height)
    lines = [] of Array(Cell)
    idx = 0
    height.times do
      line_cells = [] of Cell
      width.times do
        ch = text[idx]? || ' '
        idx += 1
        line_cells << Cell.new(ch)
      end
      lines << line_cells
    end
    lines
  end
end