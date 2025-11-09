# Component-oriented facade on top of the existing builder/runtime stack.
# Components define layout once, maintain their own model, and react to typed events.

require "./ui_builder"
require "./ui_layout"
require "./input_widget"
require "./text_box_widget"
require "./dropdown_widget"
require "./runtime_harness"

module Terminal
  module Components
    module Events
      struct InputSubmitted
        getter widget_id : String
        getter value : String

        def initialize(@widget_id : String, @value : String)
        end
      end

      struct KeyPressed
        getter key : String

        def initialize(@key : String)
        end
      end

      struct Tick
        getter name : String?

        def initialize(@name : String? = nil)
        end
      end
    end

    module Handles
      class TextBox
        getter widget : Terminal::TextBoxWidget

        def initialize(@widget : Terminal::TextBoxWidget)
        end

        def set_text(text : String)
          @widget.set_text(text)
        end

        def append(text : String)
          @widget.append_text(text)
        end

        def append_line(line : String)
          @widget.add_line(line)
        end

        def clear
          @widget.clear
        end

        def content : String
          @widget.content
        end
      end

      class Input
        getter widget : Terminal::InputWidget

        def initialize(@widget : Terminal::InputWidget)
        end

        def set_value(text : String)
          @widget.value = text
          @widget.cursor_pos = text.size
        end

        def value : String
          @widget.value
        end

        def clear
          @widget.clear
        end

        def prompt(text : String, bg : String = "blue")
          @widget.prompt(text, bg)
        end
      end
    end

    class ViewContext
      def initialize(@widgets : Hash(String, Terminal::Widget))
      end

      def text_box(id : String | Symbol) : Handles::TextBox
        widget = lookup(id).as(Terminal::TextBoxWidget)
        Handles::TextBox.new(widget)
      end

      def input(id : String | Symbol) : Handles::Input
        widget = lookup(id).as(Terminal::InputWidget)
        Handles::Input.new(widget)
      end

      private def lookup(id : String | Symbol) : Terminal::Widget
        key = normalize(id)
        @widgets[key]? || raise ArgumentError.new("Unknown widget '#{key}'")
      end

      private def normalize(id : String | Symbol) : String
        id.is_a?(Symbol) ? id.to_s : id
      end
    end

    class LayoutDSL
      getter widgets : Hash(String, Terminal::Widget)
      getter input_widgets : Array(Terminal::InputWidget)

      def initialize(@builder : Terminal::UI::Builder)
        @widgets = {} of String => Terminal::Widget
        @input_widgets = [] of Terminal::InputWidget
        @layout_defined = false
        @layout_stack = [] of Terminal::UI::LayoutBuilder
      end

      def compose(&block : LayoutDSL -> Nil)
        raise ArgumentError.new("Layout already defined") if @layout_defined
        @builder.layout do |layout|
          @layout_stack = [layout]
          block.call(self)
        ensure
          @layout_stack.clear
        end
        @layout_defined = true
      end

      def flex(weight : Int32 = 1) : Terminal::UI::Constraint
        Terminal::UI::Constraint.flex(weight)
      end

      def percent(value : Int32) : Terminal::UI::Constraint
        Terminal::UI::Constraint.percent(value)
      end

      def length(value : Int32) : Terminal::UI::Constraint
        Terminal::UI::Constraint.length(value)
      end

      def column(constraint : Terminal::UI::Constraint = Terminal::UI::Constraint.flex, &block : LayoutDSL -> Nil)
        with_layout_node(:vertical, constraint, &block)
      end

      def row(constraint : Terminal::UI::Constraint = Terminal::UI::Constraint.flex, &block : LayoutDSL -> Nil)
        with_layout_node(:horizontal, constraint, &block)
      end

      def text_box(id : String | Symbol, constraint : Terminal::UI::Constraint = Terminal::UI::Constraint.flex, auto_scroll : Bool? = nil, can_focus : Bool? = nil)
        text_box(id, constraint, auto_scroll, can_focus) { }
      end

      def text_box(id : String | Symbol, constraint : Terminal::UI::Constraint = Terminal::UI::Constraint.flex, auto_scroll : Bool? = nil, can_focus : Bool? = nil, &block : Proc(Terminal::TextBoxWidget, Nil))
        widget = @builder.text_box(id) do |box|
          box.auto_scroll = auto_scroll unless auto_scroll.nil?
          box.can_focus = can_focus unless can_focus.nil?
          block.call(box)
        end
        attach_widget(id, widget, constraint)
        widget
      end

      def input(id : String | Symbol, constraint : Terminal::UI::Constraint = Terminal::UI::Constraint.flex, prompt : String? = nil, prompt_bg : String? = nil)
        input(id, constraint, prompt, prompt_bg) { }
      end

      def input(id : String | Symbol, constraint : Terminal::UI::Constraint = Terminal::UI::Constraint.flex, prompt : String? = nil, prompt_bg : String? = nil, &block : Proc(Terminal::InputWidget, Nil))
        widget = @builder.input(id) do |input|
          if prompt
            if prompt_bg
              input.prompt(prompt, prompt_bg)
            else
              input.prompt(prompt)
            end
          end
          block.call(input)
        end
        @input_widgets << widget
        attach_widget(id, widget, constraint)
        widget
      end

      private def attach_widget(id, widget : Terminal::Widget, constraint : Terminal::UI::Constraint)
        key = normalize(id)
        if @widgets.has_key?(key)
          raise ArgumentError.new("Widget id '#{key}' already registered")
        end
        @widgets[key] = widget
        current_layout.widget(key, constraint)
      end

      private def with_layout_node(direction : Symbol, constraint : Terminal::UI::Constraint, &block : LayoutDSL -> Nil)
        builder = current_layout
        if direction == :horizontal
          builder.horizontal(constraint) do |child|
            @layout_stack << child
            block.call(self)
            @layout_stack.pop
          end
        else
          builder.vertical(constraint) do |child|
            @layout_stack << child
            block.call(self)
            @layout_stack.pop
          end
        end
      end

      private def current_layout : Terminal::UI::LayoutBuilder
        layout = @layout_stack.last?
        raise ArgumentError.new("No layout defined. Wrap layout calls inside compose.") unless layout
        layout
      end

      private def normalize(id : String | Symbol) : String
        id.is_a?(Symbol) ? id.to_s : id
      end
    end

    abstract class Component(ModelType)
      abstract def initial_model : ModelType
      abstract def layout(layout : LayoutDSL) : Nil
      abstract def render(model : ModelType, view : ViewContext) : Nil

      def update(event, model : ModelType) : ModelType
        model
      end

      def configure(program : Program(ModelType)) : Nil
      end
    end

    class Program(ModelType)
      getter component : Component(ModelType)
      getter view : ViewContext
      getter model : ModelType
      getter app : Terminal::TerminalApplication(Terminal::Widget)

      @harness : Terminal::RuntimeHarness::Controller?

      def initialize(
        @component : Component(ModelType),
        width : Int32 = 80,
        height : Int32 = 24,
        io : IO = STDOUT,
        input_provider : Terminal::InputProvider? = nil,
        harness : Terminal::RuntimeHarness::Controller? = nil,
      )
        @harness = harness
        @builder = Terminal::UI::Builder.new(width, height, harness)
        @layout = LayoutDSL.new(@builder)
        @layout.compose { @component.layout(@layout) }
        @view = ViewContext.new(@layout.widgets)
        @app = @builder.build(io: io, input_provider: input_provider)
        @model = @component.initial_model
        @started = false
        @running = true
        @tickers = [] of Tuple(Time::Span, Proc(Nil))
        wire_inputs
        @component.configure(self)
        render!
      end

      def start
        return if @started
        @started = true
        @app.start
        request_render
        start_tickers
      end

      def stop(reason : String | Symbol = "component.stop")
        @running = false
        notify_harness(reason)
        @app.dispatch(Terminal::Msg::Stop.new(reason.to_s))
      end

      def dispatch(event)
        @model = @component.update(event, @model)
        render!
      end

      def focus(id : String | Symbol)
        @app.widget_manager.focus_widget(id)
      end

      def record(message : String)
        @harness.try &.record(message)
      end

      def on_key(key : String | Symbol, consume : Bool = true, &block : -> _)
        normalized = normalize_key(key)
        @app.widget_manager.register_key_handler(normalized, consume) do
          if payload = block.call
            dispatch(payload)
          end
        end
      end

      def on_key(key : String | Symbol, consume : Bool = true, &block : Terminal::Msg::KeyPress -> _)
        normalized = normalize_key(key)
        handler = ->(event : Terminal::Msg::KeyPress) do
          payload = block.call(event)
          dispatch(payload) if payload
          consume
        end
        @app.widget_manager.register_key_handler(normalized, handler)
      end

      def every(interval : Time::Span, &block : -> Nil)
        @tickers << {interval, block}
      end

      private def wire_inputs
        @layout.input_widgets.each do |widget|
          widget.on_submit do |value|
            dispatch(Events::InputSubmitted.new(widget.id, value))
            widget.clear
            @app.widget_manager.focus_widget(widget.id)
          end
        end
      end

      private def start_tickers
        @tickers.each do |interval, block|
          spawn do
            while @running
              sleep(interval)
              block.call
            end
          end
        end
      end

      private def render!
        @component.render(@model, @view)
        @harness.try &.record("render")
        request_render if @started
      end

      private def request_render
        @app.dispatch(Terminal::Msg::RenderRequest.new("component", ""))
      rescue
      end

      private def notify_harness(reason : String | Symbol)
        @harness.try do |controller|
          controller.stop(normalize_reason(reason))
        end
      end

      private def normalize_reason(reason : String | Symbol) : Symbol
        return reason if reason.is_a?(Symbol)
        :component_stop
      end

      private def normalize_key(key : String | Symbol) : String
        raw = key.is_a?(Symbol) ? key.to_s : key
        raw.downcase
      end
    end

    def self.run(component : Component(ModelType), width : Int32 = 80, height : Int32 = 24, io : IO = STDOUT, input_provider : Terminal::InputProvider? = nil, harness : Terminal::RuntimeHarness::Controller? = nil) forall ModelType
      controller = harness || Terminal::RuntimeHarness::Controller.new
      program = Program(ModelType).new(component, width: width, height: height, io: io, input_provider: input_provider, harness: controller)
      program.start
      controller.wait_for_stop if harness.nil?
      program
    end
  end
end
