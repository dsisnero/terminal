# Source ↔ Spec Inventory

> Last updated: 2025-11-08 (audit branch)

## Legend
- ✅ = covered / confirmed current
- ⚠️ = partial coverage or TODO
- 🗑️ = candidate for removal / archival

| Source File | Purpose | Spec Coverage | Notes / Actions |
|-------------|---------|---------------|-----------------|
| `application_dsl.cr` | Legacy DSL helpers that wrap `Terminal.app` | `spec/application_dsl_spec.cr` ✅ | Still referenced by older demos; keep but document deprecation once builder docs land. |
| `basic_widget.cr` | Minimal widget implementation used in low-level examples | `spec/widget_render_spec.cr` ✅ | Covered indirectly via helper specs. |
| `block.cr` | Legacy concurrent block runner (unused in builder/component pipelines) | None ⚠️ | Verify callers; currently appears unused → mark for removal or document rationale. |
| `cell.cr` | Represents styled terminal cells | `spec/cell_spec.cr` ✅ | Good coverage. |
| `color_dsl.cr` | Inline color helpers for widgets | `spec/widget_helpers_spec.cr` ✅ | N/A. |
| `container.cr` | Legacy DI container | `spec/container_spec.cr` ⚠️ (failing) | Spec currently broken; audit should decide whether to retire in favor of `container_new.cr`. |
| `container_new.cr` | Replacement DI container | `spec/dependency_test_classes*_spec.cr` ✅ | Consider renaming to `container_v2.cr` after audit. |
| `cursor_manager.cr` | Cursor hide/show/move logic | `spec/cursor_manager_spec.cr` ✅ | Add integration mention in runtime doc. |
| `diff_renderer.cr` | Applies `ScreenDiff` to IO | `spec/diff_renderer_spec.cr` ✅ | Instrumented for harness logging. |
| `dispatcher.cr` | Routes messages to widgets/render pipeline | `spec/widget_event_routing_spec.cr`, `spec/ui_builder_integration_spec.cr` ✅ | Document focus/global key flow in runtime doc. |
| `dropdown_widget.cr` | Dropdown widget implementation | `spec/dropdown_widget_spec.cr` ✅ | None. |
| `dsl_convenience.cr` | Shortcuts on builder DSL | `spec/dsl_convenience_spec.cr` ✅ | Good. |
| `editable_text.cr` | Shared text editing helper | `spec/editable_text_spec.cr` ✅ | None. |
| `event_loop.cr` | Manages subsystem fibers/tickers | `spec/run_spec.cr`, `spec/interactive_streaming_ui_spec.cr` ⚠️ | Coverage via integration only; consider targeted unit spec. |
| `form_widget.cr` | Multi-field form widget | `spec/form_widget_spec.cr` ✅ | None. |
| `geometry.cr` | Layout geometry helpers | `spec/geometry_spec.cr` ✅ | None. |
| `input_provider.cr` | Abstract input provider + dummy/raw wiring | `spec/dummy_input_provider_spec.cr`, `spec/windows_key_map_spec.cr` ✅ | None. |
| `input_raw_unix.cr` | Unix raw input provider | Integration only ⚠️ | Hard to unit test; document manual coverage. |
| `input_raw_windows.cr` | Windows VT input provider | `spec/windows_key_map_spec.cr` (partial) ⚠️ | Rely on Windows CI smoke tests (TODO). |
| `input_widget.cr` | Single-line input widget | `spec/input_widget_spec.cr` ✅ | None. |
| `interactive_streaming_ui.cr` | Legacy streaming demo wiring | `spec/interactive_streaming_ui_spec.cr` ✅ | Confirm still needed after audit. |
| `messages.cr` | Message definitions | `spec/widget_event_routing_spec.cr` (indirect) ⚠️ | Consider direct message spec or doc topic instead. |
| `prelude.cr` | Convenience require aggregator | Covered implicitly ✅ | No standalone spec required. |
| `prompts.cr` | CLI prompt helpers | `spec/prompts_spec.cr` ✅ | None. |
| `run.cr` | `Terminal.run` lifecycle helper | `spec/run_spec.cr` ✅ | None. |
| `runtime_harness.cr` | Harness controller | `spec/runtime_helper_spec.cr` ✅ | Update docs2/runtime flow with harness usage. |
| `screen_buffer.cr` | Maintains active screen grid | `spec/screen_buffer_spec.cr` ✅ | New harness logs exist. |
| `service_provider.cr` | DI service provider wiring | `spec/dependency_test_classes*_spec.cr` ✅ | None. |
| `spinner_widget.cr` | Spinner widget | `spec/spinner_widget_spec.cr` ✅ | None. |
| `stop_handler.cr` | Signal handling glue | Covered via `spec/run_spec.cr` ⚠️ | Document behavior. |
| `table_widget.cr` | Table widget | `spec/table_widget_spec.cr` ✅ | None. |
| `terminal_application.cr` | Core app orchestrator | `spec/terminal_application_spec.cr` ✅ | None. |
| `text_box_widget.cr` | Multi-line text widget | `spec/text_box_widget_spec.cr` ✅ | None. |
| `tty.cr` | TTY helper utilities | Implicit via prompts/input ⚠️ | Add doc describing responsibilities; consider spec. |
| `ui_builder.cr` | Builder DSL implementation | `spec/ui_builder_spec.cr`, `spec/ui_builder_integration_spec.cr` ✅ | Document interplay with runtime harness. |
| `ui_layout.cr` | Constraint-based layout engine | `spec/ui_builder_spec.cr`, `spec/geometry_spec.cr` ✅ | None. |
| `timed_wait_group.cr` | WaitGroup wrapper adding timeout support | ⚠️ | Thin layer over stdlib `WaitGroup`; currently exercised indirectly via `EventLoop` integration specs. |
| `widget.cr` | Widget base module | `spec/widget_helpers_spec.cr` ✅ | None. |
| `widget_manager.cr` | Focus + render orchestration | `spec/widget_manager_spec.cr`, `spec/widget_render_spec.cr` ✅ | None. |
| `windows_key_map.cr` | Windows key translation | `spec/windows_key_map_spec.cr` ✅ | None. |

### Spec-Only Files (no matching source)
- `spec/enhanced_dsl_integration_spec.cr` – Covers deprecated DSL demo; decide whether to keep or migrate.
- `spec/dependency_test_classes_spec.cr` / `_fixed` – Fixture specs purely for DI container validation; keep as long as both containers exist.

### Source Files Without Specs
- `block.cr`
- `timed_wait_group.cr`
- Platform-specific raw input files (documented manually)

📝 Action: confirm usage of the above and either add specs or remove files.
