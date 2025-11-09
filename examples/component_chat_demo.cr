# Component model demo using the Terminal::Components API.

require "../src/terminal"

module Examples
  struct ComponentChatModel
    property messages : Array(String)
    property status : String

    def initialize
      @messages = ["Welcome to the component chat demo!"]
      @status = "Ready"
    end
  end

  class ComponentChat < Terminal::Components::Component(ComponentChatModel)
    alias Model = ComponentChatModel

    @program : Terminal::Components::Program(Model)?

    def initial_model : Model
      Model.new
    end

    def layout(layout : Terminal::Components::LayoutDSL) : Nil
      layout.compose do
        layout.column do
          layout.text_box :chat, layout.flex, auto_scroll: true do |box|
            box.can_focus = false
          end

          layout.text_box :status, layout.length(3), can_focus: false do |box|
            box.auto_scroll = false
          end

          layout.input :input, layout.length(3), prompt: "You: "
        end
      end
    end

    def render(model : Model, view : Terminal::Components::ViewContext) : Nil
      view.text_box(:chat).set_text(model.messages.join("\n"))
      view.text_box(:status).set_text("Status: #{model.status}\nEsc to quit · Ctrl+C to force exit")
    end

    def update(event, model : Model) : Model
      case event
      when Terminal::Components::Events::InputSubmitted
        text = event.value.strip
        return model if text.empty?

        @program.try &.record("submitted: #{text}")

        if {"/quit", "quit", "exit"}.includes?(text.downcase)
          model.status = "Exiting…"
          @program.try &.stop("user_exit")
          return model
        end

        model.messages << "You: #{text}"
        model.messages << "Echo: #{text.reverse}"
        model.status = "Responded at #{Time.local.to_s("%H:%M:%S")}"
      when Terminal::Components::Events::KeyPressed
        @program.try &.record("key: #{event.key}")
        if event.key == "escape"
          model.status = "Press Ctrl+C to exit"
        end
      when Terminal::Components::Events::Tick
        @program.try &.record("tick: #{Time.local}")
        model.status = "Tick #{Time.local.to_s("%H:%M:%S")}"
      end
      model
    end

    def configure(program : Terminal::Components::Program(Model)) : Nil
      @program = program
      program.focus(:input)
      program.on_key(:escape) do
        program.dispatch(Terminal::Components::Events::KeyPressed.new("escape"))
        program.stop("escape")
        nil
      end
      program.on_key("ctrl+c") do
        program.stop("ctrl_c")
        nil
      end
      program.every(3.seconds) do
        program.dispatch(Terminal::Components::Events::Tick.new("status"))
      end
    end
  end
end

stem = File.basename(__FILE__, ".cr")
if PROGRAM_NAME.includes?(stem) && !ENV["TERM_DEMO_SKIP_MAIN"]?
  harness = Terminal::RuntimeHarness::Controller.new
  program = Terminal::Components.run(Examples::ComponentChat.new, width: 80, height: 24, harness: harness)
  harness.wait_for_stop
  program.stop("demo_exit")
end
