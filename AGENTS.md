# AGENTS.md - AI Coding Assistant Guide

## Agent Behavior

When working on this codebase:

- **Always update plan.md** when completing phases or major features
- **Mark items complete** in plan.md using `[x]` when done
- **Update completion docs** when finishing phases (create PHASE_X_COMPLETION.md files)
- **Run tests** after changes: `./run_tests.sh` (recommended) or `crystal spec --tag ~interactive`
- **Check build** after changes: `crystal build src/cli.cr`
- **Track progress** using plan.md as the source of truth

## Commands

- **Test all**: `./run_tests.sh` (recommended) or `crystal spec --tag ~interactive`
- **Test single file**: `crystal spec spec/path/to/file_spec.cr`
- **Build**: `shards build` or `make build`
- **Build release**: `shards build --release`
- **Install dependencies**: `shards install` or `make install`
- **Run**: `./bin/clarity`
- **Setup config**: `./bin/clarity config generate`
- **Format code**: `crystal tool format`

### Language & Version

- **Language**: Crystal (>= 1.17.1)
- **Project Name**: Term

## Code Style

- **Formatting**: 2-space indent, LF line endings, UTF-8, trailing newline (see `.editorconfig`)
- **Naming**: `snake_case` for methods/variables, `PascalCase` for classes/modules
- **Types**: Explicit type annotations for method parameters and return types
- **Logging**: Use `Log.debug`, `Log.info` for diagnostic output
- **Require order**: External dependencies first, then internal requires in alphabetical order

### Test Conventions

- Use descriptive `describe` and `it` blocks
- Setup/teardown for file fixtures

Log.debug {}
Log.info {}
```

## Troubleshooting


## Recent Major Accomplishments
