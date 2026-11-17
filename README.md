# Narana edition v57 — group layout editor

Download and extract `Narana-0.14.7-layout-v57.zip`, then install the APK over the existing Narana edition. Do not uninstall the existing application.

- Package: `org.selecter1302.gensokyomod`
- versionCode: 57 (input: 56)
- Menu: Settings → General → immediately below main screen appearance → 다함께 안기 배치 편집
- Separate 3/4-person, character and seat preferences; drag, numeric X/Y/scale, save/cancel and resets.
- Layout preferences use a separate app preference file, independent of game saves.
- Original save, unlock, expression preset and v56 migration code retained byte-for-byte.
- Input APK, supplied signing key and output certificate SHA-256: `52a1b6f90047314502c2160124f655c7add4d3aa8d7ecb05152b710d56434297`.

Validation: Godot 4.6.3 loading the APK sparse resource pack; 26 functional assertions passed plus separate process restart persistence. Covered settings menu entry/order, drag/numeric transforms, save/cancel/resets, 3/4-person separation and game rendering, shadows, exchange marker/alpha hit tests, partner exchange, other save loading, three-column expression picker and preset preview/copy condition preservation. All 2,890 sparse resource entries checked against actual APK byte lengths and MD5; full resource membership checked. apksigner v2/v3 and zipalign checks passed; stored native libraries also checked for 16 KiB alignment.

No Android physical-device or emulator installation test was performed. Automated Godot checks do not replace physical-device validation. Signing credentials and game saves are not included.
