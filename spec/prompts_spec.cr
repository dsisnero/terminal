require "./spec_helper"

class PromptHarness
  include Terminal::Prompts
end

describe Terminal::Prompts do
  describe ".password" do
    it "returns masked input and writes mask characters" do
      input = IO::Memory.new("hunter2\n")
      output = IO::Memory.new

      result = Terminal::Prompts.password("Password:", input: input, output: output)

      result.should eq("hunter2")
      expected = "Password: " + ("*" * result.size) + '\n'
      output.to_s.should eq(expected)
    end

    it "supports backspace editing" do
      input = IO::Memory.new("foo\b\bbar\n")
      output = IO::Memory.new

      result = Terminal::Prompts.password("Password:", input: input, output: output)

      result.should eq("fbar")
      rendered = output.to_s
      rendered.should eq("Password: ***\b \b\b \b***\n")
    end

    it "is available as a mixin helper" do
      input = IO::Memory.new("s3cret\n")
      output = IO::Memory.new
      result = PromptHarness.new.password("Secret:", mask_char: '#', input: input, output: output)

      result.should eq("s3cret")
      expected = "Secret: " + ("#" * result.size) + '\n'
      output.to_s.should eq(expected)
    end
  end

  describe ".ask" do
    it "echoes input when no mask is requested" do
      input = IO::Memory.new("alice\n")
      output = IO::Memory.new

      result = Terminal::Prompts.ask("Name:", input: input, output: output)

      result.should eq("alice")
      output.to_s.should eq("Name: alice\n")
    end
  end
end
