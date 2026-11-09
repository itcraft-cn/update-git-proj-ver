# update-git-proj-ver

通过放置 `.version` 文件，自动更新 Git 项目版本号。

## 核心功能

- **ugv**：单一版本号更新工具，支持 Maven/Gradle/Rust/Python/Node.js/CMake
- **fastugv**：Git 主/开发分支版本发布自动化

## 安装

```console
sudo cp ugv /usr/local/bin
sudo cp fastugv /usr/local/bin
```

## 依赖

1. `git`
2. `sed`
3. [fdfind](https://github.com/sharkdp/fd)

## 测试

项目内置自包含测试环境，覆盖五类生态（Maven / npm / Python / Cargo / CMake），
每类均含单项目与多模块（带单向引用）形态，并包含故障注入用例：

```console
./test/run-tests.sh
```

每个用例会被复制到临时目录、初始化为 git 仓库、执行 `ugv` 后校验版本更新、依赖引用、
多余文件与失败可还原性。最新结论见 `test/REPORT.md`。

## ugv - 版本更新工具

### 前提

1. 在项目根目录下放置 `.version` 文件，内容为版本号，如 `1.0.0`。
2. 在需要管理的文件中，对版本号进行标识。依赖引用中的版本号（如 Maven `<dependency>`、
   Cargo 依赖条目）若需一并管理，同样必须带上相同标记。npm 的 `package.json` 中，
   依赖名为仓库内部包、且版本值恰为旧版本的条目也会自动更新。

    1. Maven pom.xml

    ```xml
    <version>1.0.0</version> <!-- managed by updgitver -->
    ```

    2. Gradle build.gradle

    ```groovy
    version = '1.0.0' // managed by updgitver
    ```

    3. Rust Cargo.toml

    ```toml
    version = "1.0.0" # managed by updgitver
    ```

    4. Python pyproject.toml

    ```toml
    version = "1.0.0" # managed by updgitver
    ```

    5. Python setup.py

    ```python
    version = "1.0.0", # managed by updgitver
    ```

    6. Node.js package.json

    ```json
    {
      "name": "my-project",
      "version": "1.0.0"
    }
    ```
    注意：package.json 版本号必须在第 3 行。

    7. CMake CMakeLists.txt

    ```cmake
    project(my-project VERSION 1.0.0 LANGUAGES C) # managed by updgitver
    ```
    注意：CMake 不支持 `1.0.0-dev` 这类预发布后缀；开发期可用 `1.0.999` 之类的数字占位，
    发布时再升级到下一个版本号。

3. (可选) 项目基于 `git` 管理。

### 使用

```console
ugv 1.0.1
```

将会按如下顺序执行:

1. 基于当前最新 Git `HEAD` 及当日日期建立 Git tag `v{旧版本}_{yyyymmdd}`。
2. 基于当前最新 Git `HEAD` 建立 Git branch `v{旧版本}`。
3. 更新 `pom.xml`/`build.gradle`/`Cargo.toml`/`pyproject.toml`/`setup.py`/`package.json`/`CMakeLists.txt` 中的版本号。
4. 更新 `.version` 文件中的版本号。
5. 提交变更，提交信息为 `build: change to new version: {新版本}`。

任一步骤失败时，`ugv` 会恢复本次所有被修改的文件、删除本次创建的 Git tag/branch，
并以非 0 退出，不留下部分修改状态。

## fastugv - 分支发布自动化

### 作用

为采用主/开发分支分离的项目自动化版本发布流程，实现分支间的双向同步和版本更新。

### 使用

```console
# 默认：main 和 dev 分支
fastugv <main版本> <dev版本>

# 自定义分支名
fastugv <主分支> <main版本> <开发分支> <dev版本>
```

### 工作流示例

```console
fastugv 1.0.0 1.1.0
```

将会执行：

1. 切换到 `main` 分支
2. 将 `dev` 分支合并到 `main`
3. 在 `main` 分支执行 `ugv 1.0.0`（创建 tag、分支、更新版本号）
4. 切换到 `dev` 分支
5. 将 `main` 分支合并到 `dev`
6. 在 `dev` 分支执行 `ugv 1.1.0`（创建 tag、分支、更新版本号）
7. 切回 `main` 分支

### 适用场景

- 主/开发分支分离的发布流程
- 自动完成版本同步和发布
- 确保发布后两个分支版本号正确

## 设计理念

1. **单一真相源**：`.version` 文件作为版本号的唯一来源
2. **标记即管理**：通过 `managed by updgitver` 注释标记需要管理的版本号
3. **Git 深度集成**：自动创建 tag 和分支保存历史版本
4. **发布工作流**：`fastugv` 实现 main/dev 分支的双向同步和版本发布

## 相关文档

- [English README](README_en.md)
- [变更日志](CHANGELOG.md)
- [使用手册](MANUAL.md)