module Terminal
  # InteractiveStreamingUI provides a simple prompt/response loop
  # that streams output to the provided IO as tokens are produced
  # by the given handler block.
  #
  # It is intentionally decoupled from any AI/LLM types. The caller
  # supplies a block that receives the input String and an IO to write
  # streamed output to. The block is responsible for writing tokens and
  # returning when the response is complete.
  class InteractiveStreamingUI
    getter prompt : String
    getter output : IO
    getter input : IO

    def initialize(@prompt : String = "> ", @output : IO = STDOUT, @input : IO = STDIN)
    end

    # Runs the interactive loop until EOF or the user types 'exit'.
    # The handler block is called for each non-empty input; it should
    # write streamed output to the provided IO and return when finished.
    def run(&handler : String, IO -> Nil) : Nil
      loop do
        @output << @prompt
        @output.flush

        line = read_line
        break if line.nil?

        cmd = line.not_nil!.strip
        break if cmd.downcase == "exit"
        next if cmd.empty?

        handler.call(cmd, @output)
        @output << "\n"
        @output.flush
      end
    end

    private def read_line : String?
      # Read a line from @input in a way that works with STDIN
      # and custom IOs.
      if @input.responds_to?(:gets)
        # :nodoc: STDIN, File, IO::Memory etc.
        (@input.as(IO)).gets
      end
    end
  end
end
