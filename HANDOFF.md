# Narana v58 recovery

Goal: fix small face expression editing context and restore accepting all simultaneous visitors. Preserve saved games, presets, general-menu layout editor, and prior settings. Build an in-place update for org.selecter1302.gensokyomod with Godot 4.6.3 and the v57 signer.

Baseline: selecter1302-cloud/-1, narana-v57-layout-20261117, cc8fc8cf2c5eb91cf277593aadc4772baf128753.
LFS ZIP SHA-256: 3f5cc8f872d7f9bf63a479adbc6de00c2819fdc73266fb4e9cee992e8aa19909.
Expected APK SHA-256: f250f70ca53c2a5d1740a348185309b44b8454e5c2c52d148b8135894a18081b.
User-supplied split ZIP (.z01 through .z20 and .zip) is the build input. Assemble with zip -s 0, then extract and compare APK hashes. The baseline download URL returned HTTP 403 from this cloud proxy. Git HTTPS and Git LFS are available.
Signing inputs: supplied android-release.keystore, alias gensokyomod, and supplied signing-password.txt. Use apksigner file-based passwords. Keep both outside all Git checkouts. Expected certificate SHA-256: 52a1b6f90047314502c2160124f655c7add4d3aa8d7ecb05152b710d56434297.

Status: initial checkpoint. Split input retrieval in progress. Source changes, installation verification, signing, and release pending.
