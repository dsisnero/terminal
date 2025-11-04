require "signal"

module Terminal
  module SpecSupport
    module Runtime
      struct Result
        getter app : Terminal::TerminalApplication(Terminal::Widget)
        getter output : IO::Memory

        def initialize(@app : Terminal::TerminalApplication(Terminal::Widget), @output : IO::Memory)
        end
      end

      # Run a builder block using `Terminal.run` inside tests. Returns the
      # application and the IO::Memory used for rendering. Specs can call
      # `result.app.widget_manager.compose(width, height)` to inspect the final
      # frame once the helper returns.
      def self.run(
        width : Int32 = 40,
        height : Int32 = 10,
        signals : Array(Signal) = [] of Signal,
        exit_key : String? = nil,
        stop_after : Time::Span? = 5.milliseconds,
        input_provider : Terminal::InputProvider? = Terminal::DummyInputProvider.new,
        compose_after_stop : Bool = false,
        harness : Terminal::RuntimeHarness::Controller? = nil,
        &block : UI::Builder -> Nil
      ) : Result
        output = IO::Memory.new
        configure = ->(application : Terminal::TerminalApplication(Terminal::Widget)) {
          if stop_after
            spawn do
              sleep stop_after
              if harness
                harness.stop(:timeout)
              else
                application.dispatch(Terminal::Msg::Stop.new("spec-runtime"))
              end
            end
          end
        }

        app = Terminal.run(
          width: width,
          height: height,
          signals: signals,
          exit_key: exit_key,
          stop_message: -> { Terminal::Msg::Stop.new("spec-runtime") },
          io: output,
          input_provider: input_provider,
          harness: harness,
          configure: configure,
          &block
        )

        if compose_after_stop
          app.widget_manager.compose(width, height)
        end

        Result.new(app, output)
      end
    end
  end
end
