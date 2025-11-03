require "atomic"
require "signal"

module Terminal
  module StopHandler
    CTRL_C_MESSAGE = -> { Terminal::Msg::Stop.new("SIGINT") }

    def self.install_signal_forwarders(channel : Channel(Terminal::Msg::Any), signals : Array(Signal) = [Signal::INT], message : Proc(Terminal::Msg::Any) = CTRL_C_MESSAGE)
      triggered = Atomic(Bool).new(false)
      previous = signals.map do |signal|
        handler = signal.trap do
          next if triggered.swap(true)
          begin
            channel.send(message.call)
          rescue
          end
        end
        {signal, handler}
      end

      -> {
        previous.each do |signal, handler|
          if handler
            signal.trap(&handler)
          else
            signal.reset
          end
        end
      }
    end
  end
end
