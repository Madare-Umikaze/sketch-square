# MIGRATION — Processing 4.5.2 → 4.5.7

最終更新: 2026-11-10
状態: **ローカル移行とCheerpJブラウザSmoke Test完了。**

## 1. Processing 4.5.7の導入

Apple Silicon macOSで公式DMGを使用した。

- Official release: https://github.com/processing/processing4/releases/tag/processing-1435-4.5.7
- Asset: `processing-4.5.7-macos-aarch64.dmg`
- SHA-256: `27fb4bb8d5fb785c02cc6987649e215b224d49a3ad9ae7dbedc3a8ccf981cae9`
- App location: `$HOME/Applications/Processing-4.5.7/Processing.app`
- Keep 4.5.2 at `/Applications/Processing.app`; do not overwrite it.

## 2. Core JAR

Expected path:

`$HOME/Applications/Processing-4.5.7/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.7.jar`

Actual path must be verified locally:

```bash
find "$HOME/Applications/Processing-4.5.7/Processing.app/Contents" \
  -type f -name 'core-4.5.7.jar' -print
```

## 3. CLI差

4.5.3のmacOS CLI install script change is recorded in official release notes:

`Update install script to create 'processing' instead of 'processing-java' on macOS` (PR #1377).

4.5.7 project build uses a version-specific wrapper invoking the Processing app's CLI entrypoint. Do not replace the existing 4.5.2 global CLI alias.

## 4. Build artifact naming

4.5.2 artifacts remain under their existing names and paths. 4.5.7 uses versioned names:

- `public/lib/processing-awt-patch-4.5.7.jar`
- `public/lib/processing-core-4.5.7.jar`
- `public/ProcessingWebLauncher-4.5.7.jar`
- `public/works/demo/v4.5.7/ProcessingSmokeTest.jar`
- `public/works/demo/v4.5.7/data/sample.png`

## 5. Browser classpath

The patch must come first:

```js
const SKETCH_CLASSPATH = [
  "/app/lib/processing-awt-patch-4.5.7.jar",
  "/app/ProcessingWebLauncher-4.5.7.jar",
  "/app/works/demo/v4.5.7/ProcessingSmokeTest.jar",
  "/app/lib/processing-core-4.5.7.jar"
].join(":");
```

The runner passes the sketch path to `ProcessingWebLauncher`, which constructs the Processing `PApplet.main()` option array in the required order.

## 6. Result

The user reported the post-migration browser verification checklist fully passed: launch, window, draw loop, shapes/text, animation, `frameCount`, click count, image loading, and no relevant Console errors.

## 7. Rollback

To return to the 4.5.2 PoC, restore the previous `runner.js` constants/classpath and use the 4.5.2 JAR paths. Do not delete either version's JARs or app installation during testing.
