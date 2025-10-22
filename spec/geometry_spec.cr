require "spec"
require "../src/terminal/geometry"

describe Terminal::Geometry do
  describe Terminal::Geometry::Point do
    describe "#initialize" do
      it "creates a point with x and y coordinates" do
        point = Terminal::Geometry::Point.new(10, 20)
        point.x.should eq(10)
        point.y.should eq(20)
      end
    end

    describe "#+" do
      it "adds two points together" do
        p1 = Terminal::Geometry::Point.new(10, 20)
        p2 = Terminal::Geometry::Point.new(5, 15)
        result = p1 + p2

        result.x.should eq(15)
        result.y.should eq(35)
      end
    end

    describe "#-" do
      it "subtracts one point from another" do
        p1 = Terminal::Geometry::Point.new(10, 20)
        p2 = Terminal::Geometry::Point.new(5, 15)
        result = p1 - p2

        result.x.should eq(5)
        result.y.should eq(5)
      end
    end

    describe "#distance_to" do
      it "calculates distance between points" do
        p1 = Terminal::Geometry::Point.new(0, 0)
        p2 = Terminal::Geometry::Point.new(3, 4)

        p1.distance_to(p2).should be_close(5.0, 0.001)
      end

      it "calculates zero distance to itself" do
        point = Terminal::Geometry::Point.new(10, 20)
        point.distance_to(point).should eq(0.0)
      end
    end
  end

  describe Terminal::Geometry::Size do
    describe "#initialize" do
      it "creates a size with width and height" do
        size = Terminal::Geometry::Size.new(100, 50)
        size.width.should eq(100)
        size.height.should eq(50)
      end

      it "raises error for negative width" do
        expect_raises(ArgumentError, "Width must be non-negative") do
          Terminal::Geometry::Size.new(-1, 50)
        end
      end

      it "raises error for negative height" do
        expect_raises(ArgumentError, "Height must be non-negative") do
          Terminal::Geometry::Size.new(100, -1)
        end
      end

      it "allows zero dimensions" do
        size = Terminal::Geometry::Size.new(0, 0)
        size.width.should eq(0)
        size.height.should eq(0)
      end
    end

    describe "#area" do
      it "calculates area correctly" do
        size = Terminal::Geometry::Size.new(10, 20)
        size.area.should eq(200)
      end

      it "returns zero for zero dimensions" do
        size = Terminal::Geometry::Size.new(0, 5)
        size.area.should eq(0)
      end
    end

    describe "#fits_in?" do
      it "returns true if size fits within another" do
        small = Terminal::Geometry::Size.new(10, 20)
        large = Terminal::Geometry::Size.new(15, 25)

        small.fits_in?(large).should be_true
      end

      it "returns false if size doesn't fit" do
        large = Terminal::Geometry::Size.new(15, 25)
        small = Terminal::Geometry::Size.new(10, 20)

        large.fits_in?(small).should be_false
      end

      it "returns true for equal sizes" do
        size1 = Terminal::Geometry::Size.new(10, 20)
        size2 = Terminal::Geometry::Size.new(10, 20)

        size1.fits_in?(size2).should be_true
      end
    end

    describe "#scale" do
      it "scales size by factor" do
        size = Terminal::Geometry::Size.new(10, 20)
        scaled = size.scale(2.0)

        scaled.width.should eq(20)
        scaled.height.should eq(40)
      end

      it "handles fractional scaling" do
        size = Terminal::Geometry::Size.new(10, 20)
        scaled = size.scale(0.5)

        scaled.width.should eq(5)
        scaled.height.should eq(10)
      end
    end
  end

  describe Terminal::Geometry::Rect do
    describe "#initialize" do
      it "creates a rect with position and size" do
        rect = Terminal::Geometry::Rect.new(10, 20, 100, 50)
        rect.x.should eq(10)
        rect.y.should eq(20)
        rect.width.should eq(100)
        rect.height.should eq(50)
      end

      it "raises error for negative dimensions" do
        expect_raises(ArgumentError) do
          Terminal::Geometry::Rect.new(0, 0, -1, 10)
        end
      end
    end

    describe ".from_position_size" do
      it "creates rect from position and size objects" do
        pos = Terminal::Geometry::Point.new(5, 10)
        size = Terminal::Geometry::Size.new(20, 30)
        rect = Terminal::Geometry::Rect.from_position_size(pos, size)

        rect.x.should eq(5)
        rect.y.should eq(10)
        rect.width.should eq(20)
        rect.height.should eq(30)
      end
    end

    describe "#position" do
      it "returns position as Point" do
        rect = Terminal::Geometry::Rect.new(5, 10, 20, 30)
        pos = rect.position

        pos.x.should eq(5)
        pos.y.should eq(10)
      end
    end

    describe "#size" do
      it "returns size as Size" do
        rect = Terminal::Geometry::Rect.new(5, 10, 20, 30)
        size = rect.size

        size.width.should eq(20)
        size.height.should eq(30)
      end
    end

    describe "#right" do
      it "returns right edge coordinate" do
        rect = Terminal::Geometry::Rect.new(10, 20, 100, 50)
        rect.right.should eq(110)
      end
    end

    describe "#bottom" do
      it "returns bottom edge coordinate" do
        rect = Terminal::Geometry::Rect.new(10, 20, 100, 50)
        rect.bottom.should eq(70)
      end
    end

    describe "#center" do
      it "returns center point" do
        rect = Terminal::Geometry::Rect.new(0, 0, 100, 50)
        center = rect.center

        center.x.should eq(50)
        center.y.should eq(25)
      end
    end

    describe "#area" do
      it "calculates area" do
        rect = Terminal::Geometry::Rect.new(0, 0, 10, 20)
        rect.area.should eq(200)
      end
    end

    describe "#contains?" do
      it "checks if point is inside rect" do
        rect = Terminal::Geometry::Rect.new(10, 10, 20, 20)

        rect.contains?(15, 15).should be_true
        rect.contains?(5, 5).should be_false
        rect.contains?(35, 35).should be_false
      end

      it "works with Point objects" do
        rect = Terminal::Geometry::Rect.new(10, 10, 20, 20)
        point_inside = Terminal::Geometry::Point.new(15, 15)
        point_outside = Terminal::Geometry::Point.new(5, 5)

        rect.contains?(point_inside).should be_true
        rect.contains?(point_outside).should be_false
      end

      it "excludes right and bottom edges" do
        rect = Terminal::Geometry::Rect.new(0, 0, 10, 10)

        rect.contains?(9, 9).should be_true
        rect.contains?(10, 9).should be_false
        rect.contains?(9, 10).should be_false
      end
    end

    describe "#overlaps?" do
      it "detects overlapping rectangles" do
        rect1 = Terminal::Geometry::Rect.new(0, 0, 10, 10)
        rect2 = Terminal::Geometry::Rect.new(5, 5, 10, 10)

        rect1.overlaps?(rect2).should be_true
        rect2.overlaps?(rect1).should be_true
      end

      it "detects non-overlapping rectangles" do
        rect1 = Terminal::Geometry::Rect.new(0, 0, 10, 10)
        rect2 = Terminal::Geometry::Rect.new(20, 20, 10, 10)

        rect1.overlaps?(rect2).should be_false
        rect2.overlaps?(rect1).should be_false
      end

      it "handles touching rectangles" do
        rect1 = Terminal::Geometry::Rect.new(0, 0, 10, 10)
        rect2 = Terminal::Geometry::Rect.new(10, 0, 10, 10)

        rect1.overlaps?(rect2).should be_false
      end
    end

    describe "#intersect" do
      it "calculates intersection of overlapping rectangles" do
        rect1 = Terminal::Geometry::Rect.new(0, 0, 10, 10)
        rect2 = Terminal::Geometry::Rect.new(5, 5, 10, 10)

        intersection = rect1.intersect(rect2)
        intersection.should_not be_nil

        if intersection
          intersection.x.should eq(5)
          intersection.y.should eq(5)
          intersection.width.should eq(5)
          intersection.height.should eq(5)
        end
      end

      it "returns nil for non-overlapping rectangles" do
        rect1 = Terminal::Geometry::Rect.new(0, 0, 10, 10)
        rect2 = Terminal::Geometry::Rect.new(20, 20, 10, 10)

        rect1.intersect(rect2).should be_nil
      end
    end

    describe "#union" do
      it "calculates union of rectangles" do
        rect1 = Terminal::Geometry::Rect.new(0, 0, 10, 10)
        rect2 = Terminal::Geometry::Rect.new(5, 5, 10, 10)

        union = rect1.union(rect2)
        union.x.should eq(0)
        union.y.should eq(0)
        union.width.should eq(15)
        union.height.should eq(15)
      end
    end

    describe "#translate" do
      it "translates rectangle by offset" do
        rect = Terminal::Geometry::Rect.new(10, 20, 30, 40)
        translated = rect.translate(5, 10)

        translated.x.should eq(15)
        translated.y.should eq(30)
        translated.width.should eq(30)
        translated.height.should eq(40)
      end

      it "works with Point offset" do
        rect = Terminal::Geometry::Rect.new(10, 20, 30, 40)
        offset = Terminal::Geometry::Point.new(5, 10)
        translated = rect.translate(offset)

        translated.x.should eq(15)
        translated.y.should eq(30)
      end
    end

    describe "#resize" do
      it "resizes rectangle" do
        rect = Terminal::Geometry::Rect.new(10, 20, 30, 40)
        resized = rect.resize(50, 60)

        resized.x.should eq(10)
        resized.y.should eq(20)
        resized.width.should eq(50)
        resized.height.should eq(60)
      end

      it "works with Size object" do
        rect = Terminal::Geometry::Rect.new(10, 20, 30, 40)
        new_size = Terminal::Geometry::Size.new(50, 60)
        resized = rect.resize(new_size)

        resized.width.should eq(50)
        resized.height.should eq(60)
      end
    end

    describe "#shrink" do
      it "shrinks rectangle by margin" do
        rect = Terminal::Geometry::Rect.new(10, 20, 30, 40)
        shrunk = rect.shrink(5)

        shrunk.x.should eq(15)
        shrunk.y.should eq(25)
        shrunk.width.should eq(20)
        shrunk.height.should eq(30)
      end
    end

    describe "#expand" do
      it "expands rectangle by margin" do
        rect = Terminal::Geometry::Rect.new(10, 20, 30, 40)
        expanded = rect.expand(5)

        expanded.x.should eq(5)
        expanded.y.should eq(15)
        expanded.width.should eq(40)
        expanded.height.should eq(50)
      end
    end
  end

  describe Terminal::Geometry::Insets do
    describe "#initialize" do
      it "creates insets with all sides" do
        insets = Terminal::Geometry::Insets.new(1, 2, 3, 4)
        insets.top.should eq(1)
        insets.right.should eq(2)
        insets.bottom.should eq(3)
        insets.left.should eq(4)
      end
    end

    describe ".uniform" do
      it "creates uniform insets" do
        insets = Terminal::Geometry::Insets.uniform(5)
        insets.top.should eq(5)
        insets.right.should eq(5)
        insets.bottom.should eq(5)
        insets.left.should eq(5)
      end
    end

    describe ".symmetric" do
      it "creates symmetric insets" do
        insets = Terminal::Geometry::Insets.symmetric(10, 20)
        insets.top.should eq(10)
        insets.bottom.should eq(10)
        insets.left.should eq(20)
        insets.right.should eq(20)
      end
    end

    describe "#horizontal" do
      it "calculates total horizontal insets" do
        insets = Terminal::Geometry::Insets.new(1, 2, 3, 4)
        insets.horizontal.should eq(6) # left + right = 4 + 2
      end
    end

    describe "#vertical" do
      it "calculates total vertical insets" do
        insets = Terminal::Geometry::Insets.new(1, 2, 3, 4)
        insets.vertical.should eq(4) # top + bottom = 1 + 3
      end
    end

    describe "#apply_to" do
      it "applies insets to rectangle (shrinks)" do
        rect = Terminal::Geometry::Rect.new(0, 0, 100, 50)
        insets = Terminal::Geometry::Insets.new(5, 10, 15, 20)

        result = insets.apply_to(rect)
        result.x.should eq(20)      # left
        result.y.should eq(5)       # top
        result.width.should eq(70)  # 100 - (left + right) = 100 - 30
        result.height.should eq(30) # 50 - (top + bottom) = 50 - 20
      end
    end

    describe "#expand_rect" do
      it "expands rectangle by insets" do
        rect = Terminal::Geometry::Rect.new(20, 10, 60, 40)
        insets = Terminal::Geometry::Insets.new(5, 10, 15, 20)

        result = insets.expand_rect(rect)
        result.x.should eq(0)       # x - left = 20 - 20
        result.y.should eq(5)       # y - top = 10 - 5
        result.width.should eq(90)  # width + horizontal = 60 + 30
        result.height.should eq(60) # height + vertical = 40 + 20
      end
    end
  end
end
