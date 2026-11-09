# Manual

This manual documents `ugv` and `fastugv`. See [README](README_en.md) for the project overview
and [Changelog](CHANGELOG_en.md) for version history.

- 中文: [MANUAL.md](MANUAL.md)
- Related documents: [README](README_en.md) · [Changelog](CHANGELOG_en.md)

## 1. Scope

For repositories that keep a single version number across multiple language build files and
release along Git main/dev branches.

## 2. Requirements

| Dependency | Purpose |
|------------|---------|
| `git` | Optional; when `.git` exists, tags/branches are created and changes committed |
| `sed` | Version replacement |
| `fd` / `fdfind` | Locate build files |

Install:

```console
sudo cp ugv /usr/local/bin
sudo cp fastugv /usr/local/bin
```

## 3. Project Setup

### 3.1 Create `.version`

Place `.version` in the project root with the current version (a trailing newline is optional):

```console
1.0.0
```

`.version` is the single source of truth.

### 3.2 Mark managed version lines

Only lines carrying the `managed by updgitver` marker are updated:

| Ecosystem | File | Marker example |
|-----------|------|----------------|
| Maven | `pom.xml` | `<version>1.0.0</version> <!-- managed by updgitver -->` |
| Gradle | `build.gradle` | `version = '1.0.0' // managed by updgitver` |
| Rust | `Cargo.toml` | `version = "1.0.0" # managed by updgitver` |
| Python | `pyproject.toml` | `version = "1.0.0" # managed by updgitver` |
| Python | `setup.py` | `version = "1.0.0", # managed by updgitver` |
| Node.js | `package.json` | No comments; `version` must be on line 3 |
| CMake | `CMakeLists.txt` | `project(app VERSION 1.0.0 LANGUAGES C) # managed by updgitver` |

Dependency references follow the same marker rule, for example:

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

### 3.3 npm internal dependencies

JSON has no comments, so `package.json` uses semantic detection: a dependency whose name is a
package in this repository and whose value is exactly the old version is updated too. Example:

```json
{
  "name": "@demo/b",
  "version": "1.0.0",
  "dependencies": { "@demo/a": "1.0.0" }
}
```

Requirements: exact version value (no `^`/`~`) and single-line dependency entries.

## 4. ugv Usage

```console
ugv <new_version>
```

Example:

```console
ugv 1.0.1
```

Order of operations:

1. Create tag `v{old_version}_{yyyymmdd}` at HEAD;
2. Create branch `v{old_version}` at HEAD;
3. Update versions in build files (including marked dependency references);
4. Update `.version`;
5. Commit: `build: change to new version: <new_version>`.

### 4.1 Rollback on failure

The script runs with `set -eu`. If any step fails it:

- restores every modified file;
- clears the index entries it staged;
- deletes the tag and branch created in this run;
- removes temporary files and exits non-zero.

No partial state is left behind.

## 5. fastugv Usage

```console
# Default main / dev
fastugv <main_version> <dev_version>

# Custom branches
fastugv <main_branch> <main_version> <dev_branch> <dev_version>
```

Example:

```console
fastugv 1.0.0 1.1.0
```

Flow:

1. Checkout `main`;
2. Merge `dev` into `main`;
3. Run `ugv 1.0.0` on `main`;
4. Checkout `dev`;
5. Merge `main` into `dev`;
6. Run `ugv 1.1.0` on `dev`;
7. Checkout `main`.

On merge failure it runs `git merge --abort` and exits non-zero.

## 6. Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `not a ugv managed project` | Missing `.version` in the current directory |
| A file is not updated | The line lacks the `managed by updgitver` marker or uses an unsupported form |
| CMake rejects `-dev` | CMake accepts numeric versions only; use `1.0.999` during development and upgrade to `1.1.0` |
| `package.json` not updated | `version` is not on line 3 |
| npm dependency not updated | Value is not the exact old version, or the name is not an in-repo package |
| Fails because the tag exists | Re-running on the same day; delete the old tag or use a new version |
| Automatic rollback happened | Check stderr for `Rollback completed.`, fix the cause and retry |

## 7. Testing

```console
./test/run-tests.sh
```

Covers single-project and multi-module (one-way reference) forms for Maven/npm/Python/Cargo/CMake,
plus failure-injection rollback. See [test/REPORT.md](test/REPORT.md) for details.
