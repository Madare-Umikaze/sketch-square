#!/usr/bin/env python3
"""Apply the known CheerpJ-compatible AWT paint patch to Processing 4.5.7 source."""
from __future__ import annotations

import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit(
        "Usage: python3 scripts/apply-processing-awt-patch.py "
        "patches/processing-4.5.7/processing/awt/PSurfaceAWT.java"
    )

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"ERROR: source file not found: {path}")

text = path.read_text(encoding="utf-8")

old_paint = """    @Override
    public void paint(Graphics screen) {
      render();
    }"""
new_paint = """    @Override
    public void paint(Graphics screen) {
      if (canvas.isDisplayable() && graphics.image != null) {
        screen.drawImage(
          graphics.image,
          0, 0, sketchWidth, sketchHeight, null
        );
      }
    }"""

if old_paint in text:
    text = text.replace(old_paint, new_paint, 1)
elif new_paint not in text:
    raise SystemExit(
        "ERROR: SmoothCanvas.paint() did not match the expected 4.5.7 source. "
        "No changes were written. Inspect the upstream source before patching."
    )

render_pattern = re.compile(
    r"(?ms)^  protected void render\(\) \{\n.*?^  \}\n"
)
render_matches = list(render_pattern.finditer(text))
new_render = """  protected void render() {
    if (canvas.isDisplayable() && graphics.image != null) {
      canvas.repaint();
    }
  }
"""

if len(render_matches) != 1:
    # Idempotent path: if already patched, the exact method should still exist.
    already_patched = re.findall(
        r"(?ms)^  protected void render\(\) \{\n"
        r"    if \(canvas\.isDisplayable\(\) && graphics\.image != null\) \{\n"
        r"      canvas\.repaint\(\);\n"
        r"    \}\n"
        r"  \}\n",
        text,
    )
    if len(already_patched) == 1 and len(render_matches) == 0:
        print(f"Patch already applied: {path}")
        raise SystemExit(0)
    raise SystemExit(
        f"ERROR: expected exactly one protected void render() method; found {len(render_matches)}. "
        "No changes were written."
    )

current_render = render_matches[0].group(0)
if "canvas.repaint();" in current_render and "getDrawGraphics()" not in current_render:
    print(f"Patch already applied: {path}")
    raise SystemExit(0)

text = text[:render_matches[0].start()] + new_render + text[render_matches[0].end():]
path.write_text(text, encoding="utf-8")
print(f"Applied CheerpJ AWT patch: {path}")
