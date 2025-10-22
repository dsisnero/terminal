# Terminal DSL Convenience Methods
# Additional helpers for common patterns

module Terminal
  # Convenience methods at module level
  def self.application(width : Int32 = 80, height : Int32 = 24, &block : ApplicationDSL::ApplicationBuilder -> Nil)
    ApplicationDSL.application(width, height, &block)
  end

  # Chat-specific convenience method that uses :four_quadrant layout
  def self.chat_application(title : String = "Chat Interface", width : Int32 = 80, height : Int32 = 24, &block : ApplicationDSL::ChatApplicationBuilder -> Nil)
    builder = ApplicationDSL::ChatApplicationBuilder.new(title, width, height)
    block.call(builder)
    builder.build_application
  end

  module ApplicationDSL
    # Specialized builder for chat applications
    class ChatApplicationBuilder
      def initialize(@title : String, @width : Int32, @height : Int32)
        @app_builder = ApplicationBuilder.new(@width, @height)
        @chat_content = "Welcome to #{@title}!"
        @status_content = "Ready"
        @system_content = ""
        @help_content = "Type /help for commands"
      end

      # Convenient methods for chat areas
      def chat_area(&block : TextWidgetBuilder -> Nil)
        @app_builder.text_widget("chat") do |text|
          text.title("💬 Chat")
          text.content(@chat_content)
          text.color(:white, :default)
          text.auto_scroll(true)
          text.border(true)
          block.call(text)
        end
      end

      def status_area(&block : TextWidgetBuilder -> Nil)
        @app_builder.text_widget("status") do |text|
          text.title("📊 Status")
          text.content(@status_content)
          text.color(:cyan, :default)
          text.border(true)
          block.call(text)
        end
      end

      def system_area(&block : TextWidgetBuilder -> Nil)
        @app_builder.text_widget("system") do |text|
          text.title("⚙️ System")
          text.content(@system_content)
          text.color(:yellow, :default)
          text.auto_scroll(true)
          text.border(true)
          block.call(text)
        end
      end

      def help_area(&block : TextWidgetBuilder -> Nil)
        @app_builder.text_widget("help") do |text|
          text.title("❓ Help")
          text.content(@help_content)
          text.color(:white, :default)
          text.border(true)
          block.call(text)
        end
      end

      def input_area(&block : InputWidgetBuilder -> Nil)
        @app_builder.input_widget("input") do |input|
          input.prompt("You: ", "blue")
          input.placeholder("Type a message...")
          block.call(input)
        end
      end

      # Event delegation
      def on_user_input(&block : String -> Nil)
        @app_builder.on_input("input", &block)
      end

      def on_key(key : String | Symbol, &block)
        @app_builder.on_key(key, &block)
      end

      def every(interval : Time::Span, &block)
        @app_builder.every(interval, &block)
      end

      # Build with automatic four-quadrant layout
      def build_application
        # Setup four-quadrant layout automatically
        @app_builder.layout :four_quadrant do |layout|
          if layout.is_a?(ApplicationDSL::FourQuadrantLayout)
            layout.top_left("chat", 70, 75)
            layout.top_right("status", 30, 75) 
            layout.bottom_left("system", 70, 20)
            layout.bottom_right("help", 30, 20)
            layout.bottom_full("input", 3)
          end
        end

        @app_builder.build
      end
    end

    # Enhanced ApplicationBuilder with more convenience methods
    class ApplicationBuilder
      # Shorthand layout methods with proper typing
      def four_quadrant
        layout_builder = Terminal::ApplicationDSL::FourQuadrantLayout.new(@width, @height)
        yield layout_builder
        @layout_areas = layout_builder.areas
      end

      def grid(rows : Int32 = 2, cols : Int32 = 2)
        layout_builder = Terminal::ApplicationDSL::GridLayout.new(@width, @height, rows, cols)
        yield layout_builder
        @layout_areas = layout_builder.areas
      end

      def vertical
        layout_builder = Terminal::ApplicationDSL::VerticalLayout.new(@width, @height)
        yield layout_builder
        @layout_areas = layout_builder.areas
      end

      def horizontal
        layout_builder = Terminal::ApplicationDSL::HorizontalLayout.new(@width, @height)
        yield layout_builder
        @layout_areas = layout_builder.areas
      end

      # Widget shortcuts
      def text(id : String, content : String, title : String? = nil, color : Symbol? = nil, auto_scroll : Bool = false, border : Bool = true)
        text_widget(id) do |text|
          text.content(content)
          text.color(color) if color
          text.title(title) if title
          text.auto_scroll(auto_scroll)
          text.border(border)
        end
      end

      def input(id : String, prompt : String = "> ", bg : String = "blue", placeholder : String = "", max_length : Int32? = nil)
        input_widget(id) do |input|
          input.prompt(prompt, bg)
          input.placeholder(placeholder)
          input.max_length(max_length) if max_length
        end
      end

      # Theme support
      def theme(&block : ThemeBuilder -> Nil)
        theme_builder = ThemeBuilder.new
        block.call(theme_builder)
        # Apply theme to widgets (would be implemented)
      end
    end

    class ThemeBuilder
      def initialize
        @colors = {} of Symbol => NamedTuple(fg: Symbol, bg: Symbol, bold: Bool?)
      end

      def primary(fg : Symbol, bg : Symbol = :default, bold : Bool = false)
        @colors[:primary] = {fg: fg, bg: bg, bold: bold}
      end

      def accent(fg : Symbol, bg : Symbol = :default, bold : Bool = false)
        @colors[:accent] = {fg: fg, bg: bg, bold: bold}
      end

      def success(fg : Symbol, bg : Symbol = :default, bold : Bool = false)
        @colors[:success] = {fg: fg, bg: bg, bold: bold}
      end

      def warning(fg : Symbol, bg : Symbol = :default, bold : Bool = false)
        @colors[:warning] = {fg: fg, bg: bg, bold: bold}
      end

      def error(fg : Symbol, bg : Symbol = :default, bold : Bool = false)
        @colors[:error] = {fg: fg, bg: bg, bold: bold}
      end
    end
  end
end