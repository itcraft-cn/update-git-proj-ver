# ugv 测试报告

## 1. 测试环境

- 工具：本地仓库 `ugv`（已修复问题 1：package.json 处理）
- 时间：2026-11-09
- 平台：Linux / bash 5.2 / fd / git
- 运行入口：`test/run-tests.sh`
- 工作目录：`/tmp/opencode/ugv-tests`（可用 `WORK_ROOT` 覆盖）
- 断言总数：81，通过 81，失败 0

### 样本来源

单项目 fixture 直接取自真实仓库 `xlsb-series` 的编译结构（提取到
`/tmp/opencode/xlsb-samples` 作为样本后映照到测试名）：

| 测试名 | 来源子项目 | 语言 | 真实版本 |
|--------|-----------|------|----------|
| `maven-single` | jxlsb | Java | `1.3.0-dev` |
| `node-single` | jsxlsb | TypeScript | `1.2.0-dev` |
| `cargo-single` | rxlsb | Rust | `0.5.0-dev` |
| `cmake-single` | cxlsb | ANSI C | `0.2.999` |

多模块用例仍为通用构造，覆盖单向引用。`xlsb-series` 原始仓库未被修改。

### 标记规约

所有需要管理的版本引用行均按规约带有 `managed by updgitver` 标记，
包括跨模块依赖的版本行（Maven `<dependency>`、Cargo 内联表行末、Python `install_requires`）。
JSON 无注释语法，`package.json` 仅按「第 3 行 version」约定管理。

### 用例矩阵

每个生态均覆盖「单项目」与「多模块（含单向引用）」两种形态：

| 生态 | 单项目用例 | 多模块用例 | 单向引用 |
|------|-----------|-----------|----------|
| Maven | `maven-single` | `maven-multi` | `lib-b` 依赖 `lib-a` |
| npm | `node-single` | `node-multi` | `packages/b` 依赖 `packages/a` |
| Python | `python-single` | `python-multi` | `pkg-b` 依赖 `pkg-a` |
| Cargo | `cargo-single` | `cargo-multi` | `crates/b` 依赖 `crates/a` |
| CMake | `cmake-single` | `cmake-multi` | `lib-b` 链接 `lib-a` |
| 补充 | `node-subdir`（子目录含 package.json、根目录无） | `failure-rollback`（故障注入） | - |

### 运行方式

```bash
./test/run-tests.sh
```

脚本会对每个用例：复制 fixture 到临时目录 → `git init` 建立基线 → 执行 `ugv <目标版本>` →
校验版本号、依赖引用、是否产生多余文件、失败时是否可还原。任一断言失败则整体退出码为 1。
目标版本按用例配置（单项目沿用真实版本线，多模块用 `1.0.0 → 1.1.0`）。

## 2. 通过情况

以下用例完全通过：

- `maven-single`、`maven-multi`（真实 jxlsb pom）
- `node-single`（真实 jsxlsb package.json）
- `node-subdir`（修复问题 1 后通过）
- `python-single`
- `cargo-single`（真实 rxlsb Cargo.toml）
- `cmake-single`、`cmake-multi`（支持 CMake 后通过；真实 cxlsb `0.2.999`）
- `failure-rollback`（失败可识别、可回滚）

体现的正确行为：带 `managed by updgitver` 标记的**文件自身版本行**可以被正确更新；
每个 `package.json` 独立就地更新，不再合并或凭空生成根文件；
Maven 多模块中同时打了标记的 `<dependency>` 版本也能被更新。

## 3. 暴露的问题

### 问题 1：package.json 被合并、并凭空生成根 package.json（已修复）

- 原现象 A（`node-multi`）：根 `package.json` 被覆盖为「所有 package.json 内容的拼接」，
  且只有全局第 3 行被替换；子目录文件没有改动。
- 原现象 B（`node-subdir`）：根目录本来没有 `package.json`，执行后凭空多出一个。
- 原根因：`fd ... -X awk ... {} > tmp.json && mv tmp.json package.json` 的重定向作用在
  当前目录、`awk` 的 `NR==3` 命中整个输入流而非单文件、`mv` 固定写回根文件。
- 修复方式：改为对 `fd` 列出的每个 `package.json` 逐个就地处理
  （`while read` + `awk -v old -v new 'NR==3 && /"version"/ {sub(old,new)}'` 写临时文件再 `mv`），
  不再跨目录合并，也不会创建原本不存在的文件。
- 验证结果：`node-subdir` 全部通过；`node-multi` 中根与各子包的 version 行均正确更新
  （仅剩依赖引用未更新，见问题 4）。
- 关联已知问题：1。

### 问题 2：出错时无法无痛还原，且失败被静默吞掉（已修复）

- 原现象（`failure-rollback`）：对 `lib-b` 目录注入写失败（`chmod 555`）后，
  `ugv` 退出码仍为 0，出现部分修改，Git 标签/分支残留，并提交了部分修改。
- 原根因：未启用 `set -e`、未检查各步骤返回值，没有 `trap` 回滚；
  标签/分支先于文件修改创建，失败后不清理。
- 修复方式：
  - 脚本改为 `set -eu`，任一命令失败即中止；
  - 修改前把 `.version` 与所有待改文件备份到临时目录；
  - `trap on_exit EXIT`：失败时恢复全部备份文件、删除本次创建的 tag 与 branch、
    清理临时目录，并以非 0 退出；成功才跳过回滚。
- 验证结果：`failure-rollback` 四项断言全部通过——失败通过退出码暴露（sed 返回 4）、
  无部分修改、无标签/分支残留、工作区干净（无残留改动或暂存）。
- 关联已知问题：2。

### 问题 3：不支持 CMake（已修复）

- 原现象：`cmake-single` / `cmake-multi` 中 `project(... VERSION ...)` 完全没有被更新。
- 原根因：`ugv` 没有处理 `CMakeLists.txt` 的分支。
- 修复方式：新增 CMake 分支，对带 `# managed by updgitver` 标记的行执行
  `s/VERSION <old>/VERSION <new>/`，逐文件就地更新。
- 验证结果：`cmake-single`（真实 cxlsb `0.2.999 → 0.3.0`）与 `cmake-multi` 全部通过；
  真实 cxlsb 副本实测 `.version` 与 `CMakeLists.txt` 同步更新。
- 已知限制：CMake 不支持 `-dev` 后缀，开发期请使用 `x.y.999` 数字占位。
- 关联已知问题：3。

### 问题 4：多模块单向引用依赖未更新（已修复）

本测试已严格遵循规约：所有需要管理的版本引用行都带有 `managed by updgitver` 标记
（Maven `<dependency>` 的 `<version>`、Cargo 内联表行末、Python `install_requires` 行末）。
修复前的问题：

- `cargo-multi`：`a = { path = "../a", version = "1.0.0" } # managed by updgitver` 未更新。
- `python-multi`：`"demo-a==1.0.0", # managed by updgitver` 未更新。
- `node-multi`：`"@demo/a": "1.0.0"` 依赖未更新（JSON 无注释，无法打标记）。

修复方式：

- 文本类构建文件统一改为「按标记行做版本替换」：
  `sed -i "/managed by updgitver/ s/<old>/<new>/g"`，
  不再依赖某一固定行写法，因此可覆盖 Maven dependency、Cargo 内联表、
  Python install_requires、CMake project VERSION 等。
- `package.json`：收集仓库内所有包名，识别 workspace 内部依赖；
  对「依赖名属于本仓库包」且「版本值恰好等于旧版本」的条目一并替换，
  同时仍更新第 3 行 `version`。
- 已知限制：npm 依赖必须是精确版本（如 `1.0.0`，不含 `^`/`~`），且依赖名需为仓库内的包名。

验证结果：`cargo-multi`、`python-multi`、`node-multi` 全部通过；
Cargo 内联表、`install_requires`、npm workspace 依赖均正确更新。
- 关联已知问题：4。

## 4. 结论

- 单项目、且版本行带标记的场景可用（含 jxlsb/jsxlsb/rxlsb/cxlsb 的真实结构）。
- package.json 合并/凭空生成问题已修复；多模块 `package.json` 逐文件更新正确。
- CMake `project(... VERSION ...)` 已支持，`x.y.999 → x.y+1.0` 的升级路径可自动化。
- 失败可识别并可回滚：退出码非 0，文件、标签、分支均恢复。
- 多模块依赖引用已覆盖：Cargo 内联表、Python install_requires、npm workspace 依赖均可更新。
- 全部 81 项断言通过。

建议后续增强（非缺陷，属于覆盖面扩展）：

1. npm 依赖若使用 `^`/`~` 范围或非仓库内部包，目前不处理；
2. `package.json` 仍按「第 3 行 version」与单行依赖条目解析，不支持压缩成一行的 JSON。
