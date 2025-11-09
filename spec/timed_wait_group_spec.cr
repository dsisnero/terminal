require "./spec_helper"

describe Terminal::TimedWaitGroup do
  it "returns true immediately when no work is pending" do
    wg = Terminal::TimedWaitGroup.new
    wg.wait(5.milliseconds).should be_true
  end

  it "waits for pending work to finish before timeout" do
    wg = Terminal::TimedWaitGroup.new
    wg.add

    spawn do
      sleep 5.milliseconds
      wg.done
    end

    wg.wait(50.milliseconds).should be_true
  end

  it "times out when work does not finish" do
    wg = Terminal::TimedWaitGroup.new
    wg.add

    wg.wait(5.milliseconds).should be_false
    wg.done
  end
end
