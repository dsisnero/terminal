# Audit Action Items

1. **Legacy / Unused Files**
   - `src/terminal/block.cr` – used only in examples; consider moving under `examples/` or documenting status.

2. **Spec Gaps**
   - Platform raw input (`input_raw_unix.cr`, `input_raw_windows.cr`) rely on manual coverage; add smoke tests or doc disclaimers.
   - `messages.cr` lacks dedicated tests; consider lightweight serialization/unit coverage or document rationale.
   - `stop_handler.cr` + `tty.cr` only covered via integration; evaluate need for direct specs.

3. **Docs Refresh**
   - Replace legacy `README.md` sections referencing deprecated demos with pointers to the builder/component model once docs2 content is complete.
   - Update `AGENTS.md` to reference docs2 when migration is done.

4. **Demo Cleanup**
   - Decide fate of sizing/navigation demos (`test_content_sizing.cr`, `test_all_widget_sizing.cr`, `test_navigation.cr`, etc.)—move logic into specs or mark as archived.
   - Reintroduce component demos (chat, etc.) onto `audit` branch or document why they remain on feature branches.

5. **CI / Tooling**
   - Add scripts for replay-based regression tests (TypescriptReplay) once capture files exist.
   - Ensure Windows smoke tests cover `input_raw_windows.cr`.
