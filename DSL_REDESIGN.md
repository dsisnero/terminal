# DSL Redesign Proposal

The current DSL (`Terminal::ApplicationDSL`) is powerful but hard to extend:

- Layouts are hard-coded (four-quadrant, grid, vertical, horizontal) and generate manual hash maps.
- `LayoutCompositeWidget` wraps all widgets in a single container instead of letting the layout engine place each widget.
- Focus and navigation are hidden inside the composite wrapper, so individual widgets never receive `focus/blur` events.
- The DSL mixes widget registration, event binding, and layout hashes, making simple apps verbose.

To compete with ergonomics found in libraries such as [Ratatui](https://github.com/ratatui-org/ratatui) and [brick](https://github.com/jtdaugherty/brick), we should split responsibilities:

1. **Declarative Layout Builder**
   ```crystal
   Terminal.app do |ui|
     ui.layout do |layout|
       layout.horizontal do
         layout.child "sidebar", constraint: :length(25)
         layout.vertical do
           layout.child "header", constraint: :length(3)
           layout.child "main", constraint: :fill
           layout.child "status", constraint: :length(1)
         end
       end
     end
   end
   ```
   - `layout.child` attaches an identifier and constraint.
   - Blocks can nest; behind the scenes we build a layout tree equivalent to Ratatui's `Layout::split`.

2. **Widget Registry**
   ```crystal
   ui.mount "sidebar", Terminal::TextBoxWidget.new("logs") do |widget|
     widget.set_text("Booting...")
   end

   ui.mount "main", Terminal::TableWidget.new("data") { ... }
   ```
   - `mount` stores widgets by ID. Missing IDs in the layout raise an error at build time.

3. **Focus & Events**
   - `ui.on_key(:tab) { ui.focus_next }` to cycle focus.
   - Widgets gain default `focus` and `blur` hooks via `Terminal::Widget` mixin.

4. **Rendering Pipeline**
   - `WidgetManager` stores the widget array and layout tree, computing `Geometry::Rect`s via `Layout`.
   - `Dispatcher` composes by asking `WidgetManager.compose` for cells; `ScreenBuffer` diffs as today.

5. **Migration Path**
   - Keep `Terminal::ApplicationDSL` as a wrapper that instantiates `Terminal::UI::Builder` under the hood for backwards compatibility.
   - Emit deprecation warnings when `layout :four_quadrant` is used, pointing to the new builder.

6. **Implementation Roadmap**
   1. Create `Terminal::UI::LayoutNode` structure (direction, constraints, children, slot ID).
   2. Build `Terminal::UI::Builder` with `layout`, `mount`, `on_key`, `every`, etc.
   3. Update `WidgetManager` to accept the layout tree and compute rects via `Layout`.
   4. Remove `LayoutCompositeWidget` once new builder is default.
   5. Expand specs:
      - Layout splitting: multiple widgets render into correct columns/rows.
      - Focus cycling changes `Widget#focused` flag.
      - Dispatcher integration spec: render two widgets, ensure cells merge.

7. **Ergonomic Extras**
   - `ui.text_box("logs") { |tb| tb.auto_scroll = true }`
   - `ui.table("data") { |t| t.rows(...) }`
   - `ui.channel("logs").listen { ... }` for streaming updates.

With this redesign, a minimal app looks like:

```crystal
Terminal.app do |ui|
  ui.layout do |layout|
    layout.vertical do
      layout.child "header", constraint: :length(3)
      layout.child "body", constraint: :fill
    end
  end

  ui.text_box "header" do |tb|
    tb.set_text("System Monitor")
  end

  ui.table "body" do |table|
    table.col("Name", :name, 20)
    table.rows(data)
  end

  ui.on_key :q { ui.stop }
end.start
```

Next steps: prototype `Terminal::UI::Builder`, integrate with the existing rendering plan (WidgetManager + Layout + ScreenBuffer), and update docs/examples accordingly.
