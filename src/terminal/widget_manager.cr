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
require "../terminal/geometry"
require "../terminal/ui_layout"

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

    alias KeyHandler = Proc(Terminal::Msg::KeyPress, Bool)

    @widgets : Array(T)
    @widget_lookup : Hash(String, T)
    @focus_keys : Array(String)
    @focused_index = 0
    @layout_root : UI::LayoutNode?
    @key_handlers : Hash(String, Array(KeyHandler))

    def initialize(widgets : Array(T))
      @widgets = widgets
      @widget_lookup = build_lookup(widgets)
      @focus_keys = build_focus_keys(@widgets)
      @layout_root = nil
      @key_handlers = Hash(String, Array(KeyHandler)).new { |hash, key| hash[key] = [] of KeyHandler }
      focus_current
    end

    def initialize(widgets : Hash(String, T), layout : UI::LayoutNode)
      @widget_lookup = widgets
      @widgets = widgets.values
      @layout_root = layout
      @key_handlers = Hash(String, Array(KeyHandler)).new { |hash, key| hash[key] = [] of KeyHandler }
      @focus_keys = layout.leaf_ids.select { |widget_id| focusable_id?(widget_id) }
      if @focus_keys.empty?
        @focus_keys = widgets.keys.select { |widget_id| focusable_id?(widget_id) }
      end
      focus_current
    end

    def focus_next
      return if @focus_keys.empty?
      @focused_index = (@focused_index + 1) % @focus_keys.size
      focus_current
    end

    def focus_prev
      return if @focus_keys.empty?
      @focused_index -= 1
      if @focused_index < 0
        @focused_index = @focus_keys.size - 1
      end
      focus_current
    end

    def focus_widget(widget_id : String | Symbol)
      return if @focus_keys.empty?
      key = widget_id.is_a?(Symbol) ? widget_id.to_s : widget_id
      if idx = @focus_keys.index(key)
        @focused_index = idx
        focus_current
      end
    end

    def route_to_focused(msg : Terminal::Msg::Any)
      case msg
      when Terminal::Msg::KeyPress
        consumed = handle_global_key(msg)
        return if consumed
      end

      current_widget.try(&.handle(msg))
    end

    def broadcast(msg : Terminal::Msg::Any)
      @widget_lookup.each_value(&.handle(msg))
    end

    def register_key_handler(key : String, handler : KeyHandler)
      normalized = key.downcase
      @key_handlers[normalized] << handler
    end

    def register_key_handler(key : String, &block : Terminal::Msg::KeyPress -> Bool)
      register_key_handler(key, block)
    end

    def register_key_handler(key : String, consume : Bool = true, &block : -> Nil)
      handler = ->(_event : Terminal::Msg::KeyPress) do
        block.call
        consume
      end
      register_key_handler(key, handler)
    end

    # Compose all widgets into a full 2D grid.
    def compose(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      return [] of Array(Terminal::Cell) if @widget_lookup.empty?

      if root = @layout_root
        compose_with_layout(root, width, height)
      else
        widget = current_widget
        widget ? widget.render(width, height) : [] of Array(Terminal::Cell)
      end
    end

    private def compose_with_layout(root : UI::LayoutNode, width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      grid = Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } }
      rects = UI::LayoutResolver.resolve(root, Geometry::Rect.new(0, 0, width, height))
      rects.each do |widget_id, rect|
        next unless widget = @widget_lookup[widget_id]?
        next if rect.width <= 0 || rect.height <= 0
        rendered = widget.render(rect.width, rect.height)
        rendered.each_with_index do |row, row_idx|
          target_row = rect.y + row_idx
          break if target_row >= height
          row.each_with_index do |cell, col_idx|
            target_col = rect.x + col_idx
            break if target_col >= width
            grid[target_row][target_col] = cell
          end
        end
      end
      grid
    end

    private def build_lookup(widgets : Array(T)) : Hash(String, T)
      lookup = {} of String => T
      widgets.each do |widget|
        lookup[widget.id] = widget
      end
      lookup
    end

    private def build_focus_keys(widgets : Enumerable(T)) : Array(String)
      widgets.compact_map do |widget|
        widget.id if widget.can_focus
      end
    end

    private def focusable_id?(widget_id : String) : Bool
      if widget = @widget_lookup[widget_id]?
        widget.can_focus
      else
        false
      end
    end

    private def current_widget : T?
      return nil if @focus_keys.empty?
      key = @focus_keys[@focused_index % @focus_keys.size]?
      key ? @widget_lookup[key]? : nil
    end

    private def focus_current
      @widget_lookup.each_value(&.blur)
      current_widget.try(&.focus)
    end

    private def handle_global_key(event : Terminal::Msg::KeyPress) : Bool
      key = event.key.downcase
      case key
      when "tab"
        focus_next
        return true
      when "shift+tab"
        focus_prev
        return true
      end

      handled = false
      if handlers = @key_handlers[key]?
        handlers.each do |handler|
          handled ||= handler.call(event)
        end
      end
      handled
    end
  end # class WidgetManager(T)

end # module Terminal
