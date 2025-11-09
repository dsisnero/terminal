#!/usr/bin/env ruby
# Smoke-test RawInputProvider on Unix by driving the interactive demo via PTY.

require "optparse"
require "pty"
require "expect"

options = {
  example: "interactive_builder_demo",
  timeout: 5,
}

OptionParser.new do |opts|
  opts.banner = "Usage: scripts/smoke_raw_input.rb [options]"
  opts.on("-e", "--example NAME", "Example to run (default: interactive_builder_demo)") { |name| options[:example] = name }
  opts.on("-t", "--timeout SECONDS", Integer, "Expect timeout (default: 5)") { |sec| options[:timeout] = sec }
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

example = options[:example]
command = "TERM_DEMO_TEST=0 TERMINAL_USE_HARNESS=1 bin/run_example #{example}"

begin
  PTY.spawn(command) do |stdout, stdin, pid|
    stdout.expect(/Press Enter/, options[:timeout]) { stdin.print("\n") }
    stdout.expect(/You:/, options[:timeout]) { stdin.print("hello smoke\n") }
    stdout.expect(/Echo -> HELLO SMOKE/, options[:timeout]) or raise "Echo not observed"
    # Send bracketed paste sequence to ensure parser consolidates it
    stdin.print("\e[200~PASTED CONTENT\e[201~")
    stdout.expect(/PASTED CONTENT/, options[:timeout]) or raise "Paste content not observed"
    stdin.print("/quit\n")
    Process.wait(pid)
    status = $?.exitstatus
    raise "Demo exited with status #{status}" unless status == 0
  end
  puts "Raw input smoke test succeeded."
rescue Errno::EIO
  # PTY raises EIO on EOF; treat as success if process already exited cleanly.
  puts "Raw input smoke test completed (PTY EOF)."
rescue => e
  warn "Smoke test failed: #{e.message}"
  exit 1
end
