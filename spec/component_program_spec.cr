require "./spec_helper"
require "../examples/component_chat_demo"

private struct TestComponentModel
  property lines : Array(String)

  def initialize
    @lines = [] of String
  end
end

private class TestComponent < Terminal::Components::Component(TestComponentModel)
  alias Model = TestComponentModel

  def initial_model : Model
    Model.new
  end

  def layout(layout : Terminal::Components::LayoutDSL) : Nil
    layout.compose do
      layout.column do
        layout.text_box :log, layout.flex, auto_scroll: true do |box|
          box.can_focus = false
        end
        layout.input :input, layout.length(1), prompt: "> "
      end
    end
  end

  def render(model : Model, view : Terminal::Components::ViewContext) : Nil
    view.text_box(:log).set_text(model.lines.join("\n"))
  end

  def update(event, model : Model) : Model
    case event
    when Terminal::Components::Events::InputSubmitted
      model.lines << event.value
    end
    model
  end
end

describe Terminal::Components::Program do
  it "updates widgets when dispatching events" do
    harness = Terminal::RuntimeHarness::Controller.new
    program = Terminal::Components::Program(TestComponentModel).new(
      TestComponent.new,
      width: 40,
      height: 6,
      harness: harness
    )

    program.dispatch(Terminal::Components::Events::InputSubmitted.new("input", "hello"))
    program.dispatch(Terminal::Components::Events::InputSubmitted.new("input", "world"))

    log = program.view.text_box(:log)
    log.content.should contain("hello")
    log.content.should contain("world")
  end

  it "handles input widget submissions via enter key" do
    harness = Terminal::RuntimeHarness::Controller.new(auto_dispatch: false)
    program = Terminal::Components::Program(Examples::ComponentChatModel).new(
      Examples::ComponentChat.new,
      width: 60,
      height: 12,
      harness: harness
    )

    input_handle = program.view.input(:input)
    input_handle.set_value("hello world")

    input_handle.widget.handle(Terminal::Msg::KeyPress.new("enter"))

    chat_content = program.view.text_box(:chat).content
    status_content = program.view.text_box(:status).content

    chat_content.should contain("You: hello world")
    status_content.should contain("Responded")
  end
end
