# File: src/terminal/form_widget.cr
# Purpose: Form widget supporting multiple control types with validation

module Terminal
  enum FormControlType
    TextInput
    Dropdown
    Checkbox
    Radio

    def text_input?
      self == TextInput
    end

    def dropdown?
      self == Dropdown
    end

    def checkbox?
      self == Checkbox
    end

    def radio?
      self == Radio
    end
  end

  class FormControl
    property id : String
    property type : FormControlType
    property label : String
    property value : String
    property options : Array(String)
    property required : Bool
    property validator : Proc(String, Bool)?
    property error : String?

    def initialize(
      @id : String,
      @type : FormControlType,
      @label : String,
      @value : String = "",
      @options : Array(String) = [] of String,
      @required : Bool = false,
      @validator : Proc(String, Bool)? = nil,
    )
      @error = nil
    end

    def valid? : Bool
      if @required && @value.empty?
        @error = "Required field"
        return false
      end

      if validator = @validator
        unless validator.call(@value)
          @error = "Invalid value"
          return false
        end
      end

      @error = nil
      true
    end
  end

  class FormWidget
    include Terminal::Widget

    getter id : String
    property controls : Array(FormControl)
    property focused_index : Int32
    property expanded_dropdown : String?

    @on_submit : Proc(Hash(String, String), Nil)?
    @title : String
    @submit_label : String

    def initialize(
      @id : String,
      @controls : Array(FormControl) = [] of FormControl,
      @title : String = "Form",
      @submit_label : String = "Submit",
    )
      @focused_index = 0
      @expanded_dropdown = nil
      @on_submit = nil
      @can_focus = true
    end

    def on_submit(&block : Hash(String, String) -> Nil)
      @on_submit = block
    end

    def add_control(control : FormControl)
      @controls << control
    end

    def handle(msg : Terminal::Msg::Any)
      # Try common navigation first
      unless handle_navigation(msg)
        case msg
        when Terminal::Msg::KeyPress
          handle_key(msg.key)
        when Terminal::Msg::InputEvent
          handle_input(msg.char)
        end
      end
    end

    # Override navigation methods for form-specific behavior
    def handle_tab_key
      # Tab moves between controls (including submit button)
      @focused_index = (@focused_index + 1) % (@controls.size + 1)
      @expanded_dropdown = nil # Close any open dropdown
    end

    # Override arrow key handling for form-specific behavior
    def handle_up_key
      if @expanded_dropdown
        # Navigate dropdown
        if control = current_control
          if idx = control.options.index(control.value)
            new_idx = [idx - 1, 0].max
            control.value = control.options[new_idx]
          end
        end
      else
        # Move focus up between controls
        @focused_index = [@focused_index - 1, 0].max
        @expanded_dropdown = nil
      end
    end

    def handle_down_key
      if @expanded_dropdown
        # Navigate dropdown
        if control = current_control
          if idx = control.options.index(control.value)
            new_idx = [idx + 1, control.options.size - 1].min
            control.value = control.options[new_idx]
          end
        end
      else
        # Move focus down between controls
        @focused_index = [@focused_index + 1, @controls.size].min
        @expanded_dropdown = nil
      end
    end

    # Override enter key for form-specific behavior
    def handle_enter_key
      if control = current_control
        case control.type
        when .dropdown?
          if @expanded_dropdown == control.id
            @expanded_dropdown = nil
          else
            @expanded_dropdown = control.id
          end
        when .checkbox?
          control.value = control.value == "true" ? "false" : "true"
        end
      elsif @focused_index == @controls.size
        # Submit button focused
        submit_form
      end
    end

    def handle_escape_key
      @expanded_dropdown = nil
    end

    private def handle_key(key : String)
      case key
      when "space"
        if control = current_control
          case control.type
          when .checkbox?
            control.value = control.value == "true" ? "false" : "true"
          when .radio?
            # Set this radio to true, others in same group to false
            control.value = "true"
          end
        end
      when "backspace"
        if control = current_control
          if control.type.text_input? && !control.value.empty?
            control.value = control.value[0...-1]
          end
        end
      end
    end

    private def handle_input(ch : Char)
      if control = current_control
        if control.type.text_input? && (ch.printable? || ch == ' ')
          control.value += ch.to_s
        end
      end
    end

    private def current_control : FormControl?
      @controls[@focused_index]? if @focused_index < @controls.size
    end

    private def submit_form
      # Validate all controls
      all_valid = @controls.all?(&.valid?)

      if all_valid
        data = {} of String => String
        @controls.each do |control|
          data[control.id] = control.value
        end
        @on_submit.try(&.call(data))
      end
    end

    # Calculate minimum width needed for the form based on content
    def calculate_min_width : Int32
      # Start with title width
      min_width = text_width(@title) + 4 # Title + some padding

      # Check each control's requirements
      @controls.each do |control|
        case control.type
        when .text_input?
          # Use helper method for label + content width
          control_width = label_content_width(control.label, 25) # Allow for input text
        when .dropdown?
          # Label + longest option + dropdown indicator
          if options = control.options
            longest_option = max_text_width(options)
            control_width = label_content_width(control.label, longest_option + 3) # Arrow + padding
          else
            control_width = label_content_width(control.label, 15)
          end
        when .checkbox?, .radio?
          # Label + checkbox/radio indicator
          control_width = label_content_width(control.label, 3) # Checkbox symbol
        else
          control_width = label_content_width(control.label, 10)
        end

        min_width = {min_width, control_width}.max
      end

      # Add submit button width
      submit_width = text_width(@submit_label) + 6 # Button styling
      min_width = {min_width, submit_width}.max

      # Minimum reasonable width
      {min_width, 30}.max
    end

    # Calculate maximum reasonable width for the form
    def calculate_max_width : Int32
      # Forms shouldn't be too wide - max based on content but capped
      content_width = calculate_min_width
      {content_width, 70}.min # Cap at reasonable width
    end

    # Calculate minimum height needed for the form
    def calculate_min_height : Int32
      # Title + separator + controls + submit button
      lines = 2                   # title + separator
      lines += @controls.size * 2 # Each control + spacer
      lines += 1                  # submit button

      # Account for expanded dropdowns (estimate)
      @controls.each do |control|
        if control.type.dropdown? && control.options
          # If expanded, would need extra lines for options
          lines += 1 # Just add one for potential expansion
        end
      end

      {lines, 5}.max # Minimum reasonable height
    end

    # Calculate maximum reasonable height for the form
    def calculate_max_height : Int32
      # All content + potential dropdown expansions
      lines = calculate_min_height

      # Add potential for all dropdowns to be expanded
      @controls.each do |control|
        if control.type.dropdown? && control.options
          lines += control.options.size # Full expansion
        end
      end

      {lines, 30}.min # Cap at reasonable height
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      # Use content-based width instead of full width parameter
      actual_width = calculate_min_width

      result = [] of Array(Terminal::Cell)

      # Title line
      title_line = render_title_line(actual_width)
      result << title_line

      # Separator
      result << Array.new(actual_width) { Terminal::Cell.new('─', fg: "cyan") }

      # Render each control
      @controls.each_with_index do |control, idx|
        focused = (idx == @focused_index)
        expanded = (@expanded_dropdown == control.id)

        control_lines = render_control(control, focused, expanded, actual_width)
        result.concat(control_lines)

        # Show error if present
        if error = control.error
          error_line = render_error_line(error, actual_width)
          result << error_line
        end

        # Spacer
        result << Array.new(actual_width) { Terminal::Cell.new(' ') }
      end

      # Submit button
      submit_focused = (@focused_index == @controls.size)
      submit_line = render_submit_button(submit_focused, actual_width)
      result << submit_line

      # Pad or truncate to height
      while result.size < height
        result << Array.new(actual_width) { Terminal::Cell.new(' ') }
      end

      result[0...height]
    end

    private def render_title_line(width : Int32) : Array(Terminal::Cell)
      line = Array.new(width) { Terminal::Cell.new(' ', bg: "blue") }
      @title.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: "blue", bold: true)
      end
      line
    end

    private def render_control(control : FormControl, focused : Bool, expanded : Bool, width : Int32) : Array(Array(Terminal::Cell))
      lines = [] of Array(Terminal::Cell)

      # Label line
      label_text = control.label + (control.required ? " *" : "")
      label_bg = focused ? "yellow" : "default"
      label_fg = focused ? "black" : "white"

      label_line = Array.new(width) { Terminal::Cell.new(' ', bg: label_bg) }
      label_text.chars.each_with_index do |ch, i|
        break if i >= width
        label_line[i] = Terminal::Cell.new(ch, fg: label_fg, bg: label_bg, bold: focused)
      end
      lines << label_line

      # Value line(s)
      case control.type
      when .text_input?
        value_line = render_text_input(control.value, focused, width)
        lines << value_line
      when .dropdown?
        dropdown_line = render_dropdown_line(control.value, focused, expanded, width)
        lines << dropdown_line

        if expanded
          control.options.each do |option|
            selected = (option == control.value)
            option_line = render_option_line(option, selected, width)
            lines << option_line
          end
        end
      when .checkbox?
        checkbox_line = render_checkbox_line(control.value == "true", focused, width)
        lines << checkbox_line
      when .radio?
        radio_line = render_radio_line(control.value == "true", focused, width)
        lines << radio_line
      end

      lines
    end

    private def render_text_input(value : String, focused : Bool, width : Int32) : Array(Terminal::Cell)
      bg = focused ? "cyan" : "default"
      line = Array.new(width) { Terminal::Cell.new(' ', bg: bg) }

      prefix = "  > "
      text = prefix + value + (focused ? "_" : "")

      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: bg)
      end
      line
    end

    private def render_dropdown_line(value : String, focused : Bool, expanded : Bool, width : Int32) : Array(Terminal::Cell)
      arrow = expanded ? "▲" : "▼"
      text = "  [#{value}] #{arrow}"
      bg = focused ? "cyan" : "default"

      line = Array.new(width) { Terminal::Cell.new(' ', bg: bg) }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: bg)
      end
      line
    end

    private def render_option_line(option : String, selected : Bool, width : Int32) : Array(Terminal::Cell)
      prefix = selected ? "    > " : "      "
      text = prefix + option
      bg = selected ? "green" : "default"

      line = Array.new(width) { Terminal::Cell.new(' ', bg: bg) }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: bg, bold: selected)
      end
      line
    end

    private def render_checkbox_line(checked : Bool, focused : Bool, width : Int32) : Array(Terminal::Cell)
      box = checked ? "[✓]" : "[ ]"
      text = "  #{box}"
      bg = focused ? "cyan" : "default"

      line = Array.new(width) { Terminal::Cell.new(' ', bg: bg) }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: bg)
      end
      line
    end

    private def render_radio_line(selected : Bool, focused : Bool, width : Int32) : Array(Terminal::Cell)
      radio = selected ? "(•)" : "( )"
      text = "  #{radio}"
      bg = focused ? "cyan" : "default"

      line = Array.new(width) { Terminal::Cell.new(' ', bg: bg) }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: bg)
      end
      line
    end

    private def render_error_line(error : String, width : Int32) : Array(Terminal::Cell)
      text = "  ⚠ #{error}"
      line = Array.new(width) { Terminal::Cell.new(' ', bg: "red") }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: "red", bold: true)
      end
      line
    end

    private def render_submit_button(focused : Bool, width : Int32) : Array(Terminal::Cell)
      text = "[ #{@submit_label} ]"
      bg = focused ? "green" : "blue"

      # Center the button
      padding = (width - text.size) // 2
      line = Array.new(width) { Terminal::Cell.new(' ') }

      text.chars.each_with_index do |ch, i|
        pos = padding + i
        break if pos >= width
        line[pos] = Terminal::Cell.new(ch, fg: "white", bg: bg, bold: true)
      end
      line
    end
  end
end
