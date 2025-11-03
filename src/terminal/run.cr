require "signal"
require "../terminal/stop_handler"

module Terminal
  def self.run(
    width : Int32 = 80,
    height : Int32 = 24,
    signals : Array(Signal) = [Signal::INT],
    exit_key : String? = "escape",
    stop_message : Proc(Terminal::Msg::Any) = -> { Terminal::Msg::Stop.new("terminal.run") },
    io : IO = STDOUT,
    input_provider : Terminal::InputProvider? = nil,
    configure : Proc(Terminal::TerminalApplication(Terminal::Widget), Nil)? = nil,
    &block : UI::Builder -> Nil
  ) : Terminal::TerminalApplication(Terminal::Widget)
    application = app(width: width, height: height, io: io, input_provider: input_provider) do |builder|
      block.call(builder)
    end

    configure.try &.call(application)

    cleanup = nil
    unless signals.empty?
      cleanup = StopHandler.install_signal_forwarders(application.message_channel, signals, stop_message)
    end

    if exit_key
      application.widget_manager.register_key_handler(exit_key, true) do
        application.dispatch(stop_message.call)
      end
    end

    application.start
    cleanup.try &.call
    application
  end
end
