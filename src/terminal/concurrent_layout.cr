# Layout engine with concurrency support and SOLID principles
# Uses channels for thread-safe communication and async layout calculations

require "./geometry"

module Terminal
  module Layout
    # Layout calculation request
    struct LayoutRequest
      getter id : String
      getter area : Geometry::Rect
      getter constraints : Array(Constraint)
      getter direction : Direction
      getter response_channel : Channel(LayoutResponse)

      def initialize(@id : String, @area : Geometry::Rect, @constraints : Array(Constraint), @direction : Direction, @response_channel : Channel(LayoutResponse))
      end
    end

    # Layout calculation response
    struct LayoutResponse
      getter id : String
      getter regions : Array(Geometry::Rect)
      getter success : Bool
      getter error : String?

      def initialize(@id : String, @regions : Array(Geometry::Rect), @success : Bool = true, @error : String? = nil)
      end

      def self.error(id : String, error : String) : LayoutResponse
        new(id, [] of Geometry::Rect, false, error)
      end
    end

    # Direction for layout splitting
    enum Direction
      Horizontal # Split left/right
      Vertical   # Split top/bottom
    end

    # Base constraint interface following SRP
    abstract class Constraint
      abstract def calculate_size(available : Int32, context : ConstraintContext) : Int32
      abstract def flexible? : Bool

      # Fixed size constraint
      class Length < Constraint
        getter value : Int32

        def initialize(@value : Int32)
          raise ArgumentError.new("Length must be non-negative") if @value < 0
        end

        def calculate_size(available : Int32, context : ConstraintContext) : Int32
          {@value, available}.min
        end

        def flexible? : Bool
          false
        end
      end

      # Percentage-based constraint
      class Percentage < Constraint
        getter value : Int32

        def initialize(@value : Int32)
          raise ArgumentError.new("Percentage must be 0-100") unless (0..100).includes?(@value)
        end

        def calculate_size(available : Int32, context : ConstraintContext) : Int32
          (available * @value / 100).to_i
        end

        def flexible? : Bool
          false
        end
      end

      # Minimum size constraint
      class Min < Constraint
        getter value : Int32

        def initialize(@value : Int32)
          raise ArgumentError.new("Min value must be non-negative") if @value < 0
        end

        def calculate_size(available : Int32, context : ConstraintContext) : Int32
          {@value, available}.min
        end

        def flexible? : Bool
          false
        end
      end

      # Maximum size constraint
      class Max < Constraint
        getter value : Int32

        def initialize(@value : Int32)
          raise ArgumentError.new("Max value must be non-negative") if @value < 0
        end

        def calculate_size(available : Int32, context : ConstraintContext) : Int32
          {@value, available}.min
        end

        def flexible? : Bool
          false
        end
      end

      # Flexible ratio-based constraint
      class Ratio < Constraint
        getter value : Int32

        def initialize(@value : Int32)
          raise ArgumentError.new("Ratio must be positive") if @value <= 0
        end

        def calculate_size(available : Int32, context : ConstraintContext) : Int32
          return 0 if context.total_ratio == 0
          (context.remaining_space * @value / context.total_ratio).to_i
        end

        def flexible? : Bool
          true
        end
      end

      # Fill remaining space
      class Fill < Constraint
        def calculate_size(available : Int32, context : ConstraintContext) : Int32
          return 0 if context.fill_count == 0
          (context.remaining_space / context.fill_count).to_i
        end

        def flexible? : Bool
          true
        end
      end
    end

    # Context for constraint calculations following SRP
    struct ConstraintContext
      getter total_ratio : Int32
      getter remaining_space : Int32
      getter fill_count : Int32

      def initialize(@total_ratio : Int32, @remaining_space : Int32, @fill_count : Int32)
      end
    end

    # Layout calculator following SRP - only calculates layouts
    class LayoutCalculator
      def calculate(area : Geometry::Rect, constraints : Array(Constraint), direction : Direction) : Array(Geometry::Rect)
        return [area] if constraints.empty?

        case direction
        when .horizontal?
          calculate_horizontal(area, constraints)
        when .vertical?
          calculate_vertical(area, constraints)
        else
          [area]
        end
      end

      private def calculate_horizontal(area : Geometry::Rect, constraints : Array(Constraint)) : Array(Geometry::Rect)
        available_width = area.width
        context = build_constraint_context(constraints, available_width)

        regions = [] of Geometry::Rect
        x_offset = area.x

        constraints.each do |constraint|
          width = constraint.calculate_size(available_width, context)
          regions << Geometry::Rect.new(x_offset, area.y, width, area.height)
          x_offset += width
        end

        regions
      end

      private def calculate_vertical(area : Geometry::Rect, constraints : Array(Constraint)) : Array(Geometry::Rect)
        available_height = area.height
        context = build_constraint_context(constraints, available_height)

        regions = [] of Geometry::Rect
        y_offset = area.y

        constraints.each do |constraint|
          height = constraint.calculate_size(available_height, context)
          regions << Geometry::Rect.new(area.x, y_offset, area.width, height)
          y_offset += height
        end

        regions
      end

      private def build_constraint_context(constraints : Array(Constraint), available : Int32) : ConstraintContext
        # Calculate fixed sizes first
        fixed_size = 0
        total_ratio = 0
        fill_count = 0

        constraints.each do |constraint|
          case constraint
          when Constraint::Length, Constraint::Percentage, Constraint::Min, Constraint::Max
            fixed_size += constraint.calculate_size(available, ConstraintContext.new(0, 0, 0))
          when Constraint::Ratio
            total_ratio += constraint.value
          when Constraint::Fill
            fill_count += 1
          end
        end

        remaining_space = available - fixed_size
        ConstraintContext.new(total_ratio, remaining_space, fill_count)
      end
    end

    # Concurrent layout engine following OCP - extensible without modification
    class ConcurrentLayoutEngine
      @calculator : LayoutCalculator
      @request_channel : Channel(LayoutRequest)
      @worker_count : Int32
      @running : Bool

      def initialize(@worker_count : Int32 = 4)
        @calculator = LayoutCalculator.new
        @request_channel = Channel(LayoutRequest).new(100) # Buffered channel
        @running = false
      end

      def start
        return if @running
        @running = true

        @worker_count.times do |i|
          spawn(name: "layout_worker_#{i}") { worker_loop }
        end
      end

      def stop
        @running = false
        @request_channel.close
      end

      # Async layout calculation
      def calculate_async(id : String, area : Geometry::Rect, constraints : Array(Constraint), direction : Direction) : Channel(LayoutResponse)
        response_channel = Channel(LayoutResponse).new(1)
        request = LayoutRequest.new(id, area, constraints, direction, response_channel)

        @request_channel.send(request)
        response_channel
      end

      # Sync layout calculation
      def calculate_sync(area : Geometry::Rect, constraints : Array(Constraint), direction : Direction) : Array(Geometry::Rect)
        id = Random::Secure.hex(8)
        response_channel = calculate_async(id, area, constraints, direction)

        response = response_channel.receive
        raise Exception.new(response.error) unless response.success

        response.regions
      end

      private def worker_loop
        while @running
          begin
            request = @request_channel.receive?
            break unless request

            process_request(request)
          rescue ex
            # Log error but continue processing
            STDERR.puts "Layout worker error: #{ex.message}"
          end
        end
      end

      private def process_request(request : LayoutRequest)
        regions = @calculator.calculate(request.area, request.constraints, request.direction)
        response = LayoutResponse.new(request.id, regions)
        request.response_channel.send(response)
      rescue ex
        response = LayoutResponse.error(request.id, ex.message || "Unknown error")
        request.response_channel.send(response)
      end
    end

    # Layout builder following Builder pattern
    class LayoutBuilder
      @constraints : Array(Constraint)
      @direction : Direction
      @margin : Geometry::Insets

      def initialize
        @constraints = [] of Constraint
        @direction = Direction::Vertical
        @margin = Geometry::Insets.uniform(0)
      end

      def direction(dir : Direction) : LayoutBuilder
        @direction = dir
        self
      end

      def margin(value : Int32) : LayoutBuilder
        @margin = Geometry::Insets.uniform(value)
        self
      end

      def margin(insets : Geometry::Insets) : LayoutBuilder
        @margin = insets
        self
      end

      def length(value : Int32) : LayoutBuilder
        @constraints << Constraint::Length.new(value)
        self
      end

      def percentage(value : Int32) : LayoutBuilder
        @constraints << Constraint::Percentage.new(value)
        self
      end

      def ratio(value : Int32) : LayoutBuilder
        @constraints << Constraint::Ratio.new(value)
        self
      end

      def fill : LayoutBuilder
        @constraints << Constraint::Fill.new
        self
      end

      def min(value : Int32) : LayoutBuilder
        @constraints << Constraint::Min.new(value)
        self
      end

      def max(value : Int32) : LayoutBuilder
        @constraints << Constraint::Max.new(value)
        self
      end

      def build(engine : ConcurrentLayoutEngine) : BuiltLayout
        BuiltLayout.new(@constraints, @direction, @margin, engine)
      end
    end

    # Built layout ready for use
    class BuiltLayout
      @constraints : Array(Constraint)
      @direction : Direction
      @margin : Geometry::Insets
      @engine : ConcurrentLayoutEngine

      def initialize(@constraints : Array(Constraint), @direction : Direction, @margin : Geometry::Insets, @engine : ConcurrentLayoutEngine)
      end

      def split_sync(area : Geometry::Rect) : Array(Geometry::Rect)
        inner_area = @margin.apply_to(area)
        @engine.calculate_sync(inner_area, @constraints, @direction)
      end

      def split_async(id : String, area : Geometry::Rect) : Channel(LayoutResponse)
        inner_area = @margin.apply_to(area)
        @engine.calculate_async(id, inner_area, @constraints, @direction)
      end
    end

    # Factory for creating layouts (Factory pattern)
    class LayoutFactory
      @engine : ConcurrentLayoutEngine

      def initialize(@engine : ConcurrentLayoutEngine)
      end

      def self.create_with_engine(worker_count : Int32 = 4) : LayoutFactory
        engine = ConcurrentLayoutEngine.new(worker_count)
        engine.start
        new(engine)
      end

      def builder : LayoutBuilder
        LayoutBuilder.new
      end

      def vertical : LayoutBuilder
        builder.direction(Direction::Vertical)
      end

      def horizontal : LayoutBuilder
        builder.direction(Direction::Horizontal)
      end

      def stop_engine
        @engine.stop
      end
    end
  end
end
