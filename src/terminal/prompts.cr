# Lightweight prompt helpers for CLI applications.
# Provides synchronous `ask` and `password` methods that can be mixed in or
# called directly, reusing shared TTY raw-mode utilities.

require "io"
require "./tty"

module Terminal
  module Prompts
    DEFAULT_MASK_CHAR = '*'

    class PromptInterrupted < Exception; end

    def self.ask(prompt : String, mask_char : Char? = nil, input : IO = STDIN, output : IO = STDOUT) : String
      Session.new(prompt: prompt, mask_char: mask_char).run(input, output)
    end

    def self.password(prompt : String = "Password:", mask_char : Char = DEFAULT_MASK_CHAR, input : IO = STDIN, output : IO = STDOUT) : String
      ask(prompt, mask_char: mask_char, input: input, output: output)
    end

    # Allow mixin style usage (`include Terminal::Prompts`)
    def ask(prompt : String, mask_char : Char? = nil, input : IO = STDIN, output : IO = STDOUT) : String
      Terminal::Prompts.ask(prompt, mask_char: mask_char, input: input, output: output)
    end

    def password(prompt : String = "Password:", mask_char : Char = DEFAULT_MASK_CHAR, input : IO = STDIN, output : IO = STDOUT) : String
      Terminal::Prompts.password(prompt, mask_char: mask_char, input: input, output: output)
    end

    private class Session
      def initialize(@prompt : String, @mask_char : Char?)
      end

      def run(input : IO, output : IO) : String
        buffer = [] of Char
        line_finished = false

        write_prompt(output)

        begin
          Terminal::TTY.with_raw_mode(input) do
            loop do
              ch = read_char(input)
              break if ch.nil?

              case ch
              when '\n', '\r'
                break
              when '\u0003'
                raise PromptInterrupted.new
              when '\u0008', '\u007f'
                if buffer.pop?
                  erase_char(output)
                end
              else
                buffer << ch
                echo_char(output, ch)
              end
            end
          end

          finish_line(output)
          line_finished = true

          build_string(buffer)
        rescue ex
          finish_line(output) unless line_finished
          raise ex
        end
      end

      private def write_prompt(io : IO)
        io << @prompt
        io << " " unless @prompt.ends_with?(" ")
        io.flush
      end

      private def echo_char(io : IO, char : Char)
        io << (@mask_char || char)
        io.flush
      end

      private def erase_char(io : IO)
        io << "\b \b"
        io.flush
      end

      private def finish_line(io : IO)
        io << '\n'
        io.flush
      end

      private def read_char(io : IO) : Char?
        io.read_char
      rescue IO::EOFError
        nil
      end

      private def build_string(chars : Array(Char)) : String
        String.build do |builder|
          chars.each { |ch| builder << ch }
        end
      end
    end
  end
end
