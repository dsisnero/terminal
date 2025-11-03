# Mapping table for Windows console key codes (returned by _getwch after an
# initial 0 or 0xE0 prefix). Centralizes translation to logical key names so it
# can be tested without Windows consoles.

module Terminal
  module WindowsKeyMap
    KEY_NAMES = {
       71_u16 => "home",
       72_u16 => "up",
       73_u16 => "page_up",
       75_u16 => "left",
       77_u16 => "right",
       79_u16 => "end",
       80_u16 => "down",
       81_u16 => "page_down",
       82_u16 => "insert",
       83_u16 => "delete",
       59_u16 => "f1",
       60_u16 => "f2",
       61_u16 => "f3",
       62_u16 => "f4",
       63_u16 => "f5",
       64_u16 => "f6",
       65_u16 => "f7",
       66_u16 => "f8",
       67_u16 => "f9",
       68_u16 => "f10",
      133_u16 => "f11",
      134_u16 => "f12",
    }

    MODIFIER_ORDER = {"ctrl", "alt", "shift"}

    def self.lookup(code : UInt16) : String?
      KEY_NAMES[code]?
    end

    def self.lookup_with_modifiers(code : UInt16, modifiers : Array(String)) : String?
      base = lookup(code)
      return unless base
      combine(base, modifiers)
    end

    def self.combine(base : String, modifiers : Array(String)) : String
      return base if modifiers.empty?
      parts = [] of String
      MODIFIER_ORDER.each do |name|
        parts << name if modifiers.includes?(name)
      end
      # Preserve any additional modifiers not in the standard ordering.
      modifiers.each do |name|
        parts << name unless MODIFIER_ORDER.includes?(name)
      end
      (parts << base).join('+')
    end
  end
end
