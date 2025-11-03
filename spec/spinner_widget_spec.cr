require "./spec_helper"

describe Terminal::SpinnerWidget do
  it "advances animation frame on render request" do
    spinner = Terminal::SpinnerWidget.new("sp", "Loading")
    initial = spinner.render(10, 1).first.map(&.char).join

    spinner.handle(Terminal::Msg::RenderRequest.new("tick", ""))
    after = spinner.render(10, 1).first.map(&.char).join

    initial.should_not eq(after)
  end

  it "respects provided dimensions" do
    spinner = Terminal::SpinnerWidget.new("sp", "Go")
    grid = spinner.render(12, 2)

    grid.size.should eq(2)
    grid[0].size.should eq(12)
    grid[1].all?(&.char.==(' ')).should be_true
  end
end
