# Terminal Widgets Examples

This directory contains examples demonstrating the Terminal library's widgets with content-based sizing, accessibility features, and keyboard navigation.

## Quick Start

### Basic Usage
```bash
crystal run examples/getting_started.cr
```
Shows simple usage of each widget type with automatic content-based sizing.

### Comprehensive Demo
```bash
crystal run examples/comprehensive_demo.cr
```
Demonstrates the widget APIs and content-based sizing in a non-interactive walkthrough.

## Interactive Example

### Interactive Builder Demo
```bash
crystal run examples/interactive_builder_demo.cr
```
- **Navigation**: Type messages, press Enter. Use `/quit` or press `Esc` to exit.
- **Features**: Built entirely with `Terminal.run`, shows live logging, global key handler, and input submission callbacks.
- **Notes**: Runs the real event loop; no manual `stty` shenanigans required.

## Static Examples

### Simple Examples
```bash
crystal run examples/simple_table_test.cr  # Basic table functionality
crystal run examples/smoke_test.cr         # Quick library validation
```

## Testing Examples

### Content-Based Sizing Tests
```bash
crystal run examples/test_content_sizing.cr     # Basic sizing test
crystal run examples/test_all_widget_sizing.cr  # Comprehensive sizing test
```

### Navigation Tests
```bash
crystal run examples/test_navigation.cr
```
Validates keyboard navigation and accessibility features.

## Key Features Demonstrated

### Content-Based Sizing
- **Before**: All widgets used 100 chars (full screen width)
- **After**: TableWidget(14), FormWidget(31), DropdownWidget(33), InputWidget(40)
- **Benefits**: Better readability, faster rendering, responsive design

### Accessibility Features
- High contrast white text on dark backgrounds
- Colorblind-friendly design (no red/green dependencies)
- Proper keyboard navigation (Tab, arrows, Enter, ESC)
- Screen reader compatible labels and indicators
- Terminal state restoration on exit

### Navigation
- **Tables**: ↑↓ arrow keys for row navigation
- **Forms**: Tab to move between fields
- **Dropdowns**: ↑↓ to select options, Enter to confirm
- **General**: ESC to close/exit, proper focus management

## Widget Types

1. **TableWidget**: Display tabular data with sorting and navigation
2. **FormWidget**: Multiple form controls with validation
3. **DropdownWidget**: Selection from options with filtering
4. **InputWidget**: Text input with validation and cursor management

All widgets automatically size to their content and include comprehensive accessibility features.
