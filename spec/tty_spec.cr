require "./spec_helper"

describe Terminal::TTY do
  it "yields for non-tty IO without modification" do
    io = IO::Memory.new
    yielded = false

    Terminal::TTY.with_raw_mode(io) do
      yielded = true
      io << "hello"
    end

    yielded.should be_true
    io.rewind
    io.gets_to_end.should eq("hello")
  end
end
