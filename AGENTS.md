# Repository Guidelines

## Project Structure & Module Organization

This is a Zig project built with `build.zig` and configured by `build.zig.zon`.
Application code lives in `src/main.zig`; reusable package-facing code and unit
tests live in `src/root.zig`. Build artifacts are written to `zig-out/`, compiler
cache data to `.zig-cache/`, and fetched dependencies to `zig-pkg/`. Treat those
three directories as generated or vendored output; do not edit them directly.

## Build, Test, and Development Commands

- `zig build` builds the `TestSpacialGrid` executable and installs it under
  `zig-out/bin/`.
- `zig build run` builds and runs the raylib demo window locally.
- `zig build test` runs both module tests from `src/root.zig` and executable
  tests wired through `build.zig`.
- `zig fmt build.zig src/*.zig` formats the build script and source files.
- `zig build --fetch` refreshes declared dependencies from `build.zig.zon` when
  the package cache is missing.

Use Zig `0.16.0` or a compatible dev build matching the minimum version recorded
in `build.zig.zon`.

## Coding Style & Naming Conventions

Follow `zig fmt` output for indentation, spacing, and brace placement. Use
`snake_case` for variables, functions, and constants such as `screen_width` or
`gen_rects` when adding new code. Reserve `PascalCase` for types and imported
module aliases, matching examples like `RectEnt`, `CircleEnt`, and `ZGL`.
Prefer explicit error propagation with `try` and keep allocation ownership clear
with matching `defer ...deinit(...)` calls.

## Testing Guidelines

Put unit tests near the code they exercise using Zig `test "description"` blocks.
Current tests live in `src/root.zig`; add more there for library behavior or in
the relevant source file as modules are split out. Run `zig build test` before
submitting changes. For rendering or raylib behavior, describe any manual checks
performed because the windowed demo is not covered by automated tests.

## Commit & Pull Request Guidelines

The current history is minimal and uses short imperative subjects such as `Test`
and `Finished Test`; prefer clearer imperative messages like `Add collision demo`
or `Fix grid insertion update`. Pull requests should include a short summary,
test results (`zig build test`), and screenshots or screen recordings for visible
raylib changes. Link related issues when available and call out dependency
updates in `build.zig.zon`.

## Agent-Specific Instructions

Keep changes focused on `build.zig`, `build.zig.zon`, and `src/` unless the task
explicitly requires generated output. Do not revert unrelated worktree changes.
