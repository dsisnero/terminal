# Demo & Tooling Status

| Target | Type | Harness Story | Notes / Actions |
|--------|------|---------------|-----------------|
| `examples/getting_started.cr` | Basic widget showcase | Non-interactive; relies on builder layout only | Verify doc references; candidate for README snippet. |
| `examples/ui_builder_demo.cr` | Layout-heavy builder demo | Harness-friendly (builder only) | Ensure README links to it instead of legacy DSL demos. |
| `examples/interactive_builder_demo.cr` | Full `Terminal.run` app | Supports `TERM_DEMO_TEST` and harness controller | See `spec/examples/interactive_builder_demo_spec.cr` for scripted flow. |
| `examples/comprehensive_demo.cr` | Non-interactive walkthrough | Outputs text to STDOUT | Keep as regression sample. |
| `examples/form_demo.cr` | Form widget sample | Non-interactive | Document in widget catalog. |
| `examples/automatic_sizing_test.cr` | Layout sizing verifier | Non-interactive test harness | Consider folding into specs. |
| `examples/test_content_sizing.cr` | Widget sizing regression | Non-interactive | Candidate for removal once specs cover cases. |
| `examples/test_all_widget_sizing.cr` | Exhaustive sizing run | Non-interactive | Same as above. |
| `examples/layout_demo.cr` / `layout_concepts_demo.cr` | Layout debugging | Non-interactive | Keep for docs2/layout reference. |
| `examples/simple_table_test.cr` | Table widget sample | Non-interactive | Use in docs2. |
| `examples/test_navigation.cr` | Focus/navigation smoke | Interactive; no harness | Needs update or removal. |
| `examples/smoke_test.cr` | Quick runtime validation | Interactive | Decide whether to keep now that specs cover pipeline. |
| `bin/run_example` + `examples/README.md` | Example launcher & doc | Works but references old demos | Update README once docs2 replacements ready. |

**Missing:** Component-based demos (chat, etc.) were on the `better_api` branch but are not present on `audit`. Decide whether to bring them across or keep audit focused on the existing builder demos.
