# update-git-proj-ver

通过放置 .version 文件，自动更新 git 项目版本号。

支持 `Maven`/`Gradle`/`Rust Cargo`/`Python setup.py` 等多种语言项目。

## 安装

```console
sudo cp ugv /usr/local/bin
```

## 使用

前提:

1. 在项目根目录下放置 `.version` 文件，内容为版本号，如 `1.0.0`。
2. 在需要管理的文件中，对版本号进行标识。

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

    4. Python setup.py

    ```python
    version = "1.0.0", # managed by updgitver
    ```

3. (可选)项目基于 `git` 管理。

使用:

```console
ugv 1.0.1
```

将会按如下顺序执行:

1. 基于当前最新 Git `HEAD` 及当日日期建立 Git `1.0.0_yyyymmdd` 标签。
2. 基于基于当前最新 Git `HEAD` 建立 Git `v1.0.0` 分支。
3. 更新 `pom.xml`/`build.gradle`/`Cargo.toml`/`setup.py` 中的版本号。
4. 更新 `.version` 文件中的版本号。
5. 提交并推送。

## 依赖

1. `git`
2. `sed`
3. [fdfind](https://github.com/sharkdp/fd)
