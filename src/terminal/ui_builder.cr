# File: src/terminal/ui_builder.cr
# Provides a high-level builder for composing terminal applications with
# declarative layout and widget mounting.

require "./ui_layout"
require "./widget_manager"
require "./text_box_widget"
require "./table_widget"
require "./input_widget"
require "./spinner_widget"
require "./terminal_application"

module Terminal
  # Convenience entrypoint
  def self.app(width : Int32 = 80, height : Int32 = 24, io : IO = STDOUT, input_provider : Terminal::InputProvider? = nil, &block : UI::Builder -> Nil) : TerminalApplication(Widget)
    builder = UI::Builder.new(width, height)
    block.call(builder)
    builder.build(io: io, input_provider: input_provider)
  end

  module UI
    class LayoutBuilder
      def initialize(@node : LayoutNode)
      end

      def horizontal(constraint : Constraint = Constraint.flex, &block : LayoutBuilder -> Nil)
        child = LayoutNode.new(constraint, Direction::Horizontal)
        @node.add_child(child)
        block.call(LayoutBuilder.new(child))
        child
      end

      def vertical(constraint : Constraint = Constraint.flex, &block : LayoutBuilder -> Nil)
        child = LayoutNode.new(constraint, Direction::Vertical)
        @node.add_child(child)
        block.call(LayoutBuilder.new(child))
        child
      end

      def widget(id : String | Symbol, constraint : Constraint = Constraint.flex)
        @node.add_child(LayoutNode.new(constraint, nil, id.to_s))
      end
    end

    class Builder
      getter width : Int32
      getter height : Int32

      def initialize(@width : Int32, @height : Int32)
        @widgets = {} of String => Terminal::Widget
        @layout_root = LayoutNode.new(Constraint.flex, Direction::Vertical)
        @input_handlers = {} of String => Proc(String, Nil)
        @key_handlers = Hash(String, Array(Tuple(Bool, Proc(Nil)))).new { |hash, key| hash[key] = [] of Tuple(Bool, Proc(Nil)) }
        @tickers = [] of Tuple(Time::Span, Proc(Nil))
        @on_start = nil
        @on_stop = nil
      end

      def layout(&block : LayoutBuilder -> Nil)
        block.call(LayoutBuilder.new(@layout_root))
      end

      def mount(id : String | Symbol, widget : Terminal::Widget)
        key = normalize_id(id)
        if @widgets.has_key?(key)
          raise ArgumentError.new("Widget id '#{key}' already registered")
        end
        @widgets[key] = widget
      end

      def text_box(id : String | Symbol, &block : TextBoxWidget -> Nil)
        key = normalize_id(id)
        widget = Terminal::TextBoxWidget.new(key)
        block.call(widget)
        mount(key, widget)
      end

      def table(id : String | Symbol, &block : TableWidget -> Nil)
        key = normalize_id(id)
        widget = Terminal::TableWidget.new(key)
        block.call(widget)
        mount(key, widget)
      end

      def input(id : String | Symbol, &block : InputWidget -> Nil)
        key = normalize_id(id)
        widget = Terminal::InputWidget.new(id: key)
        block.call(widget)
        mount(key, widget)
      end

      def spinner(id : String | Symbol, label : String = "", &block : SpinnerWidget -> Nil)
        key = normalize_id(id)
        widget = Terminal::SpinnerWidget.new(key, label)
        block.call(widget)
        mount(key, widget)
      end

      def on_input(widget_id : String | Symbol, &block : String -> Nil)
        @input_handlers[normalize_id(widget_id)] = block
      end

      def on_key(key : String | Symbol, consume : Bool = true, &block : -> Nil)
        @key_handlers[normalize_key(key)] << {consume, block}
      end

      def every(interval : Time::Span, &block : -> Nil)
        @tickers << {interval, block}
      end

      def on_start(&block : -> Nil)
        @on_start = block
      end

      def on_stop(&block : -> Nil)
        @on_stop = block
      end

      def build(io : IO = STDOUT, input_provider : Terminal::InputProvider? = nil) : TerminalApplication(Terminal::Widget)
        ensure_layout_covers_widgets

        manager = WidgetManager(Terminal::Widget).new(@widgets, @layout_root)

        attach_input_handlers
        attach_key_handlers(manager)

        app = TerminalApplication(Terminal::Widget).new(
          widget_manager: manager,
          io: io,
          input_provider: input_provider,
          width: @width,
          height: @height
        )

        schedule_start_and_ticks

        app
      end

      private def ensure_layout_covers_widgets
        leaf_ids = @layout_root.leaf_ids
        if leaf_ids.empty? && !@widgets.empty?
          @widgets.each_key do |widget_id|
            @layout_root.add_child(LayoutNode.new(Constraint.flex, nil, widget_id))
          end
          leaf_ids = @layout_root.leaf_ids
        else
          duplicates = leaf_ids.group_by(&.itself).select { |_, items| items.size > 1 }.keys
          unless duplicates.empty?
            raise ArgumentError.new("Layout defines duplicate widget ids: #{duplicates.join(", ")}")
          end
        end

        missing = @widgets.keys - leaf_ids
        if leaf_ids.empty?
          missing.each { |widget_id| @layout_root.add_child(LayoutNode.new(Constraint.flex, nil, widget_id)) }
        else
          unless missing.empty?
            raise ArgumentError.new("Layout does not declare widgets: #{missing.join(", ")}")
          end

          extra = leaf_ids - @widgets.keys
          unless extra.empty?
            raise ArgumentError.new("Layout references unknown widgets: #{extra.join(", ")}")
          end
        end
      end

      private def attach_input_handlers
        @input_handlers.each do |widget_id, handler|
          if widget = @widgets[widget_id]?.as?(InputWidget)
            widget.on_submit(&handler)
          end
        end
      end

      private def attach_key_handlers(manager : WidgetManager(Terminal::Widget))
        @key_handlers.each do |key, handlers|
          handlers.each do |consume, handler|
            manager.register_key_handler(key, consume, &handler)
          end
        end
      end

      private def schedule_start_and_ticks
        if handler = @on_start
          spawn { handler.call }
        end

        @tickers.each do |interval, proc|
          spawn do
            loop do
              sleep(interval)
              proc.call
            end
          end
        end
      end

      private def normalize_id(id : String | Symbol) : String
        id.is_a?(Symbol) ? id.to_s : id
      end

      private def normalize_key(key : String | Symbol) : String
        raw = key.is_a?(Symbol) ? key.to_s : key
        raw.downcase
      end
    end
  end
end
