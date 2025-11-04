ENV["TERM_DEMO_SKIP_MAIN"] = "1"
require "../spec_helper"
require "../../examples/interactive_builder_demo"
ENV.delete("TERM_DEMO_SKIP_MAIN")

describe Examples::InteractiveBuilderDemo do
  it "supports editing, status updates, and commands" do
    harness = Terminal::RuntimeHarness::Controller.new(auto_dispatch: false)
    builder = Terminal::UI::Builder.new(80, 22, harness)

    Examples::InteractiveBuilderDemo.build(builder)

    input = builder.widget!("input").as(Terminal::InputWidget)
    log_box = builder.widget!("log").as(Terminal::TextBoxWidget)
    status_box = builder.widget!("status").as(Terminal::TextBoxWidget)

    status_box.content.should contain("Messages: 0")
    status_box.content.should contain("Commands: 0")

    input.handle(Terminal::Msg::InputEvent.new('A', Time::Span.zero))
    input.handle(Terminal::Msg::InputEvent.new('B', Time::Span.zero))
    input.handle(Terminal::Msg::InputEvent.new('\u{7f}', Time::Span.zero))
    input.value.should eq("A")

    "lpha".each_char do |ch|
      input.handle(Terminal::Msg::InputEvent.new(ch, Time::Span.zero))
    end
    input.handle(Terminal::Msg::KeyPress.new("enter"))

    status_box.content.should contain("Messages: 1")

    "/stats".each_char do |ch|
      input.handle(Terminal::Msg::InputEvent.new(ch, Time::Span.zero))
    end
    input.handle(Terminal::Msg::KeyPress.new("enter"))

    status_box.content.should contain("Commands: 1")
    status_box.content.should contain("Last command: /stats")

    "/quit".each_char do |ch|
      input.handle(Terminal::Msg::InputEvent.new(ch, Time::Span.zero))
    end
    input.handle(Terminal::Msg::KeyPress.new("enter"))

    harness.wait_for_stop.should eq(:quit)

    content = log_box.content
    content.should contain("You: Alpha")
    content.should contain("System: Echo -> ALPHA")
    content.should contain("System: Messages sent: 1")
    content.should contain("You: /quit")
    content.should contain("System: /quit received, stopping...")
  end
end
