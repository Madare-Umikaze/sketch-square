#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROCESSING_CORE_JAR="${PROCESSING_CORE_JAR:-}"
PATCH_SOURCE="$ROOT_DIR/patches/processing-4.5.7/processing/awt/PSurfaceAWT.java"
BUILD_DIR="$ROOT_DIR/.build/processing-awt-patch-4.5.7"
OUTPUT_JAR="$ROOT_DIR/public/lib/processing-awt-patch-4.5.7.jar"

if [[ -z "$PROCESSING_CORE_JAR" || ! -f "$PROCESSING_CORE_JAR" ]]; then
  echo "ERROR: set PROCESSING_CORE_JAR to the Processing 4.5.7 Core JAR." >&2
  exit 1
fi

if [[ "$(basename "$PROCESSING_CORE_JAR")" != "core-4.5.7.jar" ]]; then
  echo "WARNING: expected a file named core-4.5.7.jar; got: $PROCESSING_CORE_JAR" >&2
  echo "Confirm that this is the Processing 4.5.7 Java Mode Core JAR." >&2
fi

if [[ ! -f "$PATCH_SOURCE" ]]; then
  echo "ERROR: patched PSurfaceAWT.java not found: $PATCH_SOURCE" >&2
  exit 1
fi

JAVAC_BIN="${JAVAC:-$(command -v javac || true)}"
JAR_BIN="${JAR:-$(command -v jar || true)}"
if [[ -z "$JAVAC_BIN" || ! -x "$JAVAC_BIN" ]]; then
  echo "ERROR: javac not found. Configure JDK 17 first." >&2
  exit 1
fi
if [[ -z "$JAR_BIN" || ! -x "$JAR_BIN" ]]; then
  echo "ERROR: jar tool not found. Configure JDK 17 first." >&2
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$(dirname "$OUTPUT_JAR")"

"$JAVAC_BIN" --release 17 \
  -cp "$PROCESSING_CORE_JAR" \
  -d "$BUILD_DIR" \
  "$PATCH_SOURCE"

rm -f "$OUTPUT_JAR"
"$JAR_BIN" --create --file "$OUTPUT_JAR" \
  -C "$BUILD_DIR" processing/awt

if ! "$JAR_BIN" tf "$OUTPUT_JAR" | grep -q '^processing/awt/PSurfaceAWT.class$'; then
  echo "ERROR: PSurfaceAWT.class was not found in the generated patch JAR." >&2
  exit 1
fi

printf 'Build complete.\nPatch JAR: %s\n' "$OUTPUT_JAR"
