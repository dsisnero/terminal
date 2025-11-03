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
  def self.app(width : Int32 = 80, height : Int32 = 24, &block : UI::Builder -> Nil) : TerminalApplication(Widget)
    builder = UI::Builder.new(width, height)
    block.call(builder)
    builder.build
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

      def widget(id : String, constraint : Constraint = Constraint.flex)
        @node.add_child(LayoutNode.new(constraint, nil, id))
      end
    end

    class Builder
      @widgets : Hash(String, Terminal::Widget)
      @layout_root : LayoutNode
      @input_handlers : Hash(String, Proc(String, Nil))
      @tickers : Array(Tuple(Time::Span, Proc(Nil)))
      @on_start : Proc(Nil)?
      @on_stop : Proc(Nil)?

      getter width : Int32
      getter height : Int32

      def initialize(@width : Int32, @height : Int32)
        @widgets = {} of String => Terminal::Widget
        @layout_root = LayoutNode.new(Constraint.flex, Direction::Vertical)
        @input_handlers = {} of String => Proc(String, Nil)
        @tickers = [] of Tuple(Time::Span, Proc(Nil))
        @on_start = nil
        @on_stop = nil
      end

      def layout(&block : LayoutBuilder -> Nil)
        block.call(LayoutBuilder.new(@layout_root))
      end

      def mount(id : String, widget : Terminal::Widget)
        @widgets[id] = widget
      end

      def text_box(id : String, &block : TextBoxWidget -> Nil)
        widget = Terminal::TextBoxWidget.new(id)
        block.call(widget)
        mount(id, widget)
      end

      def table(id : String, &block : TableWidget -> Nil)
        widget = Terminal::TableWidget.new(id)
        block.call(widget)
        mount(id, widget)
      end

      def input(id : String, &block : InputWidget -> Nil)
        widget = Terminal::InputWidget.new(id: id)
        block.call(widget)
        mount(id, widget)
      end

      def spinner(id : String, label : String = "", &block : SpinnerWidget -> Nil)
        widget = Terminal::SpinnerWidget.new(id, label)
        block.call(widget)
        mount(id, widget)
      end

      def on_input(widget_id : String, &block : String -> Nil)
        @input_handlers[widget_id] = block
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

      def build : TerminalApplication(Terminal::Widget)
        ensure_layout_covers_widgets

        manager = WidgetManager(Terminal::Widget).new(@widgets, @layout_root)

        attach_input_handlers

        app = TerminalApplication(Terminal::Widget).new(
          widget_manager: manager,
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
        end

        missing = @widgets.keys - leaf_ids
        missing.each { |widget_id| @layout_root.add_child(LayoutNode.new(Constraint.flex, nil, widget_id)) }
      end

      private def attach_input_handlers
        @input_handlers.each do |widget_id, handler|
          if widget = @widgets[widget_id]?.as?(InputWidget)
            widget.on_submit(&handler)
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
    end
  end
end
