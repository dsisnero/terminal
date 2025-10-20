# File: spec/widget_event_routing_spec.cr
# Purpose: Tests for WidgetManager routing, focus switching, and frame composition.

require "spec"
require "../src/terminal/messages"
require "../src/terminal/widget_manager"

describe WidgetManager do
  it "routes input to focused widget" do
    widget = BasicWidget.new("w1", "start")
    wm = WidgetManager(BasicWidget).new([widget])

    wm.route_to_focused(Terminal::Msg::InputEvent.new('A', Time::Span.zero))
    frame = wm.compose(6, 1)

    frame[0][0].char.should eq 's'
    frame.flatten.map(&.char).join.should contain("startA")
  end

  it "switches focus to next widget" do
    a = BasicWidget.new("a", "A")
    b = BasicWidget.new("b", "B")
    wm = WidgetManager.new([a, b])

    wm.focus_next
    wm.route_to_focused(Terminal::Msg::InputEvent.new('X', Time::Span.zero))

    frame = wm.compose(2, 1)
    chars = frame.flatten.map(&.char).join

    chars.should contain('B')
    chars.should_not contain('A')
  end
end