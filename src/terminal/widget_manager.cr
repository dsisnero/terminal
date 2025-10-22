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
require "../terminal/widget"

module Terminal
  # Widget Manager handles multiple widgets of type T which must include Widget
  class WidgetManager(T)
    private def self.check_type
      {% begin %}
        {% unless T < Terminal::Widget %}
          {{ raise "Type parameter T must include Terminal::Widget" }}
        {% end %}
      {% end %}
    end

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
      @widgets.each(&.handle(msg))
    end

    # Compose all widgets into a full 2D grid.
    # Currently simplistic: each widget's render fills the screen.
    # Later this can evolve into compositing or layout management.
    def compose(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      return [] of Array(Terminal::Cell) if @widgets.empty?

      # Currently, just render focused widget only (simplified)
      focused = @widgets[@focused_index]
      focused.render(width, height)
    end
  end # class WidgetManager(T)

end # module Terminal
