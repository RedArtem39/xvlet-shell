#!/bin/bash
# every login scene from a folder of SVGs: tools/bake_scenes.sh DIR
# (sakura-katana-v2.svg -> scenes/sakura-katana, as bake_scene.py names them)
set -e
cd "$(dirname "$0")/.."
for f in "$1"/*.svg; do python3 tools/bake_scene.py "$f"; done
