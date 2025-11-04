# File: src/terminal/runtime_harness.cr
# Provides a reusable controller that allows applications to expose hooks for
# deterministic testing. When attached to `Terminal.app` or `Terminal.run`,
# specs can capture log messages, trigger graceful shutdowns, and wait for the
# application to stop without writing demo-specific glue code.

module Terminal
  module RuntimeHarness
    class Controller
      getter logs : Array(String)
      getter stop_reason : Symbol?
      getter auto_dispatch : Bool

      def initialize(
        @auto_dispatch : Bool = true,
        stop_message : Proc(Symbol, Terminal::Msg::Any) | Proc(Symbol, Terminal::Msg::Stop) = ->(reason : Symbol) { Terminal::Msg::Stop.new("runtime-harness:#{reason}") },
      )
        @logs = [] of String
        @stop_channel = Channel(Symbol).new(1)
        @stop_reason = nil
        @application = nil.as(Terminal::TerminalApplication(Terminal::Widget)?)
        @stop_message = ->(reason : Symbol) : Terminal::Msg::Any { stop_message.call(reason) }
      end

      def bind(app : Terminal::TerminalApplication(Terminal::Widget))
        @application = app
        return unless @auto_dispatch

        spawn do
          reason = wait_for_stop
          dispatch_stop(reason)
        end
      end

      def record(message : String)
        @logs << message
      end

      def stop(reason : Symbol = :external)
        notify(reason)
        unless @auto_dispatch
          spawn { dispatch_stop(reason) }
        end
      end

      def wait_for_stop : Symbol
        if reason = @stop_reason
          reason
        else
          @stop_reason = @stop_channel.receive
          @stop_reason.not_nil!
        end
      end

      def dispatch_stop(reason : Symbol)
        return unless app = @application
        app.dispatch(@stop_message.call(reason))
      end

      def stop_message(reason : Symbol) : Terminal::Msg::Any
        @stop_message.call(reason)
      end

      def logs? : Array(String)
        @logs
      end

      private def notify(reason : Symbol)
        return if @stop_reason
        @stop_reason = reason
        @stop_channel.send(reason)
      end
    end
  end
end
