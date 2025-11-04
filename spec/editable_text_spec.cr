require "./spec_helper"

describe Terminal::EditableText do
  it "inserts characters respecting cursor" do
    value, cursor = Terminal::EditableText.insert("abc", 1, 'X')
    value.should eq("aXbc")
    cursor.should eq(2)
  end

  it "deletes before cursor" do
    value, cursor = Terminal::EditableText.delete_before("abc", 2)
    value.should eq("ac")
    cursor.should eq(1)
  end

  it "deletes at cursor" do
    value, cursor = Terminal::EditableText.delete_at("abc", 1)
    value.should eq("ac")
    cursor.should eq(1)
  end

  it "moves cursor within bounds" do
    Terminal::EditableText.move_cursor("abc", 1, -2).should eq(0)
    Terminal::EditableText.move_cursor("abc", 1, 10).should eq(3)
  end

  it "honours max length when inserting" do
    value, cursor = Terminal::EditableText.insert("abc", 3, 'd', 3)
    value.should eq("abc")
    cursor.should eq(3)
  end
end
