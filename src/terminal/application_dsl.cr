# Enhanced Terminal Application DSL
# Provides elegant DSL while using full terminal architecture capabilities

require "./terminal_application"
require "./widget_manager"
require "./input_provider"
require "./text_box_widget"
require "./input_widget"
require "./widget"

module Terminal
  # Enhanced DSL that builds proper TerminalApplication with full architecture
  module ApplicationDSL
    # Main entry point for creating terminal applications
    def self.application(width : Int32 = 80, height : Int32 = 24, &block : ApplicationBuilder -> Nil) : TerminalApplication(Widget)
      builder = ApplicationBuilder.new(width, height)
      block.call(builder)
      builder.build
    end

    class ApplicationBuilder
      @widgets = {} of String => Widget
      @layout_areas = {} of String => NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      @input_handlers = {} of String => Proc(String, Nil)
      @key_handlers = {} of String => Proc(Nil)
      @periodic_handlers = [] of Tuple(Time::Span, Proc(Nil))
      @on_start : Proc(Nil)?
      @on_stop : Proc(Nil)?

      def initialize(@width : Int32, @height : Int32)
      end

      # Layout configuration with semantic methods
      def layout(style : Symbol, &)
        case style
        when :four_quadrant
          layout_builder = FourQuadrantLayout.new(@width, @height)
          yield layout_builder
          @layout_areas = layout_builder.areas
        when :grid
          layout_builder = GridLayout.new(@width, @height)
          yield layout_builder
          @layout_areas = layout_builder.areas
        when :vertical
          layout_builder = VerticalLayout.new(@width, @height)
          yield layout_builder
          @layout_areas = layout_builder.areas
        when :horizontal
          layout_builder = HorizontalLayout.new(@width, @height)
          yield layout_builder
          @layout_areas = layout_builder.areas
        else
          raise "Unknown layout style: #{style}"
        end
      end

      # Widget definition with blocks
      def widget(id : String, type : Symbol, &block : WidgetBuilder -> Nil)
        widget_builder = WidgetBuilder.new(id, type)
        block.call(widget_builder)
        @widgets[id] = widget_builder.build
      end

      # Convenient widget factories
      def text_widget(id : String, &block : TextWidgetBuilder -> Nil)
        builder = TextWidgetBuilder.new(id)
        block.call(builder)
        @widgets[id] = builder.build
      end

      def input_widget(id : String, &block : InputWidgetBuilder -> Nil)
        builder = InputWidgetBuilder.new(id)
        block.call(builder)
        widget = builder.build

        # Connect input handler if specified
        if handler = builder.submit_handler
          widget.on_submit(&handler)
        end

        @widgets[id] = widget
      end

      # Event handling
      def on_input(widget_id : String, &block : String -> Nil)
        @input_handlers[widget_id] = block
      end

      def on_key(key : String | Symbol, &block : -> Nil)
        @key_handlers[key.to_s] = block
      end

      def every(interval : Time::Span, &block : -> Nil)
        @periodic_handlers << {interval, block}
      end

      def on_start(&block : -> Nil)
        @on_start = block
      end

      def on_stop(&block : -> Nil)
        @on_stop = block
      end

      # Build the actual TerminalApplication with full architecture
      def build : TerminalApplication(Widget)
        # Create composite widget that handles layout and composition
        composite_widget = LayoutCompositeWidget.new(@widgets, @layout_areas, @width, @height)

        # Setup input handling
        setup_input_handling(composite_widget)

        # Create widget manager - cast to Widget to satisfy type system
        widgets_array = [composite_widget.as(Widget)]
        widget_manager = WidgetManager(Widget).new(widgets_array)

        # Create terminal application with full architecture
        app = TerminalApplication(Widget).new(
          widget_manager: widget_manager,
          input_provider: InputProvider.default,
          width: @width,
          height: @height
        )

        # Setup lifecycle callbacks
        if start_handler = @on_start
          spawn { start_handler.call }
        end

        # Setup periodic tasks
        @periodic_handlers.each do |interval, handler|
          spawn do
            loop do
              sleep(interval)
              handler.call
            end
          end
        end

        app
      end

      private def setup_input_handling(composite_widget : LayoutCompositeWidget)
        @input_handlers.each do |widget_id, handler|
          if widget = @widgets[widget_id]?.as?(InputWidget)
            widget.on_submit(&handler)
          end
        end
      end
    end

    # Layout builders for different layout styles
    abstract class LayoutBuilder
      abstract def areas : Hash(String, NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32))
    end

    class FourQuadrantLayout < LayoutBuilder
      def areas : Hash(String, NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32))
        @areas
      end

      def initialize(@width : Int32, @height : Int32)
        @areas = {} of String => NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      end

      def top_left(widget_id : String, width_percent : Int32 = 50, height_percent : Int32 = 50)
        w = (@width * width_percent / 100).to_i
        h = (@height * height_percent / 100).to_i
        @areas[widget_id] = {x: 0, y: 0, width: w, height: h}
      end

      def top_right(widget_id : String, width_percent : Int32 = 50, height_percent : Int32 = 50)
        w = (@width * width_percent / 100).to_i
        h = (@height * height_percent / 100).to_i
        x = @width - w
        @areas[widget_id] = {x: x, y: 0, width: w, height: h}
      end

      def bottom_left(widget_id : String, width_percent : Int32 = 50, height_percent : Int32 = 50)
        w = (@width * width_percent / 100).to_i
        h = (@height * height_percent / 100).to_i
        y = @height - h
        @areas[widget_id] = {x: 0, y: y, width: w, height: h}
      end

      def bottom_right(widget_id : String, width_percent : Int32 = 50, height_percent : Int32 = 50)
        w = (@width * width_percent / 100).to_i
        h = (@height * height_percent / 100).to_i
        x = @width - w
        y = @height - h
        @areas[widget_id] = {x: x, y: y, width: w, height: h}
      end

      def bottom_full(widget_id : String, height : Int32 = 3)
        y = @height - height
        @areas[widget_id] = {x: 0, y: y, width: @width, height: height}
      end

      def top_full(widget_id : String, height : Int32 = 3)
        @areas[widget_id] = {x: 0, y: 0, width: @width, height: height}
      end

      def left_full(widget_id : String, width : Int32 = 20)
        @areas[widget_id] = {x: 0, y: 0, width: width, height: @height}
      end

      def right_full(widget_id : String, width : Int32 = 20)
        x = @width - width
        @areas[widget_id] = {x: x, y: 0, width: width, height: @height}
      end
    end

    # Additional layout types
    class GridLayout < LayoutBuilder
      @cell_width : Int32
      @cell_height : Int32

      def areas : Hash(String, NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32))
        @areas
      end

      def initialize(@width : Int32, @height : Int32, @rows : Int32 = 2, @cols : Int32 = 2)
        @areas = {} of String => NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
        @cell_width = @width // @cols
        @cell_height = @height // @rows
      end

      def cell(widget_id : String, row : Int32, col : Int32, row_span : Int32 = 1, col_span : Int32 = 1)
        x = col * @cell_width
        y = row * @cell_height
        width = col_span * @cell_width
        height = row_span * @cell_height
        @areas[widget_id] = {x: x, y: y, width: width, height: height}
      end
    end

    class VerticalLayout < LayoutBuilder
      @current_y : Int32

      def areas : Hash(String, NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32))
        @areas
      end

      def initialize(@width : Int32, @height : Int32)
        @areas = {} of String => NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
        @current_y = 0
      end

      def section(widget_id : String, height : Int32? = nil, flex : Int32 = 1)
        actual_height = height || (@height // 3) # Default reasonable height
        @areas[widget_id] = {x: 0, y: @current_y, width: @width, height: actual_height}
        @current_y += actual_height
      end
    end

    class HorizontalLayout < LayoutBuilder
      @current_x : Int32

      def areas : Hash(String, NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32))
        @areas
      end

      def initialize(@width : Int32, @height : Int32)
        @areas = {} of String => NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
        @current_x = 0
      end

      def section(widget_id : String, width : Int32? = nil, flex : Int32 = 1)
        actual_width = width || (@width // 3) # Default reasonable width
        @areas[widget_id] = {x: @current_x, y: 0, width: actual_width, height: @height}
        @current_x += actual_width
      end
    end

    # Widget builders for convenient creation
    class WidgetBuilder
      def initialize(@id : String, @type : Symbol)
      end

      def build : Widget
        case @type
        when :text
          TextBoxWidget.new(@id)
        when :input
          InputWidget.new(@id)
        when :table
          TableWidget.new(@id)
        else
          raise "Unknown widget type: #{@type}"
        end
      end
    end

    class TextWidgetBuilder
      def initialize(@id : String)
        @content = ""
        @fg_color = :white
        @bg_color = :default
        @auto_scroll = false
        @border = true
        @title = ""
      end

      def content(text : String)
        @content = text
        self
      end

      def title(text : String)
        @title = text
        self
      end

      def color(fg : Symbol, bg : Symbol = :default)
        @fg_color = fg
        @bg_color = bg
        self
      end

      def auto_scroll(enabled : Bool = true)
        @auto_scroll = enabled
        self
      end

      def border(enabled : Bool = true)
        @border = enabled
        self
      end

      def build : TextBoxWidget
        # Add title to content if specified
        final_content = @title.empty? ? @content : "#{@title}\n#{@content}"

        TextBoxWidget.new(
          id: @id,
          content: final_content,
          fg_color: @fg_color,
          bg_color: @bg_color,
          auto_scroll: @auto_scroll,
          padding: @border ? 1 : 0
        )
      end
    end

    class InputWidgetBuilder
      getter submit_handler : Proc(String, Nil)?

      def initialize(@id : String)
        @prompt = "> "
        @prompt_bg = "blue"
        @placeholder = ""
        @max_length = nil
      end

      def prompt(text : String, bg : String = "blue")
        @prompt = text
        @prompt_bg = bg
        self
      end

      def placeholder(text : String)
        @placeholder = text
        self
      end

      def max_length(length : Int32)
        @max_length = length
        self
      end

      def on_submit(&block : String -> Nil)
        @submit_handler = block
        self
      end

      def build : InputWidget
        InputWidget.new(
          id: @id,
          prompt: @prompt,
          prompt_bg: @prompt_bg,
          max_length: @max_length
        )
      end
    end

    # Composite widget that handles layout and uses full terminal architecture
    class LayoutCompositeWidget
      include Widget

      @widgets : Hash(String, Terminal::Widget)

      def id : String
        "layout_composite"
      end

      def initialize(
        widgets : Hash(String, Terminal::Widget),
        @layout_areas : Hash(String, NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)),
        @width : Int32,
        @height : Int32,
      )
        @widgets = widgets.transform_values(&.as(Terminal::Widget))
      end

      # Implement Measurable interface
      def calculate_min_size : Terminal::Geometry::Size
        Terminal::Geometry::Size.new(@width, @height)
      end

      def calculate_max_size : Terminal::Geometry::Size
        Terminal::Geometry::Size.new(@width, @height)
      end

      def handle(msg : Terminal::Msg::Any)
        # Route to focused widget or broadcast to all
        case msg
        when Terminal::Msg::InputEvent, Terminal::Msg::KeyPress
          # Route to focused widget (simplified - could use focus management)
          @widgets.values.first?.try(&.handle(msg))
        else
          # Broadcast to all widgets
          @widgets.each_value(&.handle(msg))
        end
      end

      def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
        # Create buffer for composition
        buffer = Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } }

        # Render each widget into its layout area
        @layout_areas.each do |widget_id, area|
          next unless widget = @widgets[widget_id]?

          # Render widget content
          widget_content = widget.render(area[:width], area[:height])

          # Composite into main buffer
          widget_content.each_with_index do |row, row_idx|
            buffer_row = area[:y] + row_idx
            next if buffer_row >= height

            row.each_with_index do |cell, col_idx|
              buffer_col = area[:x] + col_idx
              next if buffer_col >= width

              buffer[buffer_row][buffer_col] = cell
            end
          end
        end

        buffer
      end
    end
  end
end
