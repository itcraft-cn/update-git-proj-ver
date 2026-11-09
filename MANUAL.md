# 使用手册

本手册说明 `ugv` 与 `fastugv` 的完整用法。项目概览见 [README](README.md)，
版本变更见 [变更日志](CHANGELOG.md)。

- English: [MANUAL_en.md](MANUAL_en.md)
- 相关文档：[README](README.md) · [变更日志](CHANGELOG.md)

## 1. 适用场景

适用于需要在多个语言构建文件之间保持同一版本号、并按 Git 主/开发分支发布的仓库。

## 2. 环境要求

| 依赖 | 说明 |
|------|------|
| `git` | 可选；存在 `.git` 时自动创建 tag/branch 并提交 |
| `sed` | 版本替换 |
| `fd` / `fdfind` | 查找构建文件 |

安装：

```console
sudo cp ugv /usr/local/bin
sudo cp fastugv /usr/local/bin
```

## 3. 项目准备

### 3.1 创建 `.version`

在项目根目录创建 `.version`，内容为当前版本号（无换行亦可）：

```console
1.0.0
```

`.version` 是版本号的唯一来源。

### 3.2 标记需要管理的版本行

只有带 `managed by updgitver` 标记的行会被更新。各生态写法：

| 生态 | 文件 | 标记示例 |
|------|------|----------|
| Maven | `pom.xml` | `<version>1.0.0</version> <!-- managed by updgitver -->` |
| Gradle | `build.gradle` | `version = '1.0.0' // managed by updgitver` |
| Rust | `Cargo.toml` | `version = "1.0.0" # managed by updgitver` |
| Python | `pyproject.toml` | `version = "1.0.0" # managed by updgitver` |
| Python | `setup.py` | `version = "1.0.0", # managed by updgitver` |
| Node.js | `package.json` | 无注释；`version` 必须在第 3 行 |
| CMake | `CMakeLists.txt` | `project(app VERSION 1.0.0 LANGUAGES C) # managed by updgitver` |

依赖引用同样按标记处理，例如：

```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>lib-a</artifactId>
    <version>1.0.0</version> <!-- managed by updgitver -->
</dependency>
```

```toml
a = { path = "../a", version = "1.0.0" } # managed by updgitver
```

```python
"demo-a==1.0.0", # managed by updgitver
```

### 3.3 npm 内部依赖

JSON 无注释，因此对 `package.json` 采用语义识别：若依赖名是本仓库内的包，
且版本值恰好等于旧版本，则一并更新。例如：

```json
{
  "name": "@demo/b",
  "version": "1.0.0",
  "dependencies": { "@demo/a": "1.0.0" }
}
```

要求：依赖值为精确版本（不含 `^`/`~`），且依赖条目为单行。

## 4. ugv 用法

```console
ugv <new_version>
```

示例：

```console
ugv 1.0.1
```

执行顺序：

1. 基于当前 HEAD 创建 tag `v{旧版本}_{yyyymmdd}`；
2. 基于当前 HEAD 创建分支 `v{旧版本}`；
3. 按标记更新各构建文件中的版本号（含已标记的依赖引用）；
4. 更新 `.version`；
5. 提交：`build: change to new version: <new_version>`。

### 4.1 失败回滚

脚本以 `set -eu` 运行。任一步骤失败时：

- 恢复本次所有被修改的文件；
- 清除本次暂存；
- 删除本次创建的 tag 与 branch；
- 清理临时文件并以非 0 退出。

因此失败不会留下部分修改。

## 5. fastugv 用法

```console
# 默认 main / dev
fastugv <main_version> <dev_version>

# 自定义分支
fastugv <main_branch> <main_version> <dev_branch> <dev_version>
```

示例：

```console
fastugv 1.0.0 1.1.0
```

流程：

1. 切换到 `main`；
2. 合并 `dev` 到 `main`；
3. 在 `main` 执行 `ugv 1.0.0`；
4. 切换到 `dev`；
5. 合并 `main` 到 `dev`；
6. 在 `dev` 执行 `ugv 1.1.0`；
7. 切回 `main`。

合并失败时脚本会 `git merge --abort` 并以非 0 退出。

## 6. 常见问题

| 现象 | 原因与处理 |
|------|-----------|
| `not a ugv managed project` | 当前目录缺少 `.version` |
| 某个文件未更新 | 该行未带 `managed by updgitver` 标记，或写法不在支持范围内 |
| CMake 不接受 `-dev` | CMake 版本只能用数字；开发期用 `1.0.999` 占位，发布升级为 `1.1.0` |
| `package.json` 未更新 | `version` 不在第 3 行 |
| npm 依赖未更新 | 依赖值不是精确旧版本，或依赖名不属于本仓库 |
| tag 已存在导致失败 | 同日重复执行；确认后删除旧 tag 或换版本号 |
| 失败后已自动回滚 | 查看 stderr 中的 `Rollback completed.`，修复问题后重试 |

## 7. 测试

```console
./test/run-tests.sh
```

覆盖 Maven/npm/Python/Cargo/CMake 的单项目与多模块（单向引用）形态，以及故障注入回滚。
详细结论见 [test/REPORT.md](test/REPORT.md)。
