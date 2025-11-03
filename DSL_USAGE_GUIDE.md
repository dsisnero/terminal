# Terminal UI Builder Guide

## Overview

The high-level API for this library revolves around `Terminal.app`. It lets you declare layouts, mount widgets, register input handlers, and start the asynchronous pipeline in a handful of lines. This guide covers the builder primitives, widget helpers, and recommended practices when wiring new terminal experiences.

## Quick Start

```crystal
require "terminal"

Terminal.run(width: 100, height: 28) do |ui|
  ui.layout do |layout|
    layout.vertical do
      layout.widget "header", Terminal::UI::Constraint.length(3)
      layout.horizontal do
        layout.widget "sidebar", Terminal::UI::Constraint.percent(30)
        layout.widget "main", Terminal::UI::Constraint.flex
      end
      layout.widget "input", Terminal::UI::Constraint.length(3)
    end
  end

  ui.text_box "header" do |box|
    box.set_text("System Monitor — CTRL+C to exit")
  end

  ui.table "sidebar" do |table|
    table.col("Proc", :proc, 16, :left, :cyan)
    table.col("CPU%", :cpu, 6, :right)
    table.rows([
      {"proc" => "worker-1", "cpu" => "14"},
      {"proc" => "worker-2", "cpu" => "8"},
    ])
  end

  ui.text_box "main" do |box|
    box.set_text("Logs will stream here…")
  end

  ui.input "input" do |input|
    input.prompt("Command: ")
  end

  ui.on_input("input") do |value|
    puts "Received: #{value}"
  end
  ui.on_key(:escape) { puts "Goodbye!" }
end
```

## Layout Builder Basics

Layouts are built by nesting `layout.horizontal` / `layout.vertical` calls. Each node can receive a `Terminal::UI::Constraint`:

- `Constraint.length(n)` – fixed size.
- `Constraint.percent(n)` – share container space by percentage.
- `Constraint.flex(weight)` – consume remaining space proportionally.

Call `layout.widget("id", constraint)` to reserve a leaf in the tree. Any widgets not assigned explicitly are appended automatically, but declaring them up front makes intent clear and defines focus order.

## Mounting Widgets

The builder exposes convenience helpers for the core widgets:

- `ui.text_box("logs") { |box| box.append_text("...") }`
- `ui.input("command") { |input| input.prompt("Run: ") }`
- `ui.table("metrics") { |table| ... }`
- `ui.spinner("status", "Loading") { |spinner| }`
- `ui.mount("dropdown", Terminal::DropdownWidget.new("dropdown", ["A", "B", "C"]))`
- `ui.mount("custom", CustomWidget.new("custom"))` for bespoke widgets that include `Terminal::Widget`.

Widgets use the sizing helpers from `Terminal::Widget` and render into layout rectangles computed by the resolver. They already honour focus: `Tab` moves forward, `Shift+Tab` moves backward, and `Widget#can_focus` can be set to `false` for passive elements.

## Event Hooks & Shortcuts

- `ui.on_input("input_id") { |value| ... }` wires `InputWidget#on_submit`.
- `ui.on_key(:symbol_or_string, consume = true) { ... }` registers global shortcuts via the `WidgetManager`. Keys are normalized to lowercase strings, e.g. `:escape`, `"ctrl+s"`.
- `ui.every(500.milliseconds) { ... }` schedules periodic work (ideal for updating spinners or refreshing data). These run in separate fibers.
- `ui.on_start { ... }` and `ui.on_stop { ... }` let you spawn bootstrapping logic or cleanup tasks alongside the event loop.

Global key handlers run before the focused widget. Return `false` (set `consume: false`) when you want the focused widget to also receive the event.

## Working with Text Boxes

`Terminal::TextBoxWidget` now keeps scroll state, padding, and auto-scroll behaviour internally. Useful calls:

```crystal
ui.text_box "logs" do |box|
  box.set_text("Ready\n")
  box.auto_scroll = true
end
```

Scrolling keys supported out of the box: arrow up/down, page up/down, home/end. `auto_scroll = true` keeps the viewport pinned to the newest lines unless the user scrolls manually.

## Tables, Dropdowns, and Spinners

- Tables expose a fluent API for columns, alignment, sorting, and colours. They highlight the focused row when the widget has focus.
- Dropdowns support incremental filtering, selection callbacks, and auto-reset the filter after a choice is confirmed.
- Spinners respond to `RenderRequest` ticks; combine with `ui.every` to animate them.

## Custom Widgets

Any struct/class including `Terminal::Widget` can be mounted with `ui.mount`. Implement:

```crystal
class StatusWidget
  include Terminal::Widget

  getter id : String

  def initialize(@id : String)
  end

  def handle(msg : Terminal::Msg::Any)
    # respond to input, commands, or render ticks
  end

  def render(width : Int32, height : Int32)
    Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } }
  end
end

ui.mount "status", StatusWidget.new("status")
```

Remember to set `@can_focus = false` inside the widget if it should never receive focus.

## Testing & Tooling

- Add specs next to related code (`spec/text_box_widget_spec.cr`, `spec/input_widget_spec.cr`, etc.). Use `SpecHelper.grid_to_lines` to assert rendered output when needed.
- Run `crystal tool format`, `ameba`, and `crystal spec` before sharing changes. Specs may require escalated permissions in the sandboxed CLI.
- Consult `LAYOUT_SYSTEM_SUMMARY.md` for resolver internals and `TERMINAL_ARCHITECTURE.md` for the messaging pipeline when adding new behaviours.

## Next Steps

Upcoming work tracked in `plan.md` focuses on an end-to-end builder spec, cohesive rendering documentation, and CI improvements. Align new contributions with that roadmap and update docs (including this guide) when the builder API evolves.
