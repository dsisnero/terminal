# File: src/terminal/dropdown_widget.cr
# Purpose: Dropdown widget with keyboard navigation and filtering

module Terminal
  class DropdownWidget
    include Terminal::Widget

    getter id : String
    property options : Array(String)
    property selected_index : Int32
    property expanded : Bool
    property filter : String

    @prompt : String
    @on_select : Proc(String, Nil)?

    def initialize(
      @id : String,
      @options : Array(String),
      @prompt : String = "Select:",
      @selected_index : Int32 = 0,
      @expanded : Bool = false,
    )
      @filter = ""
      @on_select = nil
    end

    def on_select(&block : String -> Nil)
      @on_select = block
    end

    def handle(msg : Terminal::Msg::Any)
      # Try base navigation first
      unless handle_navigation(msg)
        case msg
        when Terminal::Msg::KeyPress
          handle_key(msg.key)
        when Terminal::Msg::InputEvent
          if @expanded && msg.char.ascii_letter?
            @filter += msg.char.to_s
            normalize_selection
          end
        end
      end
    end

    # Override navigation for dropdown-specific behavior
    def handle_up_key
      return unless @expanded

      filtered = filtered_options
      return if filtered.empty?

      current = current_option
      current_idx = current ? filtered.index(current) : nil
      target_idx = current_idx ? [current_idx - 1, 0].max : 0
      new_option = filtered[target_idx]
      update_selected_index(new_option)
    end

    def handle_down_key
      return unless @expanded

      filtered = filtered_options
      return if filtered.empty?

      current = current_option
      current_idx = current ? filtered.index(current) : nil
      target_idx = current_idx ? [current_idx + 1, filtered.size - 1].min : 0
      new_option = filtered[target_idx]
      update_selected_index(new_option)
    end

    def handle_enter_key
      if @expanded
        filtered = filtered_options
        unless filtered.empty?
          if option = current_option
            @on_select.try &.call(option)
          end
        end
        @filter = ""
        @expanded = false
      else
        # Expand dropdown
        @expanded = true
        @filter = ""
        normalize_selection
      end
    end

    def handle_escape_key
      @expanded = false
      @filter = ""
    end

    private def handle_key(key : String)
      case key
      when "backspace"
        if @expanded && !@filter.empty?
          @filter = @filter[0...-1]
          normalize_selection
        end
      end
    end

    private def current_option : String?
      @options[@selected_index]?
    end

    private def filtered_options : Array(String)
      options = if @filter.empty?
                  @options
                else
                  @options.select(&.downcase.includes?(@filter.downcase))
                end
      adjust_selection(options)
      options
    end

    private def adjust_selection(filtered : Array(String))
      if filtered.empty?
        @selected_index = 0
        return
      end

      if (current = current_option) && filtered.includes?(current)
        return
      end

      update_selected_index(filtered.first)
    end

    private def update_selected_index(option : String)
      if idx = @options.index(option)
        @selected_index = idx
      end
    end

    # Calculate minimum width needed for dropdown
    def calculate_min_width : Int32
      # Prompt width + longest option + dropdown indicator
      prompt_width = text_width(@prompt) + 2 # prompt + space
      longest_option = max_text_width(@options)
      dropdown_indicator = 3 # " ▼ " or similar

      {prompt_width + longest_option + dropdown_indicator, 15}.max
    end

    # Calculate maximum width for dropdown
    def calculate_max_width : Int32
      # Dropdowns shouldn't be too wide
      content_width = calculate_min_width
      {content_width, 50}.min # Cap at reasonable width
    end

    # Calculate minimum height for dropdown
    def calculate_min_height : Int32
      1
    end

    def calculate_max_height : Terminal::Geometry::Size
      visible = @expanded ? [filtered_options.size, 10].min : 0
      Terminal::Geometry::Size.new(calculate_min_width, 1 + visible)
    end

    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      optimal_width = calculate_min_width
      actual_width = {width, optimal_width}.min
      actual_height = {height, calculate_max_height.height}.min

      prompt_line = render_prompt_line(actual_width)
      content = [prompt_line]

      if @expanded
        filtered = filtered_options
        max_visible = [actual_height - 1, 0].max

        filtered.first(max_visible).each do |option|
          content << render_option_line(option, option == current_option, actual_width)
        end

        if !@filter.empty? && content.size < actual_height
          content << render_filter_line(actual_width)
        end
      end

      content
    end

    private def render_prompt_line(width : Int32) : Array(Terminal::Cell)
      current = @options[@selected_index]? || "(none)"
      text = "#{@prompt} #{current} #{@expanded ? "▲" : "▼"}"

      line = Array.new(width) { Terminal::Cell.new(' ', bg: "blue") }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "white", bg: "blue", bold: true)
      end
      line
    end

    private def render_option_line(option : String, selected : Bool, width : Int32) : Array(Terminal::Cell)
      prefix = selected ? "> " : "  "
      text = "#{prefix}#{option}"

      fg = selected ? "black" : "white"
      bg = selected ? "cyan" : "default"

      line = Array.new(width) { Terminal::Cell.new(' ', bg: bg) }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: fg, bg: bg, bold: selected)
      end
      line
    end

    private def render_filter_line(width : Int32) : Array(Terminal::Cell)
      text = "Filter: #{@filter}"
      line = Array.new(width) { Terminal::Cell.new(' ', bg: "yellow") }
      text.chars.each_with_index do |ch, i|
        break if i >= width
        line[i] = Terminal::Cell.new(ch, fg: "black", bg: "yellow")
      end
      line
    end

    private def normalize_selection
      filtered_options
    end

    # Implement required Measurable methods
    def calculate_min_size : Terminal::Geometry::Size
      Terminal::Geometry::Size.new(calculate_min_width, calculate_min_height)
    end

    def calculate_max_size : Terminal::Geometry::Size
      Terminal::Geometry::Size.new(calculate_max_width, calculate_max_height)
    end
  end
end
