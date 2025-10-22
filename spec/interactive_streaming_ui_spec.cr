require "spec"
require "../src/terminal/interactive_streaming_ui"

describe Terminal::InteractiveStreamingUI do
  describe "initialization" do
    it "creates with default prompt and IOs" do
      ui = Terminal::InteractiveStreamingUI.new
      ui.prompt.should eq("> ")
      ui.output.should eq(STDOUT)
      ui.input.should eq(STDIN)
    end

    it "creates with custom prompt" do
      ui = Terminal::InteractiveStreamingUI.new(prompt: ">> ")
      ui.prompt.should eq(">> ")
    end

    it "creates with custom IOs" do
      input = IO::Memory.new("test\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)
      ui.output.should eq(output)
      ui.input.should eq(input)
    end
  end

  describe "#run" do
    it "displays prompt and processes single input" do
      input = IO::Memory.new("hello\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(prompt: "> ", output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, io|
        received_commands << cmd
        io << "Response: #{cmd}"
      end

      received_commands.should eq(["hello"])
      output.to_s.should contain("> ")
      output.to_s.should contain("Response: hello")
    end

    it "processes multiple inputs before exit" do
      input = IO::Memory.new("first\nsecond\nthird\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, io|
        received_commands << cmd
        io << "OK"
      end

      received_commands.should eq(["first", "second", "third"])
    end

    it "exits on EOF (nil input)" do
      input = IO::Memory.new("")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      call_count = 0
      ui.run do |_, _|
        call_count += 1
      end

      call_count.should eq(0)
    end

    it "exits when user types 'exit'" do
      input = IO::Memory.new("command\nexit\nshould not see this\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, _|
        received_commands << cmd
      end

      received_commands.should eq(["command"])
    end

    it "exits when user types 'EXIT' (case insensitive)" do
      input = IO::Memory.new("command\nEXIT\nshould not see this\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, _|
        received_commands << cmd
      end

      received_commands.should eq(["command"])
    end

    it "skips empty lines" do
      input = IO::Memory.new("first\n\n  \nsecond\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, _|
        received_commands << cmd
      end

      received_commands.should eq(["first", "second"])
    end

    it "trims whitespace from input" do
      input = IO::Memory.new("  spaced command  \nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, _|
        received_commands << cmd
      end

      received_commands.should eq(["spaced command"])
    end

    it "allows handler to stream tokens incrementally" do
      input = IO::Memory.new("stream test\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      ui.run do |_, io|
        # Simulate streaming: write tokens one at a time
        ["Hello", " ", "world", "!"].each do |token|
          io << token
          io.flush
        end
      end

      output.to_s.should contain("Hello world!")
    end

    it "adds newline after each handler invocation" do
      input = IO::Memory.new("one\ntwo\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      ui.run do |_, io|
        io << "Response"
      end

      # Should have: prompt, response, newline for each command
      result = output.to_s
      result.scan(/Response\n/).size.should eq(2)
    end

    it "flushes output after prompt" do
      input = IO::Memory.new("test\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(prompt: "$ ", output: output, input: input)

      ui.run do |_, io|
        io << "ok"
      end

      # Output should start with prompt
      output.to_s.should match(/^\$ /)
    end

    it "handles handler that writes nothing" do
      input = IO::Memory.new("silent\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      ui.run do |_, _|
        # Handler does nothing
      end

      # Should still have prompt and newline
      output.to_s.should contain("> ")
    end

    it "processes commands with special characters" do
      input = IO::Memory.new("cmd with $pecial & chars!\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received_commands = [] of String
      ui.run do |cmd, _|
        received_commands << cmd
      end

      received_commands.should eq(["cmd with $pecial & chars!"])
    end

    it "supports multi-line session simulation" do
      input = IO::Memory.new("What is 2+2?\nTell me a joke\nGoodbye\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      conversation = [] of {String, String}
      ui.run do |cmd, io|
        response = case cmd
                   when "What is 2+2?"
                     "4"
                   when "Tell me a joke"
                     "Why did the crystal break? It had a fatal flaw!"
                   when "Goodbye"
                     "See you!"
                   else
                     "I don't understand"
                   end
        conversation << {cmd, response}
        io << response
      end

      conversation.size.should eq(3)
      conversation[0].should eq({"What is 2+2?", "4"})
      conversation[1].should eq({"Tell me a joke", "Why did the crystal break? It had a fatal flaw!"})
      conversation[2].should eq({"Goodbye", "See you!"})
    end
  end

  describe "custom prompt" do
    it "uses custom prompt string" do
      input = IO::Memory.new("test\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(prompt: "AI> ", output: output, input: input)

      ui.run do |_, io|
        io << "response"
      end

      output.to_s.should contain("AI> ")
      # Verify it starts with the custom prompt, not the default
      output.to_s.should match(/^AI> /)
    end

    it "supports emoji and unicode in prompt" do
      input = IO::Memory.new("hello\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(prompt: "🤖 > ", output: output, input: input)

      ui.run do |_, io|
        io << "Hi!"
      end

      output.to_s.should contain("🤖 > ")
    end
  end

  describe "error handling" do
    it "continues on handler errors if handler manages them" do
      input = IO::Memory.new("good\nbad\ngood again\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      received = [] of String
      ui.run do |cmd, io|
        received << cmd
        if cmd == "bad"
          io << "Error occurred!"
        else
          io << "OK"
        end
      end

      received.should eq(["good", "bad", "good again"])
    end
  end

  describe "integration scenarios" do
    it "simulates a simple Q&A bot" do
      input = IO::Memory.new("hello\nhelp\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(prompt: "Bot> ", output: output, input: input)

      ui.run do |cmd, io|
        response = case cmd.downcase
                   when "hello"
                     "Hi there!"
                   when "help"
                     "Available commands: hello, help, exit"
                   else
                     "Unknown command"
                   end
        io << response
      end

      result = output.to_s
      result.should contain("Hi there!")
      result.should contain("Available commands")
    end

    it "simulates streaming AI response" do
      input = IO::Memory.new("Tell me about Crystal\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      ui.run do |_, io|
        # Simulate streaming tokens
        tokens = ["Crystal", " is", " a", " fast", " language", "."]
        tokens.each do |token|
          io << token
        end
      end

      output.to_s.should contain("Crystal is a fast language.")
    end

    it "works with different IO types" do
      # Using StringIO-like behavior via IO::Memory
      input = IO::Memory.new("input text\nexit\n")
      output = IO::Memory.new
      ui = Terminal::InteractiveStreamingUI.new(output: output, input: input)

      ui.run do |cmd, io|
        io << "Processed: #{cmd}"
      end

      output.to_s.should contain("Processed: input text")
    end
  end
end
