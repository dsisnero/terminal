require "./spec_helper"

describe Terminal::SpecSupport::Runtime do
  it "allows composing the final frame" do
    runtime = Terminal::SpecSupport::Runtime.run(width: 20, height: 4, stop_after: 5.milliseconds) do |builder|
      builder.text_box("header", &.set_text("Runtime Helper"))
    end

    grid = runtime.app.widget_manager.compose(20, 4)
    grid.map(&.map(&.char).join).any?(&.includes?("Runtime Helper")).should be_true
  end
end
