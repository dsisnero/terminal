require "./src/terminal/messages"
require "./src/terminal/widget_manager"

widget = BasicWidget.new("w1", "start")
wm = WidgetManager(BasicWidget).new([widget])

puts "Initial content: #{widget.@content}"

wm.route_to_focused(Terminal::Msg::InputEvent.new('A', Time::Span.zero))

puts "After input: #{widget.@content}"

frame = wm.compose(5, 1)
puts "Frame chars: #{frame.flatten.map(&.char).join}"