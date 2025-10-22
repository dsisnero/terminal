# Block component for bordered panels with titles
# Inspired by Ratatui's Block component

require "./layout"

module Terminal
  # Border styles for blocks
  enum BorderType
    Plain
    Rounded
    Double
    Thick
  end

  # A bordered block/panel that can contain content
  class Block
    getter title : String?
    getter border_type : BorderType
    getter border_style : String?

    def initialize(@title : String? = nil, @border_type : BorderType = BorderType::Plain, @border_style : String? = nil)
    end

    # Render the block border and return inner area for content
    def render(area : Rect, buffer : IO::Memory) : Rect
      draw_borders(area, buffer)
      inner_area(area)
    end

    # Calculate inner area after borders
    def inner_area(area : Rect) : Rect
      Rect.new(
        area.x + 1,
        area.y + 1,
        area.width - 2,
        area.height - 2
      )
    end

    private def draw_borders(area : Rect, buffer : IO::Memory)
      chars = border_chars(@border_type)

      # Apply border style if specified
      if style = @border_style
        buffer << style
      end

      # Top border
      buffer << "\e[#{area.y + 1};#{area.x + 1}H"
      buffer << chars[:top_left]

      # Top line with title
      top_line_length = area.width - 2
      if title = @title
        title_length = title.size
        if title_length + 2 <= top_line_length
          padding_left = (top_line_length - title_length - 2) // 2
          padding_right = top_line_length - title_length - 2 - padding_left

          buffer << chars[:horizontal] * padding_left
          buffer << " #{title} "
          buffer << chars[:horizontal] * padding_right
        else
          buffer << chars[:horizontal] * top_line_length
        end
      else
        buffer << chars[:horizontal] * top_line_length
      end

      buffer << chars[:top_right]

      # Side borders
      (1...area.height - 1).each do |i|
        # Left border
        buffer << "\e[#{area.y + i + 1};#{area.x + 1}H"
        buffer << chars[:vertical]

        # Right border
        buffer << "\e[#{area.y + i + 1};#{area.x + area.width}H"
        buffer << chars[:vertical]
      end

      # Bottom border
      buffer << "\e[#{area.y + area.height};#{area.x + 1}H"
      buffer << chars[:bottom_left]
      buffer << chars[:horizontal] * (area.width - 2)
      buffer << chars[:bottom_right]

      # Reset style
      if @border_style
        buffer << "\e[0m"
      end
    end

    private def border_chars(type : BorderType)
      case type
      when .plain?
        {
          horizontal:   "─",
          vertical:     "│",
          top_left:     "┌",
          top_right:    "┐",
          bottom_left:  "└",
          bottom_right: "┘",
        }
      when .rounded?
        {
          horizontal:   "─",
          vertical:     "│",
          top_left:     "╭",
          top_right:    "╮",
          bottom_left:  "╰",
          bottom_right: "╯",
        }
      when .double?
        {
          horizontal:   "═",
          vertical:     "║",
          top_left:     "╔",
          top_right:    "╗",
          bottom_left:  "╚",
          bottom_right: "╝",
        }
      when .thick?
        {
          horizontal:   "━",
          vertical:     "┃",
          top_left:     "┏",
          top_right:    "┓",
          bottom_left:  "┗",
          bottom_right: "┛",
        }
      else
        # Default to plain
        {
          horizontal:   "─",
          vertical:     "│",
          top_left:     "┌",
          top_right:    "┐",
          bottom_left:  "└",
          bottom_right: "┘",
        }
      end
    end
  end
end
