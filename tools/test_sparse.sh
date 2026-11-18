#!/usr/bin/env bash
set -euo pipefail
: "${1:?Usage: test_sparse.sh FINAL_APK TEST_RUN_DIRECTORY}"
: "${2:?Missing test run directory}"
apk=$(realpath "$1")
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(realpath -m "$2")
mkdir -- "$test_dir"
unzip -q "$apk" 'assets/*' -d "$test_dir"
cd "$test_dir/assets"
export XDG_DATA_HOME="$test_dir/profile"
export XDG_CACHE_HOME="$test_dir/cache"
export XDG_CONFIG_HOME="$test_dir/config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
for pass in main restart; do
    GODOT_SILENCE_ROOT_WARNING=1 timeout 180 godot --headless --main-pack "$PWD/assets.sparsepck" --script "$source_dir/tests/sparse_smoke.gd" -- "$pass" 2>&1 | tee "$test_dir/$pass.log"
    rg '^RESULT [1-9][0-9]* passed, 0 failed$' "$test_dir/$pass.log"
    if rg '^(FAIL |SCRIPT ERROR:|ERROR:)' "$test_dir/$pass.log"; then
        exit 1
    fi
done
