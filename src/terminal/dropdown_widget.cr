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
      @expanded : Bool = false
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
          end
        end
      end
    end
    
    # Override navigation for dropdown-specific behavior
    def handle_up_key
      if @expanded && @selected_index > 0
        @selected_index -= 1
      end
    end
    
    def handle_down_key
      if @expanded && @selected_index < filtered_options.size - 1
        @selected_index += 1
      end
    end
    
    def handle_enter_key
      if @expanded
        # Select current item
        if current_option = filtered_options[@selected_index]?
          @on_select.try &.call(current_option)
        end
        @expanded = false
      else
        # Expand dropdown
        @expanded = true
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
        end
      end
    end
    
    private def filtered_options : Array(String)
      if @filter.empty?
        @options
      else
        @options.select { |opt| opt.downcase.includes?(@filter.downcase) }
      end
    end

    # Calculate minimum width needed for dropdown
    def calculate_min_width : Int32
      # Prompt width + longest option + dropdown indicator
      prompt_width = text_width(@prompt) + 2  # prompt + space
      longest_option = max_text_width(@options)
      dropdown_indicator = 3  # " ▼ " or similar
      
      {prompt_width + longest_option + dropdown_indicator, 15}.max
    end

    # Calculate maximum width for dropdown  
    def calculate_max_width : Int32
      # Dropdowns shouldn't be too wide
      content_width = calculate_min_width
      {content_width, 50}.min  # Cap at reasonable width
    end

    # Calculate minimum height for dropdown
    def calculate_min_height : Int32
      if @expanded
        # Prompt + visible options (limited)
        visible_options = {filtered_options.size, 8}.min  # Show max 8 options
        1 + visible_options  # prompt line + options
      else
        1  # Just the prompt line when collapsed
      end
    end

    # Calculate maximum height for dropdown
    def calculate_max_height : Int32
      if @expanded
        # Prompt + all options but cap it
        1 + {filtered_options.size, 10}.min  # Max 10 options visible
      else
        1  # Just the prompt line when collapsed
      end
    end
    
    def render(width : Int32, height : Int32) : Array(Array(Terminal::Cell))
      # Use content-based width instead of full parameter
      actual_width = calculate_optimal_width(width)
      
      result = [] of Array(Terminal::Cell)
      
      # Prompt line with current selection indicator
      result << render_prompt_line(actual_width)
      
      # If expanded, show options
      if @expanded
        filtered = filtered_options
        max_visible = height - 2  # Reserve space for prompt and border
        
        filtered.each_with_index do |option, idx|
          break if idx >= max_visible
          option_line = render_option_line(option, idx == @selected_index, actual_width)
          result << option_line
        end
        
        # Show filter if active
        if !@filter.empty?
          filter_line = render_filter_line(actual_width)
          result << filter_line
        end
      end
      
      # Pad remaining lines
      while result.size < height
        result << Array.new(actual_width) { Terminal::Cell.new(' ') }
      end
      
      result[0...height]
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
  end
end
