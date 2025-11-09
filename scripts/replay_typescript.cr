#!/usr/bin/env crystal
require "option_parser"
require "file_utils"
require "../src/spec_support/typescript_replay"

type Options = NamedTuple(file: String?, width: Int32, height: Int32)

options = Options.new(file: nil, width: 80, height: 24)

parser = OptionParser.new do |opts|
  opts.banner = "Usage: crystal run scripts/replay_typescript.cr -- -f log/demo.typescript [--width 80 --height 24]"
  opts.on("-f FILE", "--file FILE", "typescript capture to replay") { |file| options = options.merge(file: file) }
  opts.on("--width N", Int32, "frame width (default 80)") { |width_value| options = options.merge(width: width_value) }
  opts.on("--height N", Int32, "frame height (default 24)") { |height_value| options = options.merge(height: height_value) }
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

parser.parse!

file = options[:file]
abort("--file is required") unless file
abort("File not found: #{file}") unless File.file?(file)

replay = Terminal::SpecSupport::TypescriptReplay.new(width: options[:width], height: options[:height])
replay.load_file(file)
puts replay.lines.join("\n")
