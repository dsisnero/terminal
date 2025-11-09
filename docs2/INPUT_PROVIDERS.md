# Input Providers & TTY Notes

## Providers

| Provider | Source | Purpose | Coverage |
|----------|--------|---------|----------|
| `Terminal::DummyInputProvider` | `src/terminal/input_provider.cr` | Emits scripted sequences for specs/demos | `spec/dummy_input_provider_spec.cr` |
| `Terminal::RawInputProvider` (Unix) | `src/terminal/input_raw_unix.cr` | Puts STDIN in raw mode via termios, handles bracketed paste | Covered indirectly via integration specs; requires manual smoke tests |
| `Terminal::RawInputProvider` (Windows) | `src/terminal/input_raw_windows.cr` | Enables VT input, maps console keys to internal events | `spec/windows_key_map_spec.cr` for mapping; requires manual/CI smoke tests |

## Smoke Testing Guidance

1. **Unix Raw Input**
   ```bash
   scripts/smoke_raw_input.rb
   ```
   - Drives `interactive_builder_demo` via PTY, sending plain text plus a bracketed paste sequence.
   - Ensures RawInputProvider handles paste + normal keys and restores the terminal afterward.

2. **Windows VT Input**
   - Run the same demo on a Windows host/VM with `TERMINAL_USE_HARNESS=1`.
   - Verify that `input_raw_windows.cr` enables VT mode and that key mappings (Ctrl+C, arrows, etc.) match `spec/windows_key_map_spec.cr`.

## TTY Helpers

- `Terminal::TTY.with_raw_mode` wraps the low-level termios/Win32 toggles used by both prompts (`Terminal::Prompts`) and raw input providers.
- Specs should rely on higher-level components; only integration/manual tests need to exercise the real TTY behaviour.

## Action Items

- Record smoke-test results (per platform) under this doc when performed.
- Wire Windows CI smoke tests to execute the interactive demo under harness control once available.

## Windows Smoke Runs

Record manual runs here (date, console, result).

| Date | Operator | Console | Result/Notes |
|------|----------|---------|--------------|
