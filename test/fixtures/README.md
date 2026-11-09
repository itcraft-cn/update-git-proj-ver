# 测试 fixture

## 命名

目录名即测试用例名，由 `test/run-tests.sh` 按名调用。

## 单项目（映照真实项目）

取自 `xlsb-series` 的真实编译结构（样本提取于 `/tmp/opencode/xlsb-samples`）：

| fixture | 来源 | 语言 | 初始版本 |
|---------|------|------|----------|
| `maven-single` | jxlsb | Java / Maven | `1.3.0-dev` |
| `node-single` | jsxlsb | TypeScript / npm | `1.2.0-dev` |
| `cargo-single` | rxlsb | Rust / Cargo | `0.5.0-dev` |
| `cmake-single` | cxlsb | ANSI C / CMake | `0.2.999` |

`xlsb-series` 原始仓库未被修改。

## 多模块（构造）

用于覆盖跨模块单向引用：

| fixture | 单向引用 |
|---------|----------|
| `maven-multi` | `lib-b` 依赖 `lib-a` |
| `node-multi` | `packages/b` 依赖 `packages/a` |
| `python-multi` | `pkg-b` 依赖 `pkg-a` |
| `cargo-multi` | `crates/b` 依赖 `crates/a` |
| `cmake-multi` | `lib-b` 链接 `lib-a` |

## 补充

- `node-subdir`：子目录含 `package.json`、根目录无，用于验证不凭空生成根文件。
- `failure-rollback`：不单独建目录，运行器复制 `maven-multi` 后注入写失败。

## 标记规约

需要管理的版本行均带 `managed by updgitver` 标记；依赖引用中的版本行同样带标记。
JSON 无注释语法，`package.json` 仅按「第 3 行 version」约定管理。
