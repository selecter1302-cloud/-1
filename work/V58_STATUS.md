# Narana v58 — unfinished release handoff (2026-11-19 KST)

**NOT A RELEASE. DO NOT INSTALL OVER v57.**

- Canonical baseline: `narana-v57-layout-20261117` @ `cc8fc8cf2c5eb91cf277593aadc4772baf128753`
- Original ZIP SHA256: `3f5cc8f872d7f9bf63a479adbc6de00c2819fdc73266fb4e9cee992e8aa19909`
- Original APK SHA256: `f250f70ca53c2a5d1740a348185309b44b8454e5c2c52d148b8135894a18081b`
- Original signer certificate SHA256, **verified via apksigner**: `52a1b6f90047314502c2160124f655c7add4d3aa8d7ecb05152b710d56434297`
- Five targeted script edits: `work/v58_patch.py` (rerunnable against v57)
- Unmodified .gdc compiled scripts present in input. Runtime precedence **not verified**.
- Full 2,890-entry sparse resource size/MD5 check passed on original APK and rebuilt unsigned staged APK.
- ZIP/native 16 KiB alignment validation passed.
- AndroidManifest.xml versionCode patched from 57 to 58, package retained.
- Validated `Narana-v58-UNSIGNED-not-for-install` GitHub Actions artifact: https://github.com/selecter1302-cloud/-1/actions/runs/44348511117/artifacts/14446623198
- SHA256 of **unsigned aligned staged APK**: `2fe8a8820f41c11bc5bc8df5ebab916eddd7de30eb32b04fc182169b6954a9e5`
- The unsigned artifact expires on 2026-11-19 16:34 UTC and is **not a signed, update-installable APK**.
- Verification job: https://github.com/selecter1302-cloud/-1/actions/runs/44347063249
- Staging job: https://github.com/selecter1302-cloud/-1/actions/runs/44348511117

**Blocking:** Prior `android-release.keystore` (alias `gensokyomod`) and `signing-password.txt` were not present in the current chat files. Cannot sign v58 or verify update-installability. Never invent/replace signing key. Neither are stored in Git.

**Outstanding:** Godot sparse-pack runtime behavior tests of both fixes, 2/3/4 visitors, expression persistence after restart, old compiled .gdc handling, Android install, apksigner verification of a **new signed** v58, separate release branch/ZIP LFS upload and remote verification. The two source fixes are hypotheses awaiting runtime validation, not a completed release. Do not assume all requested fixes are proven.

The original v57 release branch remains unchanged. The work branch is isolated.