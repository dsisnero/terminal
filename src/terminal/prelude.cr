# src/terminal/prelude.cr
# All common requires for terminal library

# Messages and common types
require "./messages"
require "./cell"
require "./widget"
require "./basic_widget"

# Component implementations
require "./widget_manager"
require "./input_provider"
require "./event_loop"
require "./dispatcher"
require "./screen_buffer"
require "./diff_renderer"
require "./cursor_manager"
require "./service_provider"
require "./color_dsl"
require "./table_widget"
require "./spinner_widget"
require "./dropdown_widget"
require "./input_widget"
require "./form_widget"
require "./text_box_widget"
require "./tty"
require "./windows_key_map"
require "./prompts"
require "./ui_layout"
require "./ui_builder"
