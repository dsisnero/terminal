#!/usr/bin/env crystal

require "option_parser"
require "file_utils"

module Terminal
  module Scripts
    class ExampleRunner
      def initialize(@argv : Array(String))
        @log = false
        @example = ""
        @extra = [] of String
      end

      def run
        parse_args
        example_path = resolve_example(@example)
        cache_dir = File.join("temp", "crystal_cache")
        FileUtils.mkdir_p(cache_dir)

        env = {
          "CRYSTAL_CACHE_DIR"    => cache_dir,
          "TERMINAL_USE_HARNESS" => "1",
        }
        env["TERMINAL_HARNESS_LOG"] = "1" if @log

        cmd = ["run", example_path] + @extra
        shell = ENV["TERMINAL_SHELL"]? || "/bin/bash"
        joined = cmd.join(" ")
        status = Process.run(shell, ["-lc", "crystal #{joined}"], env: env, input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
        exit(status.exit_code)
      end

      private def parse_args
        args = @argv.dup
        if idx = args.index("--")
          @extra = args[(idx + 1)..] || [] of String
          args = args[0...idx]
        end

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: crystal run scripts/run_example.cr [options] <example>"

          opts.on("-l", "--log", "Stream harness log messages to STDERR") { @log = true }
          opts.on("-h", "--help", "Show this help") do
            puts opts
            exit
          end
        end

        parser.unknown_args do |unknown|
          unknown.each { |arg| @example = arg }
        end

        parser.parse(args)

        return unless @example.empty?

        STDERR.puts parser
        exit 1
      end

      private def resolve_example(name : String) : String
        base = name.ends_with?(".cr") ? name : "#{name}.cr"
        path = File.join("examples", base)
        unless File.file?(path)
          STDERR.puts "Example not found: #{path}"
          exit 1
        end
        path
      end
    end
  end
end

Terminal::Scripts::ExampleRunner.new(ARGV).run
