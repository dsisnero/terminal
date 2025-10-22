require "./spec_helper"
require "../src/terminal/application_dsl"

describe Terminal::ApplicationDSL do
  describe "ApplicationBuilder" do
    it "creates application with basic configuration" do
      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.text_widget("test") do |text|
          text.content("Hello World")
          text.title("Test Widget")
        end
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end

    it "supports event handling configuration" do
      input_received = false
      key_pressed = false

      app = Terminal::ApplicationDSL.application(80, 24) do |builder|
        builder.input_widget("input") do |input|
          input.prompt("Test: ")
        end

        builder.on_input("input") do |text|
          input_received = true
        end

        builder.on_key("escape") do
          key_pressed = true
        end
      end

      app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
    end
  end

  describe "FourQuadrantLayout" do
    it "calculates positions correctly" do
      layout = Terminal::ApplicationDSL::FourQuadrantLayout.new(80, 24)

      layout.top_left("tl", 50, 50)
      layout.top_right("tr", 50, 50)
      layout.bottom_left("bl", 50, 50)
      layout.bottom_right("br", 50, 50)

      areas = layout.areas

      areas["tl"][:x].should eq(0)
      areas["tl"][:y].should eq(0)
      areas["tl"][:width].should eq(40)
      areas["tl"][:height].should eq(12)

      areas["tr"][:x].should eq(40)
      areas["tr"][:y].should eq(0)

      areas["bl"][:x].should eq(0)
      areas["bl"][:y].should eq(12)

      areas["br"][:x].should eq(40)
      areas["br"][:y].should eq(12)
    end

    it "supports full-width sections" do
      layout = Terminal::ApplicationDSL::FourQuadrantLayout.new(80, 24)

      layout.bottom_full("input", 3)
      layout.top_full("header", 2)

      areas = layout.areas

      areas["input"][:x].should eq(0)
      areas["input"][:y].should eq(21)
      areas["input"][:width].should eq(80)
      areas["input"][:height].should eq(3)

      areas["header"][:x].should eq(0)
      areas["header"][:y].should eq(0)
      areas["header"][:width].should eq(80)
      areas["header"][:height].should eq(2)
    end
  end

  describe "GridLayout" do
    it "calculates grid positions correctly" do
      layout = Terminal::ApplicationDSL::GridLayout.new(80, 24, 2, 2)

      layout.cell("c1", 0, 0)
      layout.cell("c2", 0, 1)
      layout.cell("c3", 1, 0)
      layout.cell("c4", 1, 1)

      areas = layout.areas

      areas["c1"][:x].should eq(0)
      areas["c1"][:y].should eq(0)
      areas["c1"][:width].should eq(40)
      areas["c1"][:height].should eq(12)

      areas["c2"][:x].should eq(40)
      areas["c2"][:y].should eq(0)

      areas["c3"][:x].should eq(0)
      areas["c3"][:y].should eq(12)

      areas["c4"][:x].should eq(40)
      areas["c4"][:y].should eq(12)
    end

    it "supports spanning cells" do
      layout = Terminal::ApplicationDSL::GridLayout.new(80, 24, 2, 2)

      layout.cell("span", 0, 0, row_span: 2, col_span: 2)

      areas = layout.areas

      areas["span"][:x].should eq(0)
      areas["span"][:y].should eq(0)
      areas["span"][:width].should eq(80)
      areas["span"][:height].should eq(24)
    end
  end

  describe "LayoutCompositeWidget" do
    it "implements required widget interface" do
      widgets = {} of String => Terminal::Widget
      layout_areas = {} of String => NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)

      composite = Terminal::ApplicationDSL::LayoutCompositeWidget.new(
        widgets, layout_areas, 80, 24
      )

      composite.id.should eq("layout_composite")
      composite.calculate_min_size.width.should eq(80)
      composite.calculate_min_size.height.should eq(24)
    end

    it "handles messages by routing to widgets" do
      text_widget = Terminal::TextBoxWidget.new("test", "content")
      widgets = {"test" => text_widget}
      layout_areas = {"test" => {x: 0, y: 0, width: 40, height: 10}}

      composite = Terminal::ApplicationDSL::LayoutCompositeWidget.new(
        widgets, layout_areas, 80, 24
      )

      # Should not raise - message routing works
      composite.handle(Terminal::Msg::InputEvent.new('a', Time::Span::ZERO))
    end

    it "renders widgets in their layout positions" do
      text_widget = Terminal::TextBoxWidget.new("test", "Hello")
      widgets = {"test" => text_widget}
      layout_areas = {"test" => {x: 10, y: 5, width: 20, height: 5}}

      composite = Terminal::ApplicationDSL::LayoutCompositeWidget.new(
        widgets, layout_areas, 80, 24
      )

      buffer = composite.render(80, 24)

      buffer.size.should eq(24)
      buffer[0].size.should eq(80)

      # Content should be positioned correctly (basic check)
      buffer.should be_a(Array(Array(Terminal::Cell)))
    end
  end

  describe "TextWidgetBuilder" do
    it "builds text widgets with configuration" do
      builder = Terminal::ApplicationDSL::TextWidgetBuilder.new("test")

      builder.content("Test content")
        .title("Test Title")
        .color(:green, :black)
        .auto_scroll(true)
        .border(true)

      widget = builder.build

      widget.id.should eq("test")
      widget.should be_a(Terminal::TextBoxWidget)
    end
  end

  describe "InputWidgetBuilder" do
    it "builds input widgets with configuration" do
      builder = Terminal::ApplicationDSL::InputWidgetBuilder.new("input")

      builder.prompt("Enter: ", "blue")
        .placeholder("Type here...")
        .max_length(100)

      widget = builder.build

      widget.id.should eq("input")
      widget.should be_a(Terminal::InputWidget)
    end

    it "supports submit handler configuration" do
      submitted_text = ""

      builder = Terminal::ApplicationDSL::InputWidgetBuilder.new("input")
      builder.on_submit { |text| submitted_text = text }

      builder.submit_handler.should_not be_nil
    end
  end
end
