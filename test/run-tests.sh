#!/bin/bash
#
# ugv 测试运行器
#
# 针对 5 类生态（Maven / npm / Python setup.py / Cargo / CMake）的
# 单项目与多模块（含单向引用）形态，实际执行 ugv 并校验结果。
#
# 用法:
#   ./run-tests.sh            # 运行全部用例
#   WORK_ROOT=/tmp/x ./run-tests.sh
#
set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
ugv_bin=${UGV_BIN:-$repo_root/ugv}
fixtures_dir=$script_dir/fixtures
work_root=${WORK_ROOT:-/tmp/opencode/ugv-tests}
lists_dir=$work_root/.lists

total=0
passed=0
failed=0
case_failed=0
declare -a fail_msgs=()

record_pass() {
    total=$((total + 1))
    passed=$((passed + 1))
    printf '  [PASS] %s\n' "$1"
}

record_fail() {
    total=$((total + 1))
    failed=$((failed + 1))
    case_failed=1
    printf '  [FAIL] %s\n' "$1"
    fail_msgs+=("$current_case: $1")
}

expect_has() { # <file> <substring> <desc>
    local file=$1 needle=$2 desc=$3
    if [[ -f "$file" ]] && grep -qF -- "$needle" "$file"; then
        record_pass "$desc"
    else
        record_fail "$desc (期望包含: $needle, 文件: $file)"
    fi
}

expect_not_has() { # <file> <substring> <desc>
    local file=$1 needle=$2 desc=$3
    if [[ -f "$file" ]] && grep -qF -- "$needle" "$file"; then
        record_fail "$desc (仍包含旧值: $needle, 文件: $file)"
    else
        record_pass "$desc"
    fi
}

expect_no_new_files() { # <new-list-file> <desc>
    local list=$1 desc=$2
    if [[ -s "$list" ]]; then
        record_fail "$desc (新增文件: $(tr '\n' ' ' <"$list"))"
    else
        record_pass "$desc"
    fi
}

run_case() {
    local name=$1 new_ver=$2
    current_case=$name
    case_failed=0

    local work=$work_root/$name
    rm -rf "$work"
    mkdir -p "$work"
    cp -a "$fixtures_dir/$name/." "$work/"

    # 记录执行前的文件清单（排除 .git）
    find "$work" -type f ! -path '*/.git/*' -printf '%P\n' | sort >"$lists_dir/$name.before"

    (
        cd "$work" || exit 1
        git init -q
        git config user.email test@example.com
        git config user.name test
        git add -A
        git commit -qm "init"
    ) || {
        record_fail "git 初始化失败"
        return
    }

    local output rc
    output=$( cd "$work" && "$ugv_bin" "$new_ver" 2>&1 )
    rc=$?

    printf '\n== 用例: %s (目标版本 %s, 退出码 %d) ==\n' "$name" "$new_ver" "$rc"
    printf '%s\n' "$output" | sed 's/^/  | /'

    if [[ $rc -ne 0 ]]; then
        record_fail "ugv 退出码非 0"
    else
        record_pass "ugv 正常退出"
    fi

    # 执行后的文件清单
    find "$work" -type f ! -path '*/.git/*' -printf '%P\n' | sort >"$lists_dir/$name.after"
    comm -13 "$lists_dir/$name.before" "$lists_dir/$name.after" >"$lists_dir/$name.new"
    expect_no_new_files "$lists_dir/$name.new" "不产生多余文件"

    # .version 必须更新
    local dot_ver
    dot_ver=$(cat "$work/.version" 2>/dev/null)
    if [[ "$dot_ver" == "$new_ver" ]]; then
        record_pass ".version 更新为 $new_ver"
    else
        record_fail ".version 未更新 (实际: '$dot_ver', 期望: $new_ver)"
    fi

    case "$name" in
        maven-single)
            expect_has "$work/pom.xml" "<version>$new_ver</version>" "pom.xml 项目版本已更新"
            expect_not_has "$work/pom.xml" "1.0.0" "pom.xml 无旧版本残留"
            ;;
        maven-multi)
            expect_has "$work/pom.xml" "<version>$new_ver</version>" "父 pom 版本已更新"
            expect_has "$work/lib-a/pom.xml" "<version>$new_ver</version>" "lib-a pom 版本已更新"
            expect_has "$work/lib-b/pom.xml" "<version>$new_ver</version>" "lib-b pom 版本已更新"
            expect_not_has "$work/lib-b/pom.xml" "<version>1.0.0</version>" "lib-b 对 lib-a 的依赖版本已更新"
            expect_not_has "$work/pom.xml" "1.0.0" "父 pom 无旧版本残留"
            expect_not_has "$work/lib-a/pom.xml" "1.0.0" "lib-a pom 无旧版本残留"
            expect_not_has "$work/lib-b/pom.xml" "1.0.0" "lib-b pom 无旧版本残留"
            ;;
        node-single)
            expect_has "$work/package.json" "\"version\": \"$new_ver\"" "package.json 版本已更新"
            expect_not_has "$work/package.json" "1.0.0" "package.json 无旧版本残留"
            ;;
        node-subdir)
            expect_has "$work/packages/a/package.json" "\"version\": \"$new_ver\"" "packages/a 版本已更新"
            expect_not_has "$work/packages/a/package.json" "1.0.0" "packages/a 无旧版本残留"
            if [[ -e "$work/package.json" ]]; then
                record_fail "根目录不应凭空出现 package.json"
            else
                record_pass "根目录未凭空出现 package.json"
            fi
            ;;
        node-multi)
            expect_has "$work/package.json" "\"name\": \"demo-root\"" "根 package.json 名称未被破坏"
            expect_has "$work/package.json" "\"version\": \"$new_ver\"" "根 package.json 版本已更新"
            expect_has "$work/packages/a/package.json" "\"version\": \"$new_ver\"" "packages/a 版本已更新"
            expect_has "$work/packages/b/package.json" "\"version\": \"$new_ver\"" "packages/b 版本已更新"
            expect_has "$work/packages/b/package.json" "\"@demo/a\": \"$new_ver\"" "packages/b 对 @demo/a 的依赖版本已更新"
            expect_not_has "$work/package.json" "1.0.0" "根 package.json 无旧版本残留"
            expect_not_has "$work/packages/a/package.json" "1.0.0" "packages/a 无旧版本残留"
            expect_not_has "$work/packages/b/package.json" "1.0.0" "packages/b 无旧版本残留"
            ;;
        python-single)
            expect_has "$work/setup.py" "\"$new_ver\"" "setup.py 版本已更新"
            expect_not_has "$work/setup.py" "1.0.0" "setup.py 无旧版本残留"
            ;;
        python-multi)
            expect_has "$work/pkg-a/setup.py" "\"$new_ver\"" "pkg-a 版本已更新"
            expect_has "$work/pkg-b/setup.py" "\"$new_ver\"" "pkg-b 版本已更新"
            expect_has "$work/pkg-b/setup.py" "demo-a==$new_ver" "pkg-b 对 pkg-a 的依赖版本已更新"
            expect_not_has "$work/pkg-a/setup.py" "1.0.0" "pkg-a 无旧版本残留"
            expect_not_has "$work/pkg-b/setup.py" "1.0.0" "pkg-b 无旧版本残留"
            ;;
        cargo-single)
            expect_has "$work/Cargo.toml" "version = \"$new_ver\"" "Cargo.toml 版本已更新"
            expect_not_has "$work/Cargo.toml" "1.0.0" "Cargo.toml 无旧版本残留"
            ;;
        cargo-multi)
            expect_has "$work/crates/a/Cargo.toml" "version = \"$new_ver\"" "crate a 版本已更新"
            expect_has "$work/crates/b/Cargo.toml" "version = \"$new_ver\"" "crate b 版本已更新"
            expect_has "$work/crates/b/Cargo.toml" "version = \"$new_ver\" }" "crate b 对 a 的依赖版本已更新"
            expect_not_has "$work/crates/a/Cargo.toml" "1.0.0" "crate a 无旧版本残留"
            expect_not_has "$work/crates/b/Cargo.toml" "1.0.0" "crate b 无旧版本残留"
            ;;
        cmake-single)
            expect_has "$work/CMakeLists.txt" "VERSION $new_ver" "单项目 CMakeLists 版本已更新"
            expect_not_has "$work/CMakeLists.txt" "1.0.999" "单项目 CMakeLists 无旧版本残留"
            ;;
        cmake-multi)
            expect_has "$work/CMakeLists.txt" "VERSION $new_ver" "根 CMakeLists 版本已更新"
            expect_has "$work/lib-a/CMakeLists.txt" "VERSION $new_ver" "lib-a CMakeLists 版本已更新"
            expect_has "$work/lib-b/CMakeLists.txt" "VERSION $new_ver" "lib-b CMakeLists 版本已更新"
            expect_not_has "$work/CMakeLists.txt" "1.0.999" "根 CMakeLists 无旧版本残留"
            expect_not_has "$work/lib-a/CMakeLists.txt" "1.0.999" "lib-a CMakeLists 无旧版本残留"
            expect_not_has "$work/lib-b/CMakeLists.txt" "1.0.999" "lib-b CMakeLists 无旧版本残留"
            ;;
        *)
            record_fail "未知用例"
            ;;
    esac

    if [[ $case_failed -eq 0 ]]; then
        printf '  -> 用例通过\n'
    else
        printf '  -> 用例失败\n'
    fi
}

run_failure_rollback_case() {
    current_case=failure-rollback
    case_failed=0

    local work=$work_root/failure-rollback
    rm -rf "$work"
    mkdir -p "$work"
    cp -a "$fixtures_dir/maven-multi/." "$work/"

    (
        cd "$work" || exit 1
        git init -q
        git config user.email test@example.com
        git config user.name test
        git add -A
        git commit -qm "init"
    ) || {
        record_fail "git 初始化失败"
        return
    }

    # 注入故障：lib-b 目录不可写，sed -i 在该目录内创建临时文件将失败
    chmod 555 "$work/lib-b"

    local output rc
    output=$( cd "$work" && "$ugv_bin" 1.1.0 2>&1 )
    rc=$?
    chmod 755 "$work/lib-b"

    printf '\n== 用例: failure-rollback (注入 lib-b 写失败, 退出码 %d) ==\n' "$rc"
    printf '%s\n' "$output" | sed 's/^/  | /'

    local parent_changed=0 liba_changed=0 libb_changed=0 ver_changed=0
    grep -qF '<version>1.1.0</version>' "$work/pom.xml" 2>/dev/null && parent_changed=1
    grep -qF '<version>1.1.0</version>' "$work/lib-a/pom.xml" 2>/dev/null && liba_changed=1
    grep -qF '<version>1.1.0</version>' "$work/lib-b/pom.xml" 2>/dev/null && libb_changed=1
    [[ "$(cat "$work/.version" 2>/dev/null)" == "1.1.0" ]] && ver_changed=1

    local tag_count
    tag_count=$( cd "$work" && git tag -l 'v1.0.0_*' | wc -l )

    if [[ $rc -ne 0 ]]; then
        record_pass "失败通过退出码暴露"
    else
        record_fail "故障被静默吞掉（退出码为 0）"
    fi

    local changed=$((parent_changed + liba_changed + libb_changed + ver_changed))
    if [[ $changed -eq 0 ]]; then
        record_pass "失败后无部分修改（已还原）"
    elif [[ $changed -eq 4 ]]; then
        record_pass "全部更新成功"
    else
        record_fail "存在部分修改且未还原 (父pom=$parent_changed lib-a=$liba_changed lib-b=$libb_changed .version=$ver_changed)"
    fi

    if [[ $tag_count -gt 0 ]]; then
        record_fail "失败后仍残留 Git 标签/分支（标签数: $tag_count）"
    else
        record_pass "失败后未残留 Git 标签/分支"
    fi

    if [[ $case_failed -eq 0 ]]; then
        printf '  -> 用例通过\n'
    else
        printf '  -> 用例失败\n'
    fi
}

main() {
    if [[ ! -x "$ugv_bin" ]]; then
        echo "错误: 找不到可执行的 ugv: $ugv_bin" >&2
        exit 2
    fi

    rm -rf "$work_root"
    mkdir -p "$lists_dir"

    run_case maven-single 1.1.0
    run_case maven-multi 1.1.0
    run_case node-single 1.1.0
    run_case node-multi 1.1.0
    run_case node-subdir 1.1.0
    run_case python-single 1.1.0
    run_case python-multi 1.1.0
    run_case cargo-single 1.1.0
    run_case cargo-multi 1.1.0
    run_case cmake-single 1.1.0
    run_case cmake-multi 1.1.0

    run_failure_rollback_case

    printf '\n================ 汇总 ================\n'
    printf '断言: %d, 通过: %d, 失败: %d\n' "$total" "$passed" "$failed"

    if [[ $failed -gt 0 ]]; then
        printf '\n失败明细:\n'
        local m
        for m in "${fail_msgs[@]}"; do
            printf '  - %s\n' "$m"
        done
        exit 1
    fi
    exit 0
}

main "$@"
