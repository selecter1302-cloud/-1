#!/usr/bin/env bash
set -euo pipefail
: "${1:?Usage: install_build_tools.sh OUTPUT_TOOL_DIRECTORY}"
mkdir -p "$1"
tool_dir=$(realpath "$1")
if [[ -x "$tool_dir/android-15/apksigner" && -x "$tool_dir/android-15/zipalign" && -x "$tool_dir/android-15/aapt2" ]]; then
    "$tool_dir/android-15/apksigner" version
    exit
fi
stage=$(mktemp -d "$tool_dir/.install.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
curl -fsSL --retry 2 https://dl.google.com/android/repository/build-tools_r35_linux.zip -o "$stage/build-tools.zip"
(cd "$stage" && printf '%s\n' '2cfaa0bbb2336e9ec18ed3ecea84fa2e2af607bc  build-tools.zip' | sha1sum -c)
unzip -q "$stage/build-tools.zip" -d "$stage"
test -x "$stage/android-15/apksigner"
mv -T "$stage/android-15" "$tool_dir/android-15"
"$tool_dir/android-15/apksigner" version
