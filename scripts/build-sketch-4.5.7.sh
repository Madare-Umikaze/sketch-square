#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROCESSING_VERSION="4.5.7"
SKETCH_DIR="${SKETCH_DIR:-$ROOT_DIR/examples/ProcessingSmokeTest}"
SKETCH_NAME="$(basename "$SKETCH_DIR")"
BUILD_DIR="$ROOT_DIR/.build/$SKETCH_NAME"
PUBLIC_DEMO_DIR="$ROOT_DIR/public/works/demo/v4.5.7"
PUBLIC_LIB_DIR="$ROOT_DIR/public/lib"
PROCESSING_CLI="${PROCESSING_CLI:-$ROOT_DIR/scripts/bin/processing-4.5.7}"
PROCESSING_CORE_JAR="${PROCESSING_CORE_JAR:-}"

if [[ ! -x "$PROCESSING_CLI" ]]; then
  echo "ERROR: Processing 4.5.7 CLI wrapper is missing or not executable: $PROCESSING_CLI" >&2
  exit 1
fi
if [[ -z "$PROCESSING_CORE_JAR" || ! -f "$PROCESSING_CORE_JAR" ]]; then
  echo "ERROR: set PROCESSING_CORE_JAR to the Processing 4.5.7 Core JAR." >&2
  exit 1
fi
if [[ ! -f "$SKETCH_DIR/$SKETCH_NAME.pde" ]]; then
  echo "ERROR: expected PDE file: $SKETCH_DIR/$SKETCH_NAME.pde" >&2
  exit 1
fi
if ! command -v jar >/dev/null 2>&1; then
  echo "ERROR: JDK 17 jar tool was not found." >&2
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$PUBLIC_DEMO_DIR" "$PUBLIC_LIB_DIR"

"$PROCESSING_CLI" \
  --sketch="$SKETCH_DIR" \
  --output="$BUILD_DIR" \
  --force \
  --build

if ! find "$BUILD_DIR" -type f -name "$SKETCH_NAME.class" -print -quit | grep -q .; then
  echo "ERROR: expected $SKETCH_NAME.class was not found in $BUILD_DIR" >&2
  find "$BUILD_DIR" -maxdepth 4 -type f -print >&2 || true
  exit 1
fi

rm -f "$PUBLIC_DEMO_DIR/$SKETCH_NAME.jar"
jar --create --file "$PUBLIC_DEMO_DIR/$SKETCH_NAME.jar" -C "$BUILD_DIR" .

cp "$PROCESSING_CORE_JAR" "$PUBLIC_LIB_DIR/processing-core-$PROCESSING_VERSION.jar"

rm -rf "$PUBLIC_DEMO_DIR/data"
if [[ -d "$SKETCH_DIR/data" ]]; then
  cp -R "$SKETCH_DIR/data" "$PUBLIC_DEMO_DIR/data"
fi

printf 'Processing %s sketch build complete.\n' "$PROCESSING_VERSION"
printf 'Sketch JAR: %s\n' "$PUBLIC_DEMO_DIR/$SKETCH_NAME.jar"
printf 'Core JAR:   %s\n' "$PUBLIC_LIB_DIR/processing-core-$PROCESSING_VERSION.jar"
printf 'Data dir:   %s\n' "$PUBLIC_DEMO_DIR/data"
