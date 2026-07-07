# 变更日志

本项目的所有重要变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

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