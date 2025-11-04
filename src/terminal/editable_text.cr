# File: src/terminal/editable_text.cr
# Provides shared helpers for managing editable single-line text with cursor support.

module Terminal
  module EditableText
    extend self

    def insert(value : String, cursor_pos : Int32, char : Char, max_length : Int32? = nil) : {String, Int32}
      return {value, cursor_pos} if max_length && value.size >= max_length

      cursor_pos = clamp_cursor(cursor_pos, value)
      prefix = slice_prefix(value, cursor_pos)
      suffix = slice_suffix(value, cursor_pos)

      new_value = String.build do |io|
        io << prefix
        io << char
        io << suffix
      end
      {new_value, cursor_pos + 1}
    end

    def delete_before(value : String, cursor_pos : Int32) : {String, Int32}
      cursor_pos = clamp_cursor(cursor_pos, value)
      return {value, cursor_pos} if cursor_pos <= 0

      prefix = slice_prefix(value, cursor_pos - 1)
      suffix = slice_suffix(value, cursor_pos)

      {prefix + suffix, cursor_pos - 1}
    end

    def delete_at(value : String, cursor_pos : Int32) : {String, Int32}
      cursor_pos = clamp_cursor(cursor_pos, value)
      return {value, cursor_pos} if cursor_pos >= value.size

      prefix = slice_prefix(value, cursor_pos)
      suffix = slice_suffix(value, cursor_pos + 1)

      {prefix + suffix, cursor_pos}
    end

    def move_cursor(value : String, cursor_pos : Int32, delta : Int32) : Int32
      set_cursor(value, cursor_pos + delta)
    end

    def set_cursor(value : String, new_pos : Int32) : Int32
      max = value.size
      return 0 if new_pos < 0
      return max if new_pos > max
      new_pos
    end

    def clamp_cursor(cursor_pos : Int32, value : String) : Int32
      set_cursor(value, cursor_pos)
    end

    private def slice_prefix(value : String, length : Int32) : String
      value[0, length]? || ""
    end

    private def slice_suffix(value : String, start : Int32) : String
      value[start..]? || ""
    end
  end
end
