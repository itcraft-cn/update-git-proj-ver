# ugv 测试报告

## 1. 测试环境

- 工具：本地仓库 `ugv`（未做任何修复，直接被测）
- 时间：2026-11-09
- 平台：Linux / bash 5.2 / fd / git
- 运行入口：`test/run-tests.sh`
- 工作目录：`/tmp/opencode/ugv-tests`（可用 `WORK_ROOT` 覆盖）
- 断言总数：80，通过 55，失败 25

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

脚本会对每个用例：复制 fixture 到临时目录 → `git init` 建立基线 → 执行 `ugv 1.1.0` →
校验版本号、依赖引用、是否产生多余文件、失败时是否可还原。任一断言失败则整体退出码为 1。

## 2. 通过情况

以下用例完全通过：

- `maven-single`、`maven-multi`
- `node-single`
- `python-single`
- `cargo-single`

体现的正确行为：带 `managed by updgitver` 标记的**文件自身版本行**可以被正确更新；
Maven 多模块中同时打了标记的 `<dependency>` 版本也能被更新。

## 3. 暴露的问题

### 问题 1：package.json 被合并、并凭空生成根 package.json（严重，数据破坏）

- 现象 A（`node-multi`）：执行后根 `package.json` 被覆盖为「所有 package.json 内容的拼接」，
  且只有全局第 3 行（第一个文件的 version）被替换；子目录 `packages/a`、`packages/b`
  的 `package.json` 完全没有改动。原根文件内容被破坏。
- 现象 B（`node-subdir`）：根目录本来没有 `package.json`，执行后**凭空多出**一个根
  `package.json`（内容是子目录文件），子目录文件仍未更新。
- 根因：`fd ... -X awk ... {} > tmp.json && mv tmp.json package.json` 中的重定向作用在
  当前目录、且 `awk` 用 `NR==3` 只命中整个输入流的第 3 行，`mv` 又固定写回根 `package.json`。
  该写法只能正确处理「根目录恰好有一个 package.json」的情况。
- 影响：多模块 / 子目录项目中会**破坏文件并丢失版本信息**，属于数据破坏级缺陷。
- 关联已知问题：1。

### 问题 2：出错时无法无痛还原，且失败被静默吞掉（严重）

- 用例 `failure-rollback`：对 `lib-b` 目录注入写失败（`chmod 555`），`sed` 报
  `Permission denied`。
- 实际结果：
  - `ugv` 退出码仍为 **0**；
  - 父 pom 与 `.version` 未按预期更新、`lib-a` 已更新、`lib-b` 未更新，形成**部分修改**；
  - Git 标签 `v1.0.0_<日期>` 与分支仍然残留；
  - 最后还执行了 `git commit -a`，把部分修改提交入库。
- 根因：脚本未启用 `set -e` / 未检查各步骤返回值，没有 `trap` 回滚；
  标签/分支在文件修改之前创建，失败后不会清理。
- 影响：失败现场被掩盖，仓库进入不一致状态且难以察觉。
- 关联已知问题：2。

### 问题 3：不支持 CMake（功能缺失）

- `cmake-single` / `cmake-multi` 中 `project(... VERSION ...)` 完全没有被更新。
- 根因：`ugv` 没有处理 `CMakeLists.txt` 的分支。
- 影响：CMake 项目无法纳入统一版本管理；叠加「CMake 不支持 `x.y.z-dev`」的既有约束，
  用户只能手工维护 `x.y.999 → x.y+1.0` 的升级。
- 关联已知问题：3。

### 问题 4：多模块单向引用依赖未更新（功能缺陷）

只在「依赖版本行本身也打了标记」时才会更新，常见真实写法不会被处理：

- `cargo-multi`：`a = { path = "../a", version = "1.0.0" }`（内联表）未更新。
  当前 sed 只匹配整行形如 `version = "x" # managed by updgitver` 的形式。
- `python-multi`：`install_requires=["demo-a==1.0.0"]` 未更新。
  当前 sed 只匹配 `version="x", # managed...` 形式。
- `node-multi`：`"@demo/a": "1.0.0"` 依赖未更新（连同问题 1 一起失效）。
- Maven 之所以通过，是因为 fixture 在 `<dependency>` 的 `<version>` 行显式加了标记；
  真实项目通常不会给每个依赖版本行加标记，因此同样存在漏更新风险。
- 根因：替换逻辑基于「整行末端标记」的正则，覆盖面窄，无法表达结构化依赖引用。
- 关联已知问题：4。

## 4. 结论

- 单项目、且版本行带标记的场景可用。
- 多模块与非根 `package.json` 场景存在**数据破坏**和**漏更新**，不可直接用于生产。
- 失败不具备事务性：无回滚、退出码不可信。
- CMake 尚未支持。

建议后续修复方向（不在本次变更范围）：

1. 用结构化方式处理 JSON（如 `jq`）逐文件就地更新，禁止跨目录合并与凭空建文件；
2. 所有外部命令检查返回码，脚本开头 `set -euo pipefail`，并用 `trap` 在失败时回滚
   （撤销标签/分支/文件改动）；
3. 增加 CMakeLists.txt 的 `project(... VERSION ...)` 支持；
4. 依赖引用改为按生态的语义匹配（Cargo 内联表、Python install_requires、npm dependencies、
   Maven dependency 版本），而非整行末端标记。
