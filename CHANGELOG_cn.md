# 变更日志

本项目的所有重要变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [未发布]

### 新增

- 新增 `CMakeLists.txt` 支持：更新带 `managed by updgitver` 标记的
  `project(... VERSION ...)` 行（仅数字版本，不支持 `-dev` 后缀）
- 新增自包含测试环境（`test/`），覆盖 Maven/npm/Python/Cargo/CMake 的单项目与
  多模块（单向引用）形态，并包含故障注入用例
- 新增 `test/REPORT.md` 记录测试暴露的缺陷
- 单项目 fixture 改为映照 `xlsb-series` 真实编译结构（jxlsb/jsxlsb/rxlsb/cxlsb）

### 修复

- 逐个就地更新 `package.json`，不再把所有内容合并进根文件、也不再凭空创建根文件（数据破坏缺陷）
- 识别失败（`set -eu`）并回滚本次全部文件改动及创建的 tag/branch，随后以非 0 退出

### 已知问题（由测试暴露）

- 多模块依赖引用（Cargo 内联表、Python install_requires）即使带标记也不会更新，
  因为仅匹配少数固定行形式
- package.json 内的 npm 依赖无法打标记（JSON 无注释语法）

## [1.2.0] - 2026-07-07

### 新增

- 新增 Node.js package.json 版本管理支持
- 新增 Python pyproject.toml 版本管理支持
- 新增完整的 AGENTS.md 文档，包含 Shell 编码规范

### 变更

- 完善 README 文档，添加 fastugv 工作流和设计理念说明
- 新增中文 README_cn.md 完整文档

### 修复

- 修复 ugv 中 fd 输出文件计数问题，添加 `wc -l`

### 改进

- ugv 在版本替换前增加文件存在性检查

## [1.1.0] - 2025-08-25

### 新增

- 新增 fastugv 工具，实现主/开发分支版本发布自动化

### 改进

- 增强 ugv 错误处理

## [1.0.0] - 2025-07-23

### 新增

- 初始发布
- ugv 版本更新工具
- 支持 Maven pom.xml
- 支持 Gradle build.gradle
- 支持 Rust Cargo.toml
- 支持 Python setup.py
- Git 集成，自动创建 tag 和分支