require "./spec_helper"

{% unless flag?(:win32) %}
  describe Terminal::RawInputProvider::Parser do
    it "emits input events for plain characters" do
      chan = Channel(Terminal::Msg::Any).new(2)
      parser = Terminal::RawInputProvider::Parser.new(chan)

      parser.consume("ab")

      first = chan.receive
      second = chan.receive
      first.should be_a(Terminal::Msg::InputEvent)
      first.as(Terminal::Msg::InputEvent).char.should eq('a')
      second.as(Terminal::Msg::InputEvent).char.should eq('b')
    end

    it "emits paste events for bracketed paste sequences" do
      chan = Channel(Terminal::Msg::Any).new(1)
      parser = Terminal::RawInputProvider::Parser.new(chan)

      parser.consume("\e[200~hello world\e[201~")

      event = chan.receive
      event.should be_a(Terminal::Msg::PasteEvent)
      event.as(Terminal::Msg::PasteEvent).content.should eq("hello world")
    end
  end
{% end %}
