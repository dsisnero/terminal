# Geometric primitives and calculations for terminal layouts
# Provides reusable measurement and positioning functionality

module Terminal
  # Geometric measurements and calculations
  module Geometry
    # A point in 2D space
    struct Point
      getter x : Int32
      getter y : Int32

      def initialize(@x : Int32, @y : Int32)
      end

      def +(other : Point) : Point
        Point.new(@x + other.x, @y + other.y)
      end

      def -(other : Point) : Point
        Point.new(@x - other.x, @y - other.y)
      end

      def distance_to(other : Point) : Float64
        Math.sqrt((@x - other.x) ** 2 + (@y - other.y) ** 2)
      end
    end

    # Size dimensions
    struct Size
      getter width : Int32
      getter height : Int32

      def initialize(@width : Int32, @height : Int32)
        raise ArgumentError.new("Width must be non-negative") if @width < 0
        raise ArgumentError.new("Height must be non-negative") if @height < 0
      end

      def area : Int32
        @width * @height
      end

      def fits_in?(other : Size) : Bool
        @width <= other.width && @height <= other.height
      end

      def scale(factor : Float64) : Size
        Size.new((@width * factor).to_i, (@height * factor).to_i)
      end
    end

    # A rectangular area with position and dimensions
    struct Rect
      getter x : Int32
      getter y : Int32
      getter width : Int32
      getter height : Int32

      def initialize(@x : Int32, @y : Int32, @width : Int32, @height : Int32)
        raise ArgumentError.new("Width must be non-negative") if @width < 0
        raise ArgumentError.new("Height must be non-negative") if @height < 0
      end

      def self.from_position_size(position : Point, size : Size) : Rect
        new(position.x, position.y, size.width, size.height)
      end

      def position : Point
        Point.new(@x, @y)
      end

      def size : Size
        Size.new(@width, @height)
      end

      def right : Int32
        @x + @width
      end

      def bottom : Int32
        @y + @height
      end

      def center : Point
        Point.new(@x + @width // 2, @y + @height // 2)
      end

      def area : Int32
        @width * @height
      end

      def contains?(x : Int32, y : Int32) : Bool
        x >= @x && x < right && y >= @y && y < bottom
      end

      def contains?(point : Point) : Bool
        contains?(point.x, point.y)
      end

      def overlaps?(other : Rect) : Bool
        !(@x >= other.right || other.x >= right || @y >= other.bottom || other.y >= bottom)
      end

      def intersect(other : Rect) : Rect?
        left = {@x, other.x}.max
        top = {@y, other.y}.max
        right = {self.right, other.right}.min
        bottom = {self.bottom, other.bottom}.min

        return nil if left >= right || top >= bottom
        Rect.new(left, top, right - left, bottom - top)
      end

      def union(other : Rect) : Rect
        left = {@x, other.x}.min
        top = {@y, other.y}.min
        right = {self.right, other.right}.max
        bottom = {self.bottom, other.bottom}.max
        Rect.new(left, top, right - left, bottom - top)
      end

      def translate(dx : Int32, dy : Int32) : Rect
        Rect.new(@x + dx, @y + dy, @width, @height)
      end

      def translate(offset : Point) : Rect
        translate(offset.x, offset.y)
      end

      def resize(new_width : Int32, new_height : Int32) : Rect
        Rect.new(@x, @y, new_width, new_height)
      end

      def resize(new_size : Size) : Rect
        resize(new_size.width, new_size.height)
      end

      def shrink(margin : Int32) : Rect
        Rect.new(@x + margin, @y + margin, @width - 2 * margin, @height - 2 * margin)
      end

      def expand(margin : Int32) : Rect
        Rect.new(@x - margin, @y - margin, @width + 2 * margin, @height + 2 * margin)
      end
    end

    # Margin/padding specification
    struct Insets
      getter top : Int32
      getter right : Int32
      getter bottom : Int32
      getter left : Int32

      def initialize(@top : Int32, @right : Int32, @bottom : Int32, @left : Int32)
      end

      def self.uniform(value : Int32) : Insets
        new(value, value, value, value)
      end

      def self.symmetric(vertical : Int32, horizontal : Int32) : Insets
        new(vertical, horizontal, vertical, horizontal)
      end

      def horizontal : Int32
        @left + @right
      end

      def vertical : Int32
        @top + @bottom
      end

      def apply_to(rect : Rect) : Rect
        Rect.new(
          rect.x + @left,
          rect.y + @top,
          rect.width - horizontal,
          rect.height - vertical
        )
      end

      def expand_rect(rect : Rect) : Rect
        Rect.new(
          rect.x - @left,
          rect.y - @top,
          rect.width + horizontal,
          rect.height + vertical
        )
      end
    end
  end

  # Text measurement utilities
  module TextMeasurement
    extend self

    # Calculate display width of text (handles ANSI escape sequences)
    def text_width(text : String) : Int32
      # Remove ANSI escape sequences
      clean_text = text.gsub(/\e\[[0-9;]*m/, "")
      clean_text.size
    end

    # Calculate maximum width from array of texts
    def max_text_width(texts : Array(String)) : Int32
      return 0 if texts.empty?
      texts.max_of { |text| text_width(text) }
    end

    # Word wrap text to specified width
    def wrap_text(text : String, width : Int32) : Array(String)
      return [text] if width <= 0

      words = text.split(' ')
      lines = [] of String
      current_line = ""

      words.each do |word|
        test_line = current_line.empty? ? word : "#{current_line} #{word}"

        if text_width(test_line) <= width
          current_line = test_line
        else
          lines << current_line unless current_line.empty?
          current_line = word
        end
      end

      lines << current_line unless current_line.empty?
      lines.empty? ? [""] : lines
    end

    # Truncate text to fit width with ellipsis
    def truncate_text(text : String, width : Int32, ellipsis : String = "...") : String
      return text if text_width(text) <= width
      return ellipsis if width <= text_width(ellipsis)

      target_width = width - text_width(ellipsis)
      truncated = ""

      text.each_char do |char|
        test = truncated + char
        break if text_width(test) > target_width
        truncated = test
      end

      truncated + ellipsis
    end

    # Center text within specified width
    def center_text(text : String, width : Int32, padding_char : Char = ' ') : String
      text_len = text_width(text)
      return text if text_len >= width

      total_padding = width - text_len
      left_padding = total_padding // 2
      right_padding = total_padding - left_padding

      "#{padding_char.to_s * left_padding}#{text}#{padding_char.to_s * right_padding}"
    end

    # Align text within specified width
    def align_text(text : String, width : Int32, alignment : Symbol = :left, padding_char : Char = ' ') : String
      text_len = text_width(text)
      return text if text_len >= width

      padding = width - text_len

      case alignment
      when :left
        text + padding_char.to_s * padding
      when :right
        padding_char.to_s * padding + text
      when :center
        center_text(text, width, padding_char)
      else
        text + padding_char.to_s * padding
      end
    end
  end

  # Measurement calculations for UI components
  module Measurable
    include Geometry
    include TextMeasurement

    # Calculate minimum required dimensions
    abstract def calculate_min_size : Size

    # Calculate maximum useful dimensions
    abstract def calculate_max_size : Size

    # Calculate optimal dimensions based on content
    def calculate_optimal_size : Size
      calculate_min_size
    end

    # Calculate preferred dimensions within constraints
    def calculate_preferred_size(constraints : Size) : Size
      optimal = calculate_optimal_size
      min = calculate_min_size
      max = calculate_max_size

      width = {constraints.width, max.width}.min
      width = {width, min.width}.max

      height = {constraints.height, max.height}.min
      height = {height, min.height}.max

      Size.new(width, height)
    end

    # Check if size fits within constraints
    def size_fits?(size : Size, constraints : Size) : Bool
      size.fits_in?(constraints)
    end
  end
end
