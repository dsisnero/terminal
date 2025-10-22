require "spec"
require "../src/terminal/concurrent_layout"

describe Terminal::Layout do
  describe Terminal::Layout::Constraint do
    describe Terminal::Layout::Constraint::Length do
      it "calculates fixed size" do
        constraint = Terminal::Layout::Constraint::Length.new(100)
        context = Terminal::Layout::ConstraintContext.new(0, 0, 0)

        constraint.calculate_size(200, context).should eq(100)
        constraint.calculate_size(50, context).should eq(50) # Clamped to available
      end

      it "raises error for negative length" do
        expect_raises(ArgumentError, "Length must be non-negative") do
          Terminal::Layout::Constraint::Length.new(-1)
        end
      end

      it "is not flexible" do
        constraint = Terminal::Layout::Constraint::Length.new(100)
        constraint.flexible?.should be_false
      end
    end

    describe Terminal::Layout::Constraint::Percentage do
      it "calculates percentage of available space" do
        constraint = Terminal::Layout::Constraint::Percentage.new(50)
        context = Terminal::Layout::ConstraintContext.new(0, 0, 0)

        constraint.calculate_size(200, context).should eq(100)
        constraint.calculate_size(100, context).should eq(50)
      end

      it "raises error for invalid percentage" do
        expect_raises(ArgumentError, "Percentage must be 0-100") do
          Terminal::Layout::Constraint::Percentage.new(150)
        end

        expect_raises(ArgumentError, "Percentage must be 0-100") do
          Terminal::Layout::Constraint::Percentage.new(-10)
        end
      end

      it "handles edge cases" do
        zero_percent = Terminal::Layout::Constraint::Percentage.new(0)
        hundred_percent = Terminal::Layout::Constraint::Percentage.new(100)
        context = Terminal::Layout::ConstraintContext.new(0, 0, 0)

        zero_percent.calculate_size(100, context).should eq(0)
        hundred_percent.calculate_size(100, context).should eq(100)
      end
    end

    describe Terminal::Layout::Constraint::Ratio do
      it "calculates ratio-based size" do
        constraint = Terminal::Layout::Constraint::Ratio.new(2)
        context = Terminal::Layout::ConstraintContext.new(5, 100, 0) # Total ratio = 5

        # Ratio constraints use context.remaining_space, not the available parameter
        constraint.calculate_size(0, context).should eq(40) # 100 * 2 / 5 = 40
      end

      it "handles zero total ratio" do
        constraint = Terminal::Layout::Constraint::Ratio.new(2)
        context = Terminal::Layout::ConstraintContext.new(0, 100, 0)

        constraint.calculate_size(0, context).should eq(0)
      end

      it "raises error for non-positive ratio" do
        expect_raises(ArgumentError, "Ratio must be positive") do
          Terminal::Layout::Constraint::Ratio.new(0)
        end
      end

      it "is flexible" do
        constraint = Terminal::Layout::Constraint::Ratio.new(1)
        constraint.flexible?.should be_true
      end
    end

    describe Terminal::Layout::Constraint::Fill do
      it "calculates fill size" do
        constraint = Terminal::Layout::Constraint::Fill.new
        context = Terminal::Layout::ConstraintContext.new(0, 100, 2) # 2 fill constraints

        constraint.calculate_size(0, context).should eq(50) # 100 / 2
      end

      it "handles zero fill count" do
        constraint = Terminal::Layout::Constraint::Fill.new
        context = Terminal::Layout::ConstraintContext.new(0, 100, 0)

        # This would cause division by zero, so implementation should handle it
        # Let's assume it returns 0 for safety
        constraint.calculate_size(0, context).should eq(0)
      end
    end
  end

  describe Terminal::Layout::LayoutCalculator do
    describe "#calculate" do
      it "returns single area for empty constraints" do
        calculator = Terminal::Layout::LayoutCalculator.new
        area = Terminal::Geometry::Rect.new(0, 0, 100, 50)

        constraints = [] of Terminal::Layout::Constraint
        result = calculator.calculate(area, constraints, Terminal::Layout::Direction::Horizontal)
        result.should eq([area])
      end

      context "horizontal layout" do
        it "splits area horizontally with fixed lengths" do
          calculator = Terminal::Layout::LayoutCalculator.new
          area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
          constraints = [
            Terminal::Layout::Constraint::Length.new(30).as(Terminal::Layout::Constraint),
            Terminal::Layout::Constraint::Length.new(70).as(Terminal::Layout::Constraint),
          ]

          result = calculator.calculate(area, constraints, Terminal::Layout::Direction::Horizontal)

          result.size.should eq(2)
          result[0].should eq(Terminal::Geometry::Rect.new(0, 0, 30, 50))
          result[1].should eq(Terminal::Geometry::Rect.new(30, 0, 70, 50))
        end

        it "splits area with percentage constraints" do
          calculator = Terminal::Layout::LayoutCalculator.new
          area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
          constraints = [
            Terminal::Layout::Constraint::Percentage.new(60).as(Terminal::Layout::Constraint),
            Terminal::Layout::Constraint::Percentage.new(40).as(Terminal::Layout::Constraint),
          ]

          result = calculator.calculate(area, constraints, Terminal::Layout::Direction::Horizontal)

          result.size.should eq(2)
          result[0].should eq(Terminal::Geometry::Rect.new(0, 0, 60, 50))
          result[1].should eq(Terminal::Geometry::Rect.new(60, 0, 40, 50))
        end
      end

      context "vertical layout" do
        it "splits area vertically with fixed lengths" do
          calculator = Terminal::Layout::LayoutCalculator.new
          area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
          constraints = [
            Terminal::Layout::Constraint::Length.new(20).as(Terminal::Layout::Constraint),
            Terminal::Layout::Constraint::Length.new(30).as(Terminal::Layout::Constraint),
          ]

          result = calculator.calculate(area, constraints, Terminal::Layout::Direction::Vertical)

          result.size.should eq(2)
          result[0].should eq(Terminal::Geometry::Rect.new(0, 0, 100, 20))
          result[1].should eq(Terminal::Geometry::Rect.new(0, 20, 100, 30))
        end
      end
    end
  end

  describe Terminal::Layout::ConcurrentLayoutEngine do
    it "calculates layout synchronously" do
      engine = Terminal::Layout::ConcurrentLayoutEngine.new(1)
      engine.start

      area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
      constraints = [
        Terminal::Layout::Constraint::Percentage.new(50).as(Terminal::Layout::Constraint),
        Terminal::Layout::Constraint::Percentage.new(50).as(Terminal::Layout::Constraint),
      ]

      result = engine.calculate_sync(area, constraints, Terminal::Layout::Direction::Horizontal)

      result.size.should eq(2)
      result[0].width.should eq(50)
      result[1].width.should eq(50)

      engine.stop
    end

    it "calculates layout asynchronously" do
      engine = Terminal::Layout::ConcurrentLayoutEngine.new(1)
      engine.start

      area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
      constraints = [
        Terminal::Layout::Constraint::Length.new(20).as(Terminal::Layout::Constraint),
        Terminal::Layout::Constraint::Length.new(30).as(Terminal::Layout::Constraint),
      ]

      response_channel = engine.calculate_async("test-1", area, constraints, Terminal::Layout::Direction::Vertical)
      response = response_channel.receive

      response.success.should be_true
      response.regions.size.should eq(2)
      response.regions[0].height.should eq(20)
      response.regions[1].height.should eq(30)

      engine.stop
    end

    it "handles errors in async calculation" do
      engine = Terminal::Layout::ConcurrentLayoutEngine.new(1)
      engine.start

      # Create a valid area but simulate an error with invalid constraints
      area = Terminal::Geometry::Rect.new(0, 0, 10, 50)

      # We'll simulate error by having constraints that exceed available space
      # This should work but might have implementation-specific error conditions
      constraints = [Terminal::Layout::Constraint::Length.new(50).as(Terminal::Layout::Constraint)]

      response_channel = engine.calculate_async("test-error", area, constraints, Terminal::Layout::Direction::Horizontal)
      response = response_channel.receive

      # This should succeed but with clamped size
      response.success.should be_true
      response.regions.size.should eq(1)

      engine.stop
    end
  end

  describe Terminal::Layout::LayoutBuilder do
    it "builds layout with fluent interface" do
      builder = Terminal::Layout::LayoutBuilder.new
      engine = Terminal::Layout::ConcurrentLayoutEngine.new(1)
      engine.start

      layout = builder
        .direction(Terminal::Layout::Direction::Horizontal)
        .percentage(60)
        .ratio(1)
        .length(20)
        .build(engine)

      area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
      result = layout.split_sync(area)

      result.size.should eq(3)
      # First: 60% of 100 = 60
      # Second: ratio gets remaining space after fixed sizes
      # Third: 20 fixed

      engine.stop
    end

    it "applies margins to layout" do
      builder = Terminal::Layout::LayoutBuilder.new
      engine = Terminal::Layout::ConcurrentLayoutEngine.new(1)
      engine.start

      layout = builder
        .direction(Terminal::Layout::Direction::Vertical)
        .margin(5)
        .percentage(100)
        .build(engine)

      area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
      result = layout.split_sync(area)

      # Should have margins applied: area becomes (5, 5, 90, 40)
      result.size.should eq(1)
      result[0].x.should eq(5)
      result[0].y.should eq(5)
      result[0].width.should eq(90)  # 100 - 2*5
      result[0].height.should eq(40) # 50 - 2*5

      engine.stop
    end
  end

  describe Terminal::Layout::LayoutFactory do
    it "creates layouts with factory" do
      factory = Terminal::Layout::LayoutFactory.create_with_engine(2)

      layout = factory.horizontal
        .percentage(50)
        .percentage(50)
        .build(factory.@engine)

      area = Terminal::Geometry::Rect.new(0, 0, 100, 50)
      result = layout.split_sync(area)

      result.size.should eq(2)
      result[0].width.should eq(50)
      result[1].width.should eq(50)

      factory.stop_engine
    end

    it "provides convenient builder methods" do
      factory = Terminal::Layout::LayoutFactory.create_with_engine(1)

      vertical_builder = factory.vertical
      horizontal_builder = factory.horizontal

      # Both should be LayoutBuilder instances configured differently
      vertical_builder.should be_a(Terminal::Layout::LayoutBuilder)
      horizontal_builder.should be_a(Terminal::Layout::LayoutBuilder)

      factory.stop_engine
    end
  end
end
