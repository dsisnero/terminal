# Layout system for dividing screen space into regions
# Inspired by Ratatui's Layout and Block components

module Terminal
  # Direction for layout splitting
  enum Direction
    Horizontal # Split left/right
    Vertical   # Split top/bottom
  end

  # Constraint types for sizing regions
  abstract class Constraint
    # Fixed size in characters
    class Length < Constraint
      getter value : Int32

      def initialize(@value : Int32)
      end

      def apply(available : Int32) : Int32
        @value
      end
    end

    # Percentage of available space
    class Percentage < Constraint
      getter value : Int32

      def initialize(@value : Int32)
        raise "Percentage must be 0-100" unless (0..100).includes?(@value)
      end

      def apply(available : Int32) : Int32
        (available * @value / 100).to_i
      end
    end

    # Minimum size needed
    class Min < Constraint
      getter value : Int32

      def initialize(@value : Int32)
      end

      def apply(available : Int32) : Int32
        {@value, available}.min
      end
    end

    # Maximum size allowed
    class Max < Constraint
      getter value : Int32

      def initialize(@value : Int32)
      end

      def apply(available : Int32) : Int32
        {@value, available}.min
      end
    end

    # Fill remaining space (ratio-based if multiple)
    class Ratio < Constraint
      getter value : Int32

      def initialize(@value : Int32)
      end

      def apply(available : Int32, total_ratio : Int32) : Int32
        (available * @value / total_ratio).to_i
      end
    end
  end

  # A rectangular area on the screen
  struct Rect
    getter x : Int32
    getter y : Int32
    getter width : Int32
    getter height : Int32

    def initialize(@x : Int32, @y : Int32, @width : Int32, @height : Int32)
    end

    def area : Int32
      @width * @height
    end

    def right : Int32
      @x + @width
    end

    def bottom : Int32
      @y + @height
    end

    def contains?(x : Int32, y : Int32) : Bool
      x >= @x && x < right && y >= @y && y < bottom
    end
  end

  # Layout engine for dividing space into regions
  class Layout
    getter direction : Direction
    getter constraints : Array(Constraint)
    getter margin : Int32

    def initialize(@direction : Direction, constraints, @margin : Int32 = 0)
      @constraints = constraints.map(&.as(Constraint))
    end

    # Split a rect according to constraints
    def split(area : Rect) : Array(Rect)
      # Apply margin
      inner_area = Rect.new(
        area.x + @margin,
        area.y + @margin,
        area.width - 2 * @margin,
        area.height - 2 * @margin
      )

      if @direction.horizontal?
        split_horizontal(inner_area)
      else
        split_vertical(inner_area)
      end
    end

    private def split_horizontal(area : Rect) : Array(Rect)
      available_width = area.width
      regions = [] of Rect
      x_offset = area.x

      # Calculate fixed sizes first and collect ratio constraints
      remaining_width = available_width
      ratio_constraints = [] of Constraint::Ratio
      fixed_widths = {} of Int32 => Int32

      @constraints.each_with_index do |constraint, index|
        case constraint
        when Constraint::Length, Constraint::Percentage, Constraint::Min, Constraint::Max
          size = constraint.apply(available_width)
          fixed_widths[index] = size
          remaining_width -= size
        when Constraint::Ratio
          ratio_constraints << constraint
        end
      end

      # Calculate ratio total
      total_ratio = ratio_constraints.sum(&.value)

      # Create regions
      @constraints.each_with_index do |constraint, index|
        width = case constraint
                when Constraint::Ratio
                  if total_ratio > 0
                    constraint.apply(remaining_width, total_ratio)
                  else
                    0
                  end
                else
                  fixed_widths[index]
                end

        regions << Rect.new(x_offset, area.y, width, area.height)
        x_offset += width
      end

      regions
    end

    private def split_vertical(area : Rect) : Array(Rect)
      available_height = area.height
      regions = [] of Rect
      y_offset = area.y

      # Calculate fixed sizes first and collect ratio constraints
      remaining_height = available_height
      ratio_constraints = [] of Constraint::Ratio
      fixed_heights = {} of Int32 => Int32

      @constraints.each_with_index do |constraint, index|
        case constraint
        when Constraint::Length, Constraint::Percentage, Constraint::Min, Constraint::Max
          size = constraint.apply(available_height)
          fixed_heights[index] = size
          remaining_height -= size
        when Constraint::Ratio
          ratio_constraints << constraint
        end
      end

      # Calculate ratio total
      total_ratio = ratio_constraints.sum(&.value)

      # Create regions
      @constraints.each_with_index do |constraint, index|
        height = case constraint
                 when Constraint::Ratio
                   if total_ratio > 0
                     constraint.apply(remaining_height, total_ratio)
                   else
                     0
                   end
                 else
                   fixed_heights[index]
                 end

        regions << Rect.new(area.x, y_offset, area.width, height)
        y_offset += height
      end

      regions
    end
  end
end
