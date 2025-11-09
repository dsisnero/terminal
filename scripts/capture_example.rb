#!/usr/bin/env ruby
# Capture the ANSI output of an example by running it inside a PTY.

require "optparse"
require "fileutils"
require "pty"

options = {
  log: false,
  extra: [],
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: scripts/capture_example.rb [options] <example>"
  opts.on("-o", "--output PATH", "Write transcript to PATH (defaults to log/<example>.typescript)") { |path| options[:output] = path }
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

args = ARGV.dup
if idx = args.index("--")
  options[:extra] = args[(idx + 1)..] || []
  args = args[0...idx]
end

parser.parse!(args)

example = args.shift
if example.nil? || example.empty?
  warn parser
  exit 1
end

script_name = example.end_with?(".cr") ? example : "#{example}.cr"
example_path = File.join("examples", script_name)
unless File.file?(example_path)
  warn "Example not found: #{example_path}"
  exit 1
end

output_path = options[:output] || File.join("log", "#{File.basename(example, ".cr")}.typescript")
FileUtils.mkdir_p(File.dirname(output_path))

cache_dir = File.expand_path("temp/crystal_cache")
FileUtils.mkdir_p(cache_dir)

env = ENV.to_h.merge(
  "CRYSTAL_CACHE_DIR"    => cache_dir,
  "TERMINAL_USE_HARNESS" => "1",
)

command = ["bin/run_example", example] + options[:extra]

begin
  PTY.spawn(env, "/bin/bash", "-lc", command.join(" ")) do |stdout, _stdin, _pid|
    File.open(output_path, "ab") do |file|
      begin
        stdout.each do |line|
          file.write(line)
          $stdout.print(line)
        end
      rescue Errno::EIO
        # PTY raises EIO on EOF; ignore.
      end
    end
  end
rescue PTY::ChildExited => e
  exit e.status
end
