require "./spec_helper"
require "../src/terminal/dsl_convenience"

# Integration test showing the enhanced DSL in action
describe "Enhanced Terminal DSL Integration" do
  it "demonstrates four quadrant layout DSL" do
    # This test shows that the DSL creates a proper TerminalApplication
    app = Terminal.application(80, 24) do |builder|
      # Four quadrant layout - generic and reusable
      builder.layout :four_quadrant do |layout|
        if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
          layout.top_left("main", 70, 80)
          layout.top_right("status", 30, 80)
          layout.bottom_left("logs", 70, 15)
          layout.bottom_right("help", 30, 15)
          layout.bottom_full("input", 3)
        end
      end

      # Create widgets using builders
      builder.text_widget("main") do |text|
        text.content("Main content area")
        text.title("💬 Chat")
        text.auto_scroll(true)
      end

      builder.text_widget("status") do |text|
        text.content("Status: Ready")
        text.title("📊 Status")
        text.color(:cyan)
      end

      builder.text_widget("logs") do |text|
        text.content("System logs...")
        text.title("⚙️ Logs")
        text.color(:yellow)
      end

      builder.text_widget("help") do |text|
        text.content("Help info")
        text.title("❓ Help")
      end

      builder.input_widget("input") do |input|
        input.prompt("You: ", "blue")
        input.placeholder("Type here...")
      end

      # Event handling
      builder.on_input("input") do |_text|
        # Would handle user input
      end

      builder.on_key("escape") do
        # Would exit application
      end
    end

    # Verify we get a proper TerminalApplication with full architecture
    app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end

  it "demonstrates chat application convenience DSL" do
    # This shows the most convenient way for chat interfaces
    app = Terminal.chat_application("Test Chat", 80, 24) do |chat|
      chat.chat_area do |area|
        area.content("Welcome to chat!")
        area.auto_scroll(true)
      end

      chat.status_area do |area|
        area.content("Connected")
      end

      chat.system_area do |area|
        area.content("System ready")
      end

      chat.help_area do |area|
        area.content("Commands: /help, /quit")
      end

      chat.input_area do |input|
        input.prompt("Say: ")
      end

      chat.on_user_input do |_text|
        # Handle chat message
      end

      chat.on_key(:escape) do
        # Exit chat
      end
    end

    app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end

  it "demonstrates layout compositing works correctly" do
    # Test that the LayoutCompositeWidget properly handles widgets
    widgets = {
      "test1" => Terminal::TextBoxWidget.new("test1", "Content 1"),
      "test2" => Terminal::TextBoxWidget.new("test2", "Content 2"),
    }

    layout_areas = {
      "test1" => {x: 0, y: 0, width: 40, height: 12},
      "test2" => {x: 40, y: 0, width: 40, height: 12},
    }

    composite = Terminal::ApplicationDSL::LayoutCompositeWidget.new(
      widgets, layout_areas, 80, 24
    )

    # Test basic functionality
    composite.id.should eq("layout_composite")

    # Test rendering
    buffer = composite.render(80, 24)
    buffer.size.should eq(24)
    buffer[0].size.should eq(80)

    # Test message handling doesn't crash
    composite.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))
  end

  it "demonstrates all layout types work" do
    layouts_tested = [] of Symbol

    # Test four quadrant
    Terminal.application(80, 24) do |builder|
      builder.layout :four_quadrant do |layout|
        if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
          layout.top_left("tl")
          layouts_tested << :four_quadrant
        end
      end
      builder.text_widget("tl", &.content("test"))
    end

    # Test grid
    Terminal.application(80, 24) do |builder|
      builder.layout :grid do |layout|
        if layout.is_a?(Terminal::ApplicationDSL::GridLayout)
          layout.cell("c1", 0, 0)
          layouts_tested << :grid
        end
      end
      builder.text_widget("c1", &.content("test"))
    end

    # Test vertical
    Terminal.application(80, 24) do |builder|
      builder.layout :vertical do |layout|
        if layout.is_a?(Terminal::ApplicationDSL::VerticalLayout)
          layout.section("s1", 10)
          layouts_tested << :vertical
        end
      end
      builder.text_widget("s1", &.content("test"))
    end

    # Test horizontal
    Terminal.application(80, 24) do |builder|
      builder.layout :horizontal do |layout|
        if layout.is_a?(Terminal::ApplicationDSL::HorizontalLayout)
          layout.section("s1", 40)
          layouts_tested << :horizontal
        end
      end
      builder.text_widget("s1", &.content("test"))
    end

    layouts_tested.should eq([:four_quadrant, :grid, :vertical, :horizontal])
  end
end
