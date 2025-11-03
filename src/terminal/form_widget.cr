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
    @padding : Int32

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
      @padding = 1
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
      min_content, _ = form_content_width_bounds
      min_content + structural_width_padding
    end

    def calculate_max_width : Int32
      _, max_content = form_content_width_bounds
      max_content + structural_width_padding
    end

    def calculate_min_height : Int32
      min_content, _ = form_content_height_bounds
      min_content + structural_height_padding
    end

    def calculate_max_height : Int32
      _, max_content = form_content_height_bounds
      max_content + structural_height_padding
    end

    private def structural_width_padding : Int32
      (@padding * 2) + 2
    end

    private def structural_height_padding : Int32
      (@padding * 2) + 2
    end

    private def form_content_width_bounds : {Int32, Int32}
      min_width = text_width(@title) + 4 # Title + some padding

      @controls.each do |control|
        control_width = case control.type
                        when .text_input?
                          label_content_width(control.label, 25)
                        when .dropdown?
                          if options = control.options
                            longest_option = max_text_width(options)
                            label_content_width(control.label, longest_option + 3)
                          else
                            label_content_width(control.label, 15)
                          end
                        when .checkbox?, .radio?
                          label_content_width(control.label, 3)
                        else
                          label_content_width(control.label, 10)
                        end

        min_width = {min_width, control_width}.max
      end

      submit_width = text_width(@submit_label) + 6
      min_width = {min_width, submit_width}.max

      min_width = {min_width, 30}.max
      max_width = {min_width, 70}.min
      {min_width, max_width}
    end

    private def form_content_height_bounds : {Int32, Int32}
      base_lines = 2                   # title + separator
      base_lines += @controls.size * 2 # control + spacer
      base_lines += 1                  # submit button

      @controls.each do |control|
        if control.type.dropdown? && control.options
          base_lines += 1
        end
      end

      min_lines = {base_lines, 5}.max

      max_lines = min_lines
      @controls.each do |control|
        if control.type.dropdown? && control.options
          max_lines += control.options.size
        end
      end

      max_lines = {max_lines, 30}.min
      {min_lines, max_lines}
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      return Array.new(height) { Array.new(width) { Terminal::Cell.new(' ') } } if width <= 0 || height <= 0

      content_width = {width - 2 - (@padding * 2), 0}.max
      content_height = {height - 2 - (@padding * 2), 0}.max

      content_lines = [] of Array(Terminal::Cell)

      content_lines << render_title_line(content_width)
      content_lines << render_separator_line(content_width)

      @controls.each_with_index do |control, idx|
        focused = (idx == @focused_index)
        expanded = (@expanded_dropdown == control.id)

        control_lines = render_control(control, focused, expanded, content_width)
        content_lines.concat(control_lines)

        if error = control.error
          content_lines << render_error_line(error, content_width)
        end

        content_lines << blank_line(content_width)
      end

      submit_focused = (@focused_index == @controls.size)
      content_lines << render_submit_button(submit_focused, content_width)

      visible_lines = if content_height > 0
                        content_lines.first(content_height)
                      else
                        [] of Array(Terminal::Cell)
                      end

      while visible_lines.size < content_height
        visible_lines << blank_line(content_width)
      end

      build_bordered_cell_grid(width, height, @padding, visible_lines)
    end

    private def render_separator_line(width : Int32) : Array(Terminal::Cell)
      Array.new(width) { Terminal::Cell.new('─', fg: "cyan") }
    end

    private def blank_line(width : Int32, bg : String = "default") : Array(Terminal::Cell)
      Array.new(width) { Terminal::Cell.new(' ', bg: bg) }
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
      padding = width > text.size ? (width - text.size) // 2 : 0
      line = Array.new(width) { Terminal::Cell.new(' ', fg: "white", bg: bg, bold: focused) }

      text.chars.each_with_index do |ch, i|
        pos = padding + i
        next if pos < 0
        break if pos >= width
        line[pos] = Terminal::Cell.new(ch, fg: "white", bg: bg, bold: true)
      end
      line
    end
  end
end
