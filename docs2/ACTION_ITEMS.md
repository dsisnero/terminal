# Audit Action Items

1. **Legacy / Unused Files**
   - *(none pending — `Block` helper now lives under `examples/support`.)*

2. **Spec Gaps**
   - Platform raw input (`input_raw_unix.cr`, `input_raw_windows.cr`) rely on manual coverage; see `docs2/INPUT_PROVIDERS.md` for smoke-test instructions. Parser-level specs exist for Unix and we now have `scripts/smoke_raw_input.rb` for macOS/Linux; next step is wiring Windows smoke tests/dev-box automation.

3. **Docs Refresh**
   - Replace legacy `README.md` sections referencing deprecated demos with pointers to the builder/component model once docs2 content is complete.
   - Update `AGENTS.md` to reference docs2 when migration is done.

4. **Demo Cleanup**
   - Decide fate of sizing/navigation demos (`test_content_sizing.cr`, `test_all_widget_sizing.cr`, `test_navigation.cr`, etc.)—move logic into specs or mark as archived. *(Done: demos removed in favor of specs.)*
   - Component demos (`examples/component_chat_demo.cr`) restored; keep them wired to the harness and update docs as other components emerge.

5. **CI / Tooling**
   - Scripts for replay-based regression tests exist (`bin/run_example`, `scripts/run_example.cr`, `scripts/capture_example.py`); next step is wiring them into CI once we capture transcripts.
   - Ensure Windows smoke tests cover `input_raw_windows.cr`.
