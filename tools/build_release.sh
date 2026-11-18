#!/usr/bin/env bash
set -euo pipefail
umask 077
if [[ $# != 5 ]]; then
    echo 'Usage: build_release.sh BASE_APK BUILD_TOOLS_DIR KEYSTORE PASSWORD_FILE OUTPUT_APK' >&2
    exit 2
fi
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
base=$(realpath "$1")
tools=$(realpath "$2")
key=$(realpath "$3")
password_file=$(realpath "$4")
output=$(realpath -m "$5")
if [[ -e "$output" ]]; then
    echo "Output already exists: $output" >&2
    exit 2
fi
stage=$(mktemp -d "$(dirname "$output")/.narana-build.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
expected='52a1b6f90047314502c2160124f655c7add4d3aa8d7ecb05152b710d56434297'
base_certificate=$("$tools/apksigner" verify --print-certs "$base" | awk '/Signer #1 certificate SHA-256 digest:/ {print $NF}')
key_certificate=$(keytool -exportcert -keystore "$key" -alias gensokyomod -storepass:file "$password_file" | sha256sum | cut -d ' ' -f 1)
test "$base_certificate" = "$expected"
test "$key_certificate" = "$expected"
python3 "$source_dir/tools/package.py" build "$base" "$source_dir" "$stage/unsigned.apk"
"$tools/zipalign" -P 16 -f 4 "$stage/unsigned.apk" "$stage/aligned.apk"
"$tools/apksigner" sign --ks "$key" --ks-key-alias gensokyomod --ks-pass "file:$password_file" --out "$stage/signed.apk" "$stage/aligned.apk"
"$tools/apksigner" verify --verbose --print-certs "$stage/signed.apk" | tee "$stage/cert.txt"
test "$(awk '/Signer #1 certificate SHA-256 digest:/ {print $NF}' "$stage/cert.txt")" = "$expected"
rg -Fx 'Verified using v2 scheme (APK Signature Scheme v2): true' "$stage/cert.txt"
rg -Fx 'Verified using v3 scheme (APK Signature Scheme v3): true' "$stage/cert.txt"
"$tools/zipalign" -c -P 16 4 "$stage/signed.apk"
"$tools/aapt2" dump badging "$stage/signed.apk" > "$stage/badging.txt"
rg "^package: name='org\.selecter1302\.gensokyomod' versionCode='58'" "$stage/badging.txt"
python3 "$source_dir/tools/package.py" audit "$stage/signed.apk" --source "$source_dir" --version 58 --aligned
mv -n -- "$stage/signed.apk" "$output"
sha256sum "$output"
