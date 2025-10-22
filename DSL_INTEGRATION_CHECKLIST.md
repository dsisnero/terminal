# DSL Integration Checklist for AI Agents

## Quick Reference for Integrating Terminal DSL

This checklist ensures proper usage of the Terminal Enhanced DSL in other projects (like Clarity2).

### ✅ Integration Steps

1. **Add Dependency** to `shard.yml`:
   ```yaml
   dependencies:
     terminal:
       github: dsisnero/terminal
   ```

2. **Install Dependencies**:
   ```bash
   shards install
   ```

3. **Basic Import**:
   ```crystal
   require "terminal"
   ```

### ✅ DSL Usage Patterns

#### Chat Application (Easiest)
```crystal
app = Terminal.chat_application("My App") do |chat|
  chat.chat_area { |area| area.content("Welcome!") }
  chat.input_area { |input| input.prompt("You: ") }
  chat.on_user_input { |text| handle_input(text) }
  chat.on_key(:escape) { app.stop }
end
app.start
```

#### Custom Layout Application
```crystal
app = Terminal.application(80, 24) do |builder|
  builder.layout :four_quadrant do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
      layout.top_left("main")
      layout.bottom_full("input", 3)
    end
  end

  builder.text_widget("main") { |t| t.content("Content") }
  builder.input_widget("input") { |i| i.prompt("Command: ") }

  builder.on_input("input") { |text| process(text) }
  builder.on_key(:escape) { app.stop }
end
app.start
```

### ✅ Required Type Checking

**Always use type checks for layouts:**
```crystal
# ✅ Correct
builder.layout :four_quadrant do |layout|
  if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
    layout.top_left("main")
  end
end

# ❌ Wrong - Will not compile
builder.layout :four_quadrant do |layout|
  layout.top_left("main")  # Compile error
end
```

### ✅ Widget Creation Rules

**Create widgets for ALL layout areas:**
```crystal
# ✅ Correct - Widget matches area
layout.top_left("main")
builder.text_widget("main") { |t| t.content("Content") }

# ❌ Wrong - Missing widget causes runtime error
layout.top_left("main")
# No widget created - will fail
```

### ✅ Event Handling

**Always provide exit mechanisms:**
```crystal
# Required event handlers
builder.on_key(:escape) { app.stop }
builder.on_key("ctrl+c") { app.stop }

# Input handling
builder.on_input("input_id") do |text|
  # Process user input
end
```

### ✅ Layout Types Available

- `:four_quadrant` - Chat apps, dashboards (recommended)
- `:grid` - Complex layouts with rows/columns
- `:vertical` - Vertical sections with fixed heights
- `:horizontal` - Horizontal sections with fixed widths

### ✅ Architecture Benefits

The DSL automatically provides:
- **EventLoop** coordination
- **ScreenBuffer** diff computation
- **DiffRenderer** flicker-free output
- **Message-driven** architecture
- **Thread-safe** operations

### ❌ Common Mistakes to Avoid

1. **Missing type checks**:
   ```crystal
   # ❌ Wrong
   layout.top_left("area")  # Compile error
   ```

2. **Missing widgets**:
   ```crystal
   # ❌ Wrong
   layout.top_left("main")
   # No widget created - runtime error
   ```

3. **Manual rendering**:
   ```crystal
   # ❌ Wrong - Bypasses architecture
   puts "manual output"  # Causes flickering
   ```

4. **No exit handling**:
   ```crystal
   # ❌ Wrong - No way to exit
   # Missing: builder.on_key(:escape) { app.stop }
   ```

### ✅ Testing DSL Applications

```crystal
describe "My Terminal App" do
  it "creates application correctly" do
    app = Terminal.application(80, 24) do |builder|
      # Your DSL code
    end

    app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end
end
```

### ✅ Documentation References

- **[DSL_USAGE_GUIDE.md](DSL_USAGE_GUIDE.md)** - Complete documentation
- **[examples/enhanced_dsl_demo.cr](examples/enhanced_dsl_demo.cr)** - Working examples
- **[AGENTS.md](AGENTS.md)** - Agent-specific guidelines
- **[TERMINAL_ARCHITECTURE.md](TERMINAL_ARCHITECTURE.md)** - Architecture details

### ✅ Validation Commands

```bash
# Build check
crystal build src/terminal.cr

# Test DSL
crystal spec spec/application_dsl_spec.cr

# Run examples
crystal run examples/enhanced_dsl_demo.cr
```

### ✅ Integration Success Criteria

- [ ] Application compiles without errors
- [ ] Type checking used for all layouts
- [ ] Widgets created for all layout areas
- [ ] Event handlers provide exit mechanisms
- [ ] No manual puts/print statements
- [ ] Uses Terminal.application or Terminal.chat_application
- [ ] Follows patterns from DSL_USAGE_GUIDE.md

## Agent Integration Template

For AI agents integrating this DSL:

```crystal
require "terminal"

# Choose pattern based on use case:
# 1. For chat/AI interfaces: Terminal.chat_application
# 2. For custom layouts: Terminal.application

app = Terminal.chat_application("Your App Name") do |chat|
  # Configure areas
  chat.chat_area { |area| area.content("Initial content") }
  chat.input_area { |input| input.prompt("Prompt: ") }

  # Handle events
  chat.on_user_input { |text| your_handler(text) }
  chat.on_key(:escape) { app.stop }
end

app.start
```

This ensures proper integration with full architecture benefits and no common pitfalls.