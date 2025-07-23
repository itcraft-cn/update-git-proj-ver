# update-git-proj-ver

Automatically update git project version numbers by placing a `.version` file.

Supports various language projects including `Maven`/`Gradle`/`Rust Cargo`/`Python setup.py`.

## Installation

```console
sudo cp ugv /usr/local/bin
```

## Usage

Prerequisites:

1. Place a `.version` file in the project root directory with the version number, e.g. `1.0.0`.
2. Mark the version number in files that need to be managed.

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

3. (Optional) The project is managed with `git`.

Usage:

```console
ugv 1.0.1
```

Will execute in the following order:

1. Create a Git tag `1.0.0_yyyymmdd` based on the latest Git `HEAD` and current date.
2. Create a Git branch `v1.0.0` based on the latest Git `HEAD`.
3. Update version numbers in `pom.xml`/`build.gradle`/`Cargo.toml`/`setup.py`.
4. Update version number in `.version` file.
5. Commit and push.

## Dependencies

1. `git`
2. `sed`
3. [fdfind](https://github.com/sharkdp/fd)
