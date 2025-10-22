# File: src/terminal/cell.cr
# Purpose: Define the Cell struct representing a single character cell with style.
# Cell is intentionally lightweight and value-like for safe message passing.

module Terminal
  struct Cell
    getter char : Char
    getter fg : String
    getter bg : String
    getter bold : Bool
    getter underline : Bool

    def initialize(@char : Char = ' ', @fg : String = "default", @bg : String = "default", @bold : Bool = false, @underline : Bool = false)
    end

    def ==(other : Terminal::Cell)
      char == other.char && fg == other.fg && bg == other.bg && bold == other.bold && underline == other.underline
    end

    # Write this cell to an IO using optimized ANSI sequences.
    # This method groups style codes; calling code should attempt to write runs of similarly-styled cells
    # to avoid resetting per-cell in high-volume rendering.
    def to_ansi(io : IO)
      seqs = [] of String
      seqs << "1" if bold
      seqs << "4" if underline
      case fg
      when "black"   then seqs << "30"
      when "red"     then seqs << "31"
      when "green"   then seqs << "32"
      when "yellow"  then seqs << "33"
      when "blue"    then seqs << "34"
      when "magenta" then seqs << "35"
      when "cyan"    then seqs << "36"
      when "white"   then seqs << "37"
      end
      case bg
      when "black"   then seqs << "40"
      when "red"     then seqs << "41"
      when "green"   then seqs << "42"
      when "yellow"  then seqs << "43"
      when "blue"    then seqs << "44"
      when "magenta" then seqs << "45"
      when "cyan"    then seqs << "46"
      when "white"   then seqs << "47"
      end

      if !seqs.empty?
        io.print "\e[#{seqs.join(";")}m"
        io.print char
        io.print "\e[0m"
      else
        io.print char
      end
    end
  end
end
