# File: src/terminal/ui_layout.cr
# Shared layout primitives for the UI builder and widget manager.

require "./geometry"

module Terminal
  module UI
    enum Direction
      Horizontal
      Vertical
    end

    struct Constraint
      enum Kind
        Length
        Percent
        Flex
      end

      getter kind : Kind
      getter value : Int32

      def initialize(@kind : Kind, @value : Int32 = 1)
      end

      def self.length(value : Int32) : Constraint
        new(Kind::Length, value)
      end

      def self.percent(value : Int32) : Constraint
        new(Kind::Percent, value.clamp(0, 100))
      end

      def self.flex(weight : Int32 = 1) : Constraint
        new(Kind::Flex, weight.clamp(1, Int32::MAX))
      end
    end

    class LayoutNode
      property direction : Direction?
      property constraint : Constraint
      property id : String?
      property children : Array(LayoutNode)

      def initialize(@constraint : Constraint = Constraint.flex, @direction : Direction? = nil, @id : String? = nil)
        @children = [] of LayoutNode
      end

      def leaf?
        !@id.nil?
      end

      def add_child(node : LayoutNode)
        @children << node
      end

      def leaf_ids : Array(String)
        ids = [] of String
        collect_leaf_ids(ids)
        ids
      end

      def collect_leaf_ids(ids : Array(String))
        if leaf?
          ids << @id.not_nil!
        else
          @children.each(&.collect_leaf_ids(ids))
        end
      end
    end

    module LayoutResolver
      extend self

      def resolve(root : LayoutNode, rect : Geometry::Rect) : Hash(String, Geometry::Rect)
        result = {} of String => Geometry::Rect
        traverse(root, rect, result)
        result
      end

      private def traverse(node : LayoutNode, rect : Geometry::Rect, result : Hash(String, Geometry::Rect))
        if node.leaf?
          result[node.id.not_nil!] = rect
          return
        end

        direction = node.direction || Direction::Vertical
        children = node.children
        return if children.empty?

        total_space = direction == Direction::Horizontal ? rect.width : rect.height
        assigned = Array.new(children.size, 0)
        remaining = total_space
        flex_indices = [] of Int32
        flex_total = 0

        children.each_with_index do |child, idx|
          constraint = child.constraint
          case constraint.kind
          when Constraint::Kind::Length
            size = constraint.value.clamp(0, total_space)
            assigned[idx] = size
            remaining -= size
          when Constraint::Kind::Percent
            size = (total_space * constraint.value / 100).to_i
            assigned[idx] = size
            remaining -= size
          when Constraint::Kind::Flex
            flex_indices << idx
            flex_total += constraint.value
          end
        end

        if flex_total > 0
          remaining = remaining.clamp(0, total_space)
          allocated = 0
          flex_indices.each_with_index do |idx, pos|
            weight = children[idx].constraint.value
            size = flex_total > 0 ? (remaining * weight / flex_total).to_i : 0
            if pos == flex_indices.size - 1
              size = remaining - allocated
            else
              allocated += size
            end
            assigned[idx] = size.clamp(0, total_space)
          end
        end

        cursor_x = rect.x
        cursor_y = rect.y

        children.each_with_index do |child, idx|
          size = assigned[idx]
          next if size <= 0

          child_rect = if direction == Direction::Horizontal
                         Geometry::Rect.new(cursor_x, rect.y, size, rect.height)
                       else
                         Geometry::Rect.new(rect.x, cursor_y, rect.width, size)
                       end

          traverse(child, child_rect, result)

          if direction == Direction::Horizontal
            cursor_x += size
          else
            cursor_y += size
          end
        end
      end
    end
  end
end
