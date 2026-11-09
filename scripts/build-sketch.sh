#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKETCH_DIR="${SKETCH_DIR:-$ROOT_DIR/examples/ProcessingSmokeTest}"
SKETCH_NAME="$(basename "$SKETCH_DIR")"
BUILD_DIR="$ROOT_DIR/.build/$SKETCH_NAME"
PUBLIC_DEMO_DIR="$ROOT_DIR/public/works/demo/v1"
PUBLIC_LIB_DIR="$ROOT_DIR/public/lib"

PROCESSING_JAVA="${PROCESSING_JAVA:-$(command -v processing-java || true)}"
PROCESSING_CORE_JAR="${PROCESSING_CORE_JAR:-}"

if [[ -z "$PROCESSING_JAVA" || ! -x "$PROCESSING_JAVA" ]]; then
  echo "ERROR: processing-java CLI was not found or is not executable." >&2
  echo "Install it from Processing > Tools > Install processing-java, or set PROCESSING_JAVA=/absolute/path/to/processing-java." >&2
  exit 1
fi

if [[ -z "$PROCESSING_CORE_JAR" || ! -f "$PROCESSING_CORE_JAR" ]]; then
  echo "ERROR: PROCESSING_CORE_JAR must point to the Processing Core JAR." >&2
  echo "Find it with: find /Applications/Processing.app -name 'core.jar' -o -name 'core-*.jar'" >&2
  exit 1
fi

if [[ ! -f "$SKETCH_DIR/$SKETCH_NAME.pde" ]]; then
  echo "ERROR: expected PDE file: $SKETCH_DIR/$SKETCH_NAME.pde" >&2
  echo "The sketch folder and primary .pde filename must match." >&2
  exit 1
fi

if ! command -v jar >/dev/null 2>&1; then
  echo "ERROR: JDK jar tool was not found. Install/configure JDK 17." >&2
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$PUBLIC_DEMO_DIR" "$PUBLIC_LIB_DIR"

# Processing CLI options must precede the final --build argument.
"$PROCESSING_JAVA" \
  --sketch="$SKETCH_DIR" \
  --output="$BUILD_DIR" \
  --force \
  --build

if ! find "$BUILD_DIR" -type f -name "$SKETCH_NAME.class" -print -quit | grep -q .; then
  echo "ERROR: expected $SKETCH_NAME.class was not found in $BUILD_DIR" >&2
  echo "Inspect Processing CLI output and adjust this script to its actual output layout." >&2
  find "$BUILD_DIR" -maxdepth 4 -type f -print >&2 || true
  exit 1
fi

rm -f "$PUBLIC_DEMO_DIR/$SKETCH_NAME.jar"
jar --create --file "$PUBLIC_DEMO_DIR/$SKETCH_NAME.jar" -C "$BUILD_DIR" .
cp "$PROCESSING_CORE_JAR" "$PUBLIC_LIB_DIR/processing-core.jar"

# Keep Processing's data folder at the same relative path as the sketch root.
rm -rf "$PUBLIC_DEMO_DIR/data"
if [[ -d "$SKETCH_DIR/data" ]]; then
  cp -R "$SKETCH_DIR/data" "$PUBLIC_DEMO_DIR/data"
fi

echo "Build complete."
echo "Sketch JAR: $PUBLIC_DEMO_DIR/$SKETCH_NAME.jar"
echo "Core JAR:   $PUBLIC_LIB_DIR/processing-core.jar"
echo "Data dir:   $PUBLIC_DEMO_DIR/data"
echo "Next: npm run serve"
