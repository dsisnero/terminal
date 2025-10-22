#!/usr/bin/env crystal

# Enhanced DSL Demo - Complete example showing all DSL capabilities
# This file demonstrates the proper way to use the Terminal DSL

require "../src/terminal"

# Example 1: Basic four-quadrant chat application
def demo_chat_application
  puts "=== Chat Application Demo ==="

  app = Terminal.chat_application("Enhanced DSL Demo Chat", 80, 24) do |chat|
    # Pre-configured four-quadrant layout
    chat.chat_area do |area|
      area.content("Welcome to the Enhanced DSL Demo!\nThis is a chat application built with the new DSL.")
      area.title("💬 Chat")
      area.auto_scroll(true)
    end

    chat.status_area do |area|
      area.content("Status: Connected\nUsers: 1\nUptime: 00:00:01")
      area.title("📊 Status")
      area.color(:green)
    end

    chat.system_area do |area|
      area.content("System initialized\nDSL loaded successfully\nReady for input")
      area.title("🔧 System")
      area.color(:yellow)
    end

    chat.help_area do |area|
      area.content("Commands:\n/help - Show help\n/quit - Exit\n/clear - Clear chat\nESC - Exit")
      area.title("❓ Help")
      area.color(:cyan)
    end

    chat.input_area do |input|
      input.prompt("You: ")
      input.placeholder("Type your message...")
    end

    # Event handlers
    chat.on_user_input do |message|
      case message
      when "/help"
        puts "Help: Available commands are /help, /quit, /clear"
      when "/quit"
        puts "Goodbye!"
        exit(0)
      when "/clear"
        puts "Chat cleared"
      else
        puts "You said: #{message}"
        # Simulate AI response
        puts "AI: I received your message: '#{message}'"
      end
    end

    chat.on_key(:escape) do
      puts "Exiting chat application..."
      exit(0)
    end

    chat.on_key(:f1) do
      puts "F1 Help: Press ESC to exit, type /help for commands"
    end
  end

  puts "Starting chat application (press ESC to exit)..."
  app.start
end

# Example 2: Custom layout application
def demo_custom_application
  puts "\n=== Custom Layout Demo ==="

  app = Terminal.application(100, 30) do |builder|
    # Define custom four-quadrant layout
    builder.layout :four_quadrant do |layout|
      if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
        layout.top_left("main", 70, 75)
        layout.top_right("sidebar", 30, 75)
        layout.bottom_left("logs", 70, 20)
        layout.bottom_right("controls", 30, 20)
        layout.bottom_full("status", 2)
      end
    end

    # Create widgets for each area
    builder.text_widget("main") do |text|
      text.content("This is the main content area.\nIt shows primary application data.\n\nLayout: Four Quadrant\nSize: 70% width, 75% height")
      text.title("🏠 Main Content")
      text.auto_scroll(true)
      text.border_style(:rounded)
    end

    builder.text_widget("sidebar") do |text|
      text.content("Sidebar:\n- Navigation\n- Quick actions\n- Settings\n- User info")
      text.title("📂 Sidebar")
      text.color(:blue)
    end

    builder.text_widget("logs") do |text|
      text.content("[INFO] Application started\n[DEBUG] Layout configured\n[INFO] Widgets created\n[DEBUG] Event handlers set")
      text.title("📋 Logs")
      text.color(:yellow)
      text.auto_scroll(true)
    end

    builder.text_widget("controls") do |text|
      text.content("Controls:\n[F1] Help\n[F2] Settings\n[ESC] Exit\n[CTRL+C] Force quit")
      text.title("🎮 Controls")
      text.color(:magenta)
    end

    builder.text_widget("status") do |text|
      text.content("Ready | DSL Demo | 100x30 terminal")
      text.title("📊 Status")
      text.color(:green)
    end

    # Event handling
    builder.on_key(:f1) do
      puts "Help: This is a demo of the Enhanced Terminal DSL"
    end

    builder.on_key(:f2) do
      puts "Settings: No settings available in this demo"
    end

    builder.on_key(:escape) do
      puts "Exiting custom application..."
      exit(0)
    end

    builder.on_key("ctrl+c") do
      puts "Force quit requested"
      exit(0)
    end

    # Periodic updates
    builder.every(5.seconds) do
      current_time = Time.local.to_s("%H:%M:%S")
      puts "Status update at #{current_time}"
    end

    builder.on_start do
      puts "Custom application started successfully"
    end

    builder.on_stop do
      puts "Custom application stopped"
    end
  end

  puts "Starting custom application (press ESC to exit)..."
  app.start
end

# Main demo runner
def main
  puts "Terminal DSL Enhanced Demo"
  puts "========================="
  puts "This demo shows the Enhanced Terminal DSL capabilities"
  puts
  puts "Features demonstrated:"
  puts "• Layout-focused DSL (:four_quadrant, :grid, etc.)"
  puts "• Generic area methods (top_left, bottom_right)"
  puts "• Full terminal architecture integration"
  puts "• Convenience methods (Terminal.chat_application)"
  puts "• Proper type checking and error prevention"
  puts

  loop do
    puts "\nChoose a demo:"
    puts "1. Chat Application (convenience DSL)"
    puts "2. Custom Four-Quadrant Layout"
    puts "3. Exit"
    print "\nChoice (1-3): "

    choice = gets.try(&.chomp) || "3"

    case choice
    when "1"
      demo_chat_application
    when "2"
      demo_custom_application
    when "3"
      puts "Goodbye!"
      break
    else
      puts "Invalid choice. Please enter 1-3."
    end
  end
end

# Run the demo if this file is executed directly
if PROGRAM_NAME == __FILE__
  main
end
