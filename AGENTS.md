# update-git-proj-ver

## 项目简介

通过 `.version` 文件管理 Git 项目版本号，自动更新多语言构建文件的版本号。

## 核心功能

- **ugv**：单一版本号更新工具，支持 Maven/Gradle/Rust/Python/Node.js
- **fastugv**：Git 主/开发分支版本发布自动化

## 依赖

- git
- sed
- fd (fdfind)

## AI guide

### 角色定位

你是百科全书，熟知大量常识; 格式偏好 `markdown`

### 交互规则

1. 处于 AI Coding Plan 包月模式下，Token 不考虑，时间不考虑，专注于高效而完整地工作
2. 所有交互均使用简体中文
3. 每次交互的第一步，都是先检索 skill /memrec，并持续使用 skill /memrec 记忆
4. 每次沟通产出文件后，均执行 git 提交
5. git 仅以当前 `user.name` 提交，不推送到远端
6. git 提交均遵循约定式提交规范（Conventional Commits）执行
7. 编排计划或设计时，如过长(>3000行)，拆分为多份文档
8. 计划或设计中，不要穿插代码，代码不能成为设计或计划的主要内容，仅需要部分伪代码将逻辑讲清楚
9. 重要内容(plan、design等)，随时记录到 MEMORY.md 和 memrec
10. 版本管理忽略 MEMORY.md，写入 .gitignore，不提交到 Git

### Shell 编码规范

#### 基本风格

- 使用 `#!/bin/bash` shebang
- 变量赋值等号两边不加空格
- 使用 `$()` 而非反引号 `` ` `` 执行命令替换
- 使用 `[[ ]]` 而非 `[ ]` 进行条件测试

#### 变量规范

- 变量名使用小写+下划线命名
- 常量使用大写+下划线命名
- 变量引用使用双引号包裹：`"$var"`

#### 错误处理

- 使用 `set -e` 在脚本开头启用错误退出
- 使用 `set -u` 检测未定义变量
- 关键操作检查返回值：`command || exit 1`

#### 函数规范

- 函数名使用小写+下划线命名
- 函数体内的变量使用 `local` 声明
- 函数放在脚本开头，主逻辑放后面

#### 测试与验证

- 使用 `shellcheck` 进行静态检查
- 使用 `bash -n script.sh` 进行语法检查

### 项目特定规则

- 版本号格式：语义化版本 `x.y.z`
- 版本标记注释：`managed by updgitver`
- Git tag 格式：`v{旧版本}_{日期}`
- Git branch 格式：`v{版本}`
