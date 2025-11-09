require "./spec_helper"

describe Terminal::Msg do
  it "creates stop messages with optional reasons" do
    default = Terminal::Msg::Stop.new
    default.reason.should be_nil

    stop = Terminal::Msg::Stop.new("test")
    stop.reason.should eq("test")
  end

  it "wraps screen updates and diffs" do
    update = Terminal::Msg::ScreenUpdate.new(["foo", "bar"])
    update.content.should eq(["foo", "bar"])

    cells = [Terminal::Cell.new('x')]
    diff = Terminal::Msg::ScreenDiff.new([{0, "foo"}, {1, cells}])
    diff.changes.size.should eq(2)
    diff.changes.first.should eq({0, "foo"})
    diff.changes.last.should eq({1, cells})
  end

  it "supports widget events with cell payloads" do
    payload = [Terminal::Cell.new('a')]
    event = Terminal::Msg::WidgetEvent.new("input", payload)
    event.widget_id.should eq("input")
    event.payload.should eq(payload)
  end

  it "aliases copy-to-clipboard as Msg::Any" do
    copy = Terminal::Msg::CopyToClipboard.new("hello")
    any : Terminal::Msg::Any = copy
    any.should be_a(Terminal::Msg::CopyToClipboard)
  end
end
