require "./spec_helper"

describe Terminal::WindowsKeyMap do
  it "maps navigation keys" do
    Terminal::WindowsKeyMap.lookup(75_u16).should eq("left")
    Terminal::WindowsKeyMap.lookup(77_u16).should eq("right")
    Terminal::WindowsKeyMap.lookup(72_u16).should eq("up")
    Terminal::WindowsKeyMap.lookup(80_u16).should eq("down")
  end

  it "maps paging and insert/delete keys" do
    Terminal::WindowsKeyMap.lookup(73_u16).should eq("page_up")
    Terminal::WindowsKeyMap.lookup(81_u16).should eq("page_down")
    Terminal::WindowsKeyMap.lookup(82_u16).should eq("insert")
    Terminal::WindowsKeyMap.lookup(83_u16).should eq("delete")
  end

  it "maps function keys" do
    Terminal::WindowsKeyMap.lookup(59_u16).should eq("f1")
    Terminal::WindowsKeyMap.lookup(68_u16).should eq("f10")
    Terminal::WindowsKeyMap.lookup(133_u16).should eq("f11")
    Terminal::WindowsKeyMap.lookup(134_u16).should eq("f12")
  end

  it "returns nil for unknown codes" do
    Terminal::WindowsKeyMap.lookup(0_u16).should be_nil
  end
end
