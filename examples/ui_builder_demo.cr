#!/usr/bin/env crystal

# UI Builder Demo
# ---------------------------------------------
# Renders a dashboard-style layout using Terminal.app.
# Run with: `crystal run examples/ui_builder_demo.cr`

require "../src/terminal"

WIDTH  = 72
HEIGHT = 18

application = Terminal.app(width: WIDTH, height: HEIGHT) do |builder|
  builder.layout do |layout|
    layout.vertical do
      layout.widget "header", Terminal::UI::Constraint.length(3)
      layout.horizontal do
        layout.widget "summary", Terminal::UI::Constraint.percent(40)
        layout.widget "activity"
      end
      layout.widget "footer", Terminal::UI::Constraint.length(3)
    end
  end

  builder.text_box "header" do |box|
    box.set_text("UI Builder Demo\n================")
  end

  builder.table "summary" do |table|
    table.col("Service", :service, 16)
    table.col("Status", :status, 12, :center)
    table.col("Latency", :latency, 12, :right)
    table.rows([
      {"service" => "API Gateway", "status" => "OK", "latency" => "18 ms"},
      {"service" => "Billing", "status" => "Slow", "latency" => "95 ms"},
      {"service" => "Scheduler", "status" => "OK", "latency" => "03 ms"},
    ])
  end

  builder.text_box "activity" do |box|
    box.set_text(
      "Recent activity:\n" \
      "- Deploy pipeline completed successfully\n" \
      "- 3 alerts acknowledged in the last hour\n" \
      "- Cache hit rate improved by 7%"
    )
    box.auto_scroll = false
  end

  builder.text_box "footer" do |box|
    box.set_text("Tip: Wrap this layout in `Terminal.run` for an interactive app.")
  end
end

grid = application.widget_manager.compose(WIDTH, HEIGHT)

grid.each do |row|
  row.each do |cell|
    cell.to_ansi(STDOUT)
  end
  puts
end
