# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Add `CMakeLists.txt` support: update `project(... VERSION ...)` on lines marked with
  `managed by updgitver` (numeric versions only; `-dev` suffixes are not supported)
- Add self-contained test environment (`test/`) covering Maven/npm/Python/Cargo/CMake,
  single-project and multi-module (one-way reference) forms, plus failure injection
- Add `test/REPORT.md` documenting the exposed defects
- Single-project fixtures now mirror the real build structures of `xlsb-series`
  (jxlsb/jsxlsb/rxlsb/cxlsb)

### Fixed

- Update each `package.json` in place instead of merging all of them into, and creating,
  a root `package.json` (data-loss bug)
- Detect failures (`set -eu`) and roll back all file changes plus any tag/branch created
  by the run, then exit non-zero
- Update multi-module dependency references: any `managed by updgitver` line (Maven
  `<dependency>`, Cargo inline tables, Python `install_requires`, CMake `project VERSION`)
  plus npm dependencies pointing to in-repo packages

### Known Limitations

- npm dependency values must be exact (no `^`/`~`) and refer to a package in the repository
- `package.json` must keep `version` on line 3 and dependency entries on single lines

## [1.2.0] - 2026-07-07

### Added

- Add Node.js package.json support for version management
- Add Python pyproject.toml support for version management
- Add comprehensive AGENTS.md with Shell coding standards

### Changed

- Improve README documentation with fastugv workflow and design philosophy
- Add Chinese README_cn.md with complete documentation

### Fixed

- Fix file counting issue in ugv by adding `wc -l` to fd output

### Improved

- Add file existence check before version replacement in ugv

## [1.1.0] - 2025-08-25

### Added

- Add fastugv tool for main/dev branch release automation

### Improved

- Enhance ugv with better error handling

## [1.0.0] - 2025-07-23

### Added

- Initial release
- ugv tool for version update
- Support for Maven pom.xml
- Support for Gradle build.gradle
- Support for Rust Cargo.toml
- Support for Python setup.py
- Git integration with automatic tag and branch creation