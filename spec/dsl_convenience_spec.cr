require "./spec_helper"
require "../src/terminal/dsl_convenience"

describe Terminal do
  describe ".application" do
    it "creates application using convenience method" do
      app = Terminal.application(80, 24) do |builder|
        builder.text("test", "Hello World", title: "Test")
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end
  end

  describe ".chat_application" do
    it "creates chat application with four quadrant layout" do
      app = Terminal.chat_application("Test Chat", 80, 24) do |chat|
        chat.chat_area do |area|
          area.content("Welcome")
        end

        chat.input_area do |input|
          input.prompt("You: ")
        end

        chat.on_user_input do |text|
          # Test callback setup
        end
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end
  end
end

describe Terminal::ApplicationDSL::ChatApplicationBuilder do
  it "configures chat areas correctly" do
    builder = Terminal::ApplicationDSL::ChatApplicationBuilder.new("Test", 80, 24)

    builder.chat_area do |area|
      area.content("Chat content")
      area.auto_scroll(true)
    end

    builder.status_area do |area|
      area.content("Status info")
    end

    builder.input_area do |input|
      input.prompt("Input: ")
    end

    app = builder.build_application
    app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end

  it "supports event handling" do
    input_handled = false
    key_handled = false

    builder = Terminal::ApplicationDSL::ChatApplicationBuilder.new("Test", 80, 24)

    builder.on_user_input { |text| input_handled = true }
    builder.on_key(:escape) { key_handled = true }

    app = builder.build_application
    app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end
end

describe Terminal::ApplicationDSL::ApplicationBuilder do
  describe "convenience layout methods" do
    it "supports four_quadrant shorthand" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.four_quadrant do |layout|
          layout.top_left("tl")
          layout.bottom_right("br")
        end

        builder.text_widget("tl") { |t| t.content("Top Left") }
        builder.text_widget("br") { |t| t.content("Bottom Right") }
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end

    it "supports grid shorthand" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.grid(2, 2) do |layout|
          layout.cell("c1", 0, 0)
          layout.cell("c2", 1, 1)
        end

        builder.text_widget("c1") { |t| t.content("Cell 1") }
        builder.text_widget("c2") { |t| t.content("Cell 2") }
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end

    it "supports vertical layout" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.vertical do |layout|
          layout.section("top", 10)
          layout.section("bottom", 14)
        end

        builder.text_widget("top") { |t| t.content("Top") }
        builder.text_widget("bottom") { |t| t.content("Bottom") }
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end
  end

  describe "convenience widget methods" do
    it "supports text shorthand" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.text("simple", "Hello World", title: "Test", color: :green)
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end

    it "supports input shorthand" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.input("simple", "Prompt: ", placeholder: "Type here")
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end
  end

  describe "theme support" do
    it "accepts theme configuration" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.theme do |theme|
          theme.primary(:white, :blue, true)
          theme.accent(:cyan, :default, false)
          theme.success(:green, :default, true)
        end

        builder.text_widget("test") { |t| t.content("Themed") }
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end
  end
end

describe Terminal::ApplicationDSL::ThemeBuilder do
  it "configures theme colors" do
    builder = Terminal::ApplicationDSL::ThemeBuilder.new

    builder.primary(:white, :blue, true)
    builder.accent(:cyan, :default, false)
    builder.success(:green)
    builder.warning(:yellow, :black)
    builder.error(:red, :default, true)

    # Theme configuration should complete without errors
    builder.should be_a(Terminal::ApplicationDSL::ThemeBuilder)
  end
end
