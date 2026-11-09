#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROCESSING_APP="${PROCESSING_457_APP:-$HOME/Applications/Processing-4.5.7/Processing.app}"
PROCESSING_CORE_JAR="${PROCESSING_CORE_JAR:-$PROCESSING_APP/Contents/app/resources/modes/java/mode/core-4.5.7.jar}"
PROCESSING_CLI="$ROOT_DIR/scripts/bin/processing-4.5.7"
PATCH_SOURCE="$ROOT_DIR/patches/processing-4.5.7/processing/awt/PSurfaceAWT.java"
LAUNCHER_SOURCE="$ROOT_DIR/examples/ProcessingWebLauncher.java"
LAUNCHER_BUILD_DIR="$ROOT_DIR/.build/ProcessingWebLauncher"

if [[ ! -f "$PROCESSING_CORE_JAR" ]]; then
  echo "ERROR: Processing 4.5.7 Core JAR was not found:" >&2
  echo "  $PROCESSING_CORE_JAR" >&2
  echo "Set PROCESSING_CORE_JAR to the actual core-4.5.7.jar path." >&2
  exit 1
fi
if [[ ! -f "$PATCH_SOURCE" ]]; then
  echo "ERROR: upstream PSurfaceAWT source not found: $PATCH_SOURCE" >&2
  echo "Fetch the pinned 4.5.7 source first; see docs/README in the migration kit." >&2
  exit 1
fi
if [[ ! -f "$LAUNCHER_SOURCE" ]]; then
  echo "ERROR: ProcessingWebLauncher source not found: $LAUNCHER_SOURCE" >&2
  exit 1
fi

JAR_BIN="${JAR:-$(command -v jar || true)}"
JAVAC_BIN="${JAVAC:-$(command -v javac || true)}"
if [[ -z "$JAR_BIN" || ! -x "$JAR_BIN" || -z "$JAVAC_BIN" || ! -x "$JAVAC_BIN" ]]; then
  echo "ERROR: JDK 17 javac and jar tools must be available on PATH." >&2
  exit 1
fi

if ! "$JAR_BIN" tf "$PROCESSING_CORE_JAR" | grep -q '^processing/core/PApplet.class$'; then
  echo "ERROR: selected JAR does not look like a Processing Core JAR: $PROCESSING_CORE_JAR" >&2
  exit 1
fi

export PROCESSING_CORE_JAR
export PROCESSING_CLI

python3 "$ROOT_DIR/scripts/apply-processing-awt-patch.py" "$PATCH_SOURCE"
"$ROOT_DIR/scripts/build-processing-awt-patch-4.5.7.sh"
"$ROOT_DIR/scripts/build-sketch-4.5.7.sh"

rm -rf "$LAUNCHER_BUILD_DIR"
mkdir -p "$LAUNCHER_BUILD_DIR"
"$JAVAC_BIN" --release 17 \
  -cp "$PROCESSING_CORE_JAR" \
  -d "$LAUNCHER_BUILD_DIR" \
  "$LAUNCHER_SOURCE"

mkdir -p "$ROOT_DIR/public"
rm -f "$ROOT_DIR/public/ProcessingWebLauncher-4.5.7.jar"
"$JAR_BIN" --create \
  --file "$ROOT_DIR/public/ProcessingWebLauncher-4.5.7.jar" \
  -C "$LAUNCHER_BUILD_DIR" .

printf '\nProcessing 4.5.7 runtime artifacts built.\n'
printf 'AWT patch: %s\n' "$ROOT_DIR/public/lib/processing-awt-patch-4.5.7.jar"
printf 'Core:      %s\n' "$ROOT_DIR/public/lib/processing-core-4.5.7.jar"
printf 'Sketch:    %s\n' "$ROOT_DIR/public/works/demo/v4.5.7/ProcessingSmokeTest.jar"
printf 'Launcher:  %s\n' "$ROOT_DIR/public/ProcessingWebLauncher-4.5.7.jar"
