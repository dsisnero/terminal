require "./spec_helper"

private class CaptureDispatcher(T)
  getter updates : Array(Terminal::Msg::Any) = [] of Terminal::Msg::Any

  def initialize(@dispatcher : Terminal::Dispatcher(T), @system_chan : Channel(Terminal::Msg::Any), @buffer_chan : Channel(Terminal::Msg::Any))
    @frames = Channel(Nil).new(4)
    @done = Channel(Nil).new(1)
  end

  def start
    @dispatcher.start(@system_chan, @buffer_chan)
    spawn do
      loop do
        msg = @buffer_chan.receive
        @updates << msg
        @frames.send(nil) if msg.is_a?(Terminal::Msg::ScreenUpdate)
        break if msg.is_a?(Terminal::Msg::Stop)
      end
      @done.send(nil)
    end
  end

  def wait_frame
    @frames.receive
  end

  def stop
    @system_chan.send(Terminal::Msg::Stop.new)
    @done.receive
  end
end

describe "UI builder integration" do
  it "routes input events through dispatcher and updates widgets" do
    app = Terminal.app(width: 20, height: 6) do |builder|
      builder.layout do |layout|
        layout.vertical do
          layout.widget "log", Terminal::UI::Constraint.length(3)
          layout.widget "input", Terminal::UI::Constraint.length(3)
        end
      end

      builder.text_box "log" do |box|
        box.set_text("Ready")
        box.auto_scroll = true
      end

      builder.input "input" do |input|
        input.prompt("> ")
      end
    end

    system_chan = Channel(Terminal::Msg::Any).new
    buffer_chan = Channel(Terminal::Msg::Any).new
    dispatcher = Terminal::Dispatcher(Terminal::Widget).new(app.widget_manager, 20, 6)
    capture = CaptureDispatcher(Terminal::Widget).new(dispatcher, system_chan, buffer_chan)

    capture.start

    system_chan.send(Terminal::Msg::Command.new("focus_next"))
    capture.wait_frame

    system_chan.send(Terminal::Msg::InputEvent.new('h', Time::Span.zero))
    capture.wait_frame

    system_chan.send(Terminal::Msg::InputEvent.new('i', Time::Span.zero))
    capture.wait_frame

    capture.stop
    system_chan.close
    buffer_chan.close

    grid = app.widget_manager.compose(20, 6)
    input_row = grid[3].map(&.char).join
    input_row.should contain("hi")

    screen_updates = capture.updates.select(Terminal::Msg::ScreenUpdate)
    screen_updates.should_not be_empty
  end
end
