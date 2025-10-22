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
Demonstrates all features including content-based sizing, accessibility, and performance improvements.

## Interactive Examples

### Accessible Form Demo
```bash
crystal build examples/interactive_accessible_form.cr -o interactive_accessible_form
./interactive_accessible_form
```
- **Navigation**: Tab between fields, Enter to submit, ESC to exit
- **Features**: Real keyboard navigation, content-based sizing, high contrast colors
- **Accessibility**: Colorblind-friendly, screen reader compatible

### Accessible Table Demo  
```bash
crystal build examples/simple_accessible_table.cr -o simple_accessible_table
./simple_accessible_table
```
- **Navigation**: Arrow keys to navigate rows, ESC to exit
- **Features**: Row highlighting, content-based width, proper terminal restoration
- **Accessibility**: High contrast, no color dependencies

## Static Examples

### Form Demo
```bash
crystal run examples/form_demo.cr
```
Shows various form widgets, validation, and interaction patterns.

### Table Demo
```bash
crystal run examples/table_demo.cr
```
Interactive table with sorting and navigation (press ESC to exit).

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