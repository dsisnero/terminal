# Windows Raw Input Smoke Tests

> Goal: exercise `input_raw_windows.cr` and the VT input path on a real Windows terminal so regressions are caught before CI.

## Prerequisites
- Complete the steps in `docs/windows_devbox_setup.md` (Crystal + Git installed on a Windows 11/Server VM or physical box).
- Ensure the console supports VT mode (Windows 10+ does by default once `ENABLE_VIRTUAL_TERMINAL_INPUT` is enabled).

## Steps

1. **Clone & install**
   ```powershell
   git clone https://github.com/dsisnero/terminal.git
   cd terminal
   shards install
   ```
2. **Harness-friendly run**
   ```powershell
   setx TERMINAL_USE_HARNESS 1
   setx TERM_DEMO_TEST 0
   bin\run_example interactive_builder_demo
   ```
   - Validate arrow keys, Tab, `/quit`, and Esc maintain focus.
   - Paste multi-line text (right-click or Ctrl+Alt+V) to confirm bracketed paste is parsed.
3. **Scripted playback** (optional once component demo replays are captured):
   ```powershell
   setx TERM_DEMO_TEST 1
   bin\run_example component_chat_demo
   ```
   Harness logs should show `submitted:` events; the app should stop automatically.
4. **Record transcripts**
   Use the Ruby capture helper inside Git Bash or a WSL shell (both ship with Windows):
   ```bash
   scripts/capture_example.rb interactive_builder_demo -o log/win_interactive.typescript
   ```
   Store the `.typescript` file for replay-based regression tests.
5. **Report results**
   - Append your findings to `docs2/INPUT_PROVIDERS.md` under a new "Windows Smoke Runs" table (date, user, pass/fail).
   - File an issue if VT mode fails to enable (include console type and Windows build number).

## Future automation
- Add a GitHub Actions workflow targeting `windows-latest` that runs `bin/run_example interactive_builder_demo` under `ConPty`.
- Once transcripts are captured, add a CI job that replays them via `TypescriptReplay` to catch rendering regressions on Windows.
