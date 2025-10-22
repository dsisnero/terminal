# File: src/terminal/color_dsl.cr
# Convenience helper methods for building styled Cell arrays from strings.
#
# Usage:
#   include Terminal::ColorDSL
#   red_line = red("Error!")
#   bold_green = bold("OK", fg: :green)
#   line = styled_line("Title", width, :center, fg: :yellow, bold: true)

require "../terminal/cell"

module Terminal
  module ColorDSL
    COLOR_NAMES = {
      black:   "black",
      red:     "red",
      green:   "green",
      yellow:  "yellow",
      blue:    "blue",
      magenta: "magenta",
      cyan:    "cyan",
      white:   "white",
      default: "default",
    }

    # Build an array of Cells from a string with given style
    def cells(text : String, fg : Symbol | String = :default, bg : Symbol | String = :default, bold : Bool = false, underline : Bool = false) : Array(Terminal::Cell)
      fg_name = fg.is_a?(Symbol) ? (COLOR_NAMES[fg]? || fg.to_s) : fg
      bg_name = bg.is_a?(Symbol) ? (COLOR_NAMES[bg]? || bg.to_s) : bg
      text.chars.map { |ch| Terminal::Cell.new(ch, fg_name, bg_name, bold, underline) }
    end

    # Style with keyword-style API
    def style(text : String, fg : Symbol | String = :default, bg : Symbol | String = :default, bold : Bool = false, underline : Bool = false) : Array(Terminal::Cell)
      cells(text, fg, bg, bold, underline)
    end

    # Convenience foreground helpers via macro generation
    {% for name in [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white] %}
      def {{name.id}}(text : String) : Array(Terminal::Cell)
        cells(text, :{{name.id}})
      end
    {% end %}

    # Background helpers (on_color)
    {% for name in [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white] %}
      def on_{{name.id}}(text : String) : Array(Terminal::Cell)
        cells(text, :default, :{{name.id}})
      end
    {% end %}

    # Bold / underline wrappers operating on String -> Array(Terminal::Cell)
    def bold(text : String, fg : Symbol | String = :default, bg : Symbol | String = :default) : Array(Terminal::Cell)
      cells(text, fg, bg, true, false)
    end

    def underline(text : String, fg : Symbol | String = :default, bg : Symbol | String = :default) : Array(Terminal::Cell)
      cells(text, fg, bg, false, true)
    end

    # Compose a styled, padded line of fixed width with alignment
    def styled_line(text : String, width : Int32, align : Symbol = :left, fg : Symbol | String = :default, bg : Symbol | String = :default, bold : Bool = false, underline : Bool = false) : Array(Terminal::Cell)
      content = case align
                when :left
                  text.ljust(width)
                when :right
                  text.rjust(width)
                when :center
                  if text.size >= width
                    text[0...width]
                  else
                    left = ((width - text.size) / 2).to_i
                    right = width - text.size - left
                    (" " * left) + text + (" " * right)
                  end
                else
                  text.ljust(width)
                end
      cells(content[0...width], fg, bg, bold, underline)
    end
  end
end
