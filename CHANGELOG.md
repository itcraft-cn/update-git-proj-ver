# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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