# Narana v58 recovery

## Scope and recovery point

Fix the small face-window expression editor and restore accepting all simultaneous nighttime visitors. Preserve game saves, presets, unlocks, the group-layout editor in General settings, and custom preferences. Keep the existing Android package and signing certificate.

This branch, `narana-v58-recovery-20261119`, contains the six edited GDScripts, the split ZIP joiner, packaging/signing scripts, and sparse-pack integration tests. Baseline source for those scripts is in `4908737`. Source edits are in `7524f55` and `de491e0`. All other source and assets are recovered from the verified baseline APK and reused by the packaging script.

The face window resolves `doggy_window` independently of the donor pose. Its art and preview still use the configured source and crop. Existing rule identities and saved presets are preserved. Nighttime visit arrival filters and the later group-activity eligibility remain in their original paths. The room prompt can admit all present visitors, including a two-person prompt saved without the old clash receipt.

## Inputs

| Input | Location or identity | SHA-256 |
| --- | --- | --- |
| v57 release branch | `selecter1302-cloud/-1`, `narana-v57-layout-20261117`, `cc8fc8cf2c5eb91cf277593aadc4772baf128753` | LFS ZIP: `3f5cc8f872d7f9bf63a479adbc6de00c2819fdc73266fb4e9cee992e8aa19909` |
| v57 APK | Inside user-provided `Narana-0.14.7-v57.z01` through `.z20` and `.zip`, also in the release ZIP | `f250f70ca53c2a5d1740a348185309b44b8454e5c2c52d148b8135894a18081b` |
| Signed v58 APK | `/workspace/narana-work/final/Narana-0.14.7-v58.apk` | `42ad46d8a233ac8a2528060761991dea5041c208b9805543b17968450a00bf8f` |
| v58 release ZIP | `Narana-0.14.7-v58.zip`, 511901524 bytes | `4535ca778c6d71a8ab959e2bf8f93d6a8316498a1d851b24c57727257f8b5fe3` |

The attached split input was rejoined with `tools/join_split_zip.py`. Its member CRCs passed and the extracted APK matched the prescribed SHA-256 and independent Git LFS bytes. Info-ZIP's split conversion produced a truncated output for this specific archive.

Signing requires the supplied `android-release.keystore` and `signing-password.txt` via private attachment paths or a securely provisioned file binding. Use alias `gensokyomod`. The expected v57, keystore, and v58 certificate SHA-256 is `52a1b6f90047314502c2160124f655c7add4d3aa8d7ecb05152b710d56434297`. Environment status showed no saved signing bindings. Signing inputs and game saves stay outside Git; the scripts consume the password via a file reference.

## Restore and verify

Use the existing checkout in the isolated workspace when present. Use a separate clone only for verification or if the checkout is missing. From the recovery checkout, use Python 3.11+, a JDK with keytool, Git plus Git LFS, UnZip, ripgrep, and Godot 4.6.3. The installer downloads Android Build Tools 35.0.0 from Google and checks the published archive checksum.

```bash
bash tools/install_build_tools.sh /workspace/narana-work/tools
python3 tools/join_split_zip.py /path/to/split/Narana-0.14.7-v57.zip /workspace/narana-work/restored-v57.zip
unzip -jo /workspace/narana-work/restored-v57.zip '*.apk' -d /workspace/narana-work/restored-input
```

If the split set is unavailable, restore the baseline from Git LFS.

```bash
GIT_LFS_SKIP_SMUDGE=1 git clone --single-branch -b narana-v57-layout-20261117 https://github.com/selecter1302-cloud/-1.git /workspace/narana-base
git -C /workspace/narana-base lfs install --local
git -C /workspace/narana-base lfs pull
(cd /workspace/narana-base && sha256sum -c SHA256SUMS.txt)
unzip -jo /workspace/narana-base/Narana-0.14.7-layout-v57.zip '*.apk' -d /workspace/narana-work/restored-input
```

Set `NARANA_KEYSTORE_FILE` and `NARANA_SIGNING_PASSWORD_FILE` to private paths. Run from the source checkout with a new output path and a new test-run directory.

```bash
bash tools/build_release.sh /workspace/narana-work/restored-input/Narana-0.14.7-layout-v57.apk /workspace/narana-work/tools/android-15 "$NARANA_KEYSTORE_FILE" "$NARANA_SIGNING_PASSWORD_FILE" /workspace/narana-work/rebuilt-v58.apk
bash tools/test_sparse.sh /workspace/narana-work/rebuilt-v58.apk /workspace/narana-work/rebuilt-check
```

The build replaces the six scripts, drops their stale compiled counterparts, and rebuilds the sparse directory. The audit checks all 2,884 entries, APK Asset membership, size and MD5/CRC, and source bytes. `apksigner` v2/v3 verification, `zipalign`, arm64 ZIP and ELF 16 KiB alignment, and app identity checks passed. Native ARM64 libraries are stored and aligned; the original Android native extraction setting stays intact. The same optional themed-icon warning appears on both the v57 and v58 manifest inspections.

Godot on Linux loads the actual signed APK's sparse pack with the APK assets as backing files. The signed main run passed 98 assertions, including expression capture/save and actual texture, separate presets, long-press preview and copy, 2/3/4 visitor actions and subsequent progression, menu layout, 3/4-person layouts and swaps, and save loading. This is a headless functional run. Android device/emulator installation has not been run in this environment.

## Release and final verification

The separate-process signed sparse run passed 10 more assertions. It verified the saved small-window expression, other branches, saved layout, and the user-modified faint/cut-in options after restart. A separate clone of source checkpoint `1610e519982908305773536fdfc074bc6c298f52` installed the checked Android tools and reproduced the exact signed APK SHA-256.

The GitHub release branch is `narana-v58-fixes-20261119`, commit `e61f14ea58a39455df54218905a738c93462b6dc`. Git LFS uploaded the complete ZIP. An independently initialized, empty Git repository fetched the release ref and downloaded the actual 511901524-byte LFS object. Its ZIP and nested APK SHA-256 values matched and `git lfs fsck` passed. The v57 remote branch still points to its original commit.

Direct URL: https://media.githubusercontent.com/media/selecter1302-cloud/-1/refs/heads/narana-v58-fixes-20261119/Narana-0.14.7-v58.zip

The cloud proxy returned CONNECT 403 on this direct URL. The verified cloud workspace APK copy is `/workspace/shared/downloads/Narana-0.14.7-v58.apk`. The environment's install script and start instructions were saved to the configuration draft. Publication and new-environment restoration are separate from the tested clean source clone.
