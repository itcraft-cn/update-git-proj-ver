# update-git-proj-ver

Automatically update git project version numbers by placing a `.version` file.

## Core Features

- **ugv**: Single version update tool, supports Maven/Gradle/Rust/Python/Node.js
- **fastugv**: Git main/dev branch version release automation

## Installation

```console
sudo cp ugv /usr/local/bin
sudo cp fastugv /usr/local/bin
```

## Dependencies

1. `git`
2. `sed`
3. [fdfind](https://github.com/sharkdp/fd)

## ugv - Version Update Tool

### Prerequisites

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
    Note: package.json version must be on line 3.

3. (Optional) The project is managed with `git`.

### Usage

```console
ugv 1.0.1
```

Will execute in the following order:

1. Create a Git tag `v{old_version}_{yyyymmdd}` based on the latest Git `HEAD` and current date.
2. Create a Git branch `v{old_version}` based on the latest Git `HEAD`.
3. Update version numbers in `pom.xml`/`build.gradle`/`Cargo.toml`/`pyproject.toml`/`setup.py`/`package.json`.
4. Update version number in `.version` file.
5. Commit changes with message `build: change to new version: {new_version}`.

## fastugv - Branch Release Automation

### Purpose

Automate version release workflow for projects with main/dev branch separation. Handles bidirectional sync between branches and version updates.

### Usage

```console
# Default: main and dev branches
fastugv <main_version> <dev_version>

# Custom branch names
fastugv <main_branch> <main_version> <dev_branch> <dev_version>
```

### Workflow Example

```console
fastugv 1.0.0 1.1.0
```

Will execute:

1. Checkout `main` branch
2. Merge `dev` into `main`
3. Run `ugv 1.0.0` on `main` (create tag, branch, update version)
4. Checkout `dev` branch
5. Merge `main` into `dev`
6. Run `ugv 1.1.0` on `dev` (create tag, branch, update version)
7. Checkout `main` branch

### Use Cases

- Release workflow with main/dev branch separation
- Automatic version synchronization between branches
- Ensures both branches have correct version numbers after release

## Design Philosophy

1. **Single Source of Truth**: `.version` file is the unique source of version number
2. **Marker-based Management**: Version numbers are managed via `managed by updgitver` comments
3. **Git Integration**: Automatically create tags and branches to preserve version history
4. **Release Workflow**: `fastugv` enables bidirectional sync and version release for main/dev branches