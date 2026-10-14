#!/usr/bin/env sh
# Linux counterpart of build_clang.ps1: builds the generated project with clang,
# BOTH trees, from the system cmake/ninja.
#   build-clang       PSX_DEBUG_TOOLS=OFF - what the launcher runs
#   build-debugtools  PSX_DEBUG_TOOLS=ON  - TCP debug server for diagnostics
#
# Set CC/CXX to pick a versioned compiler, e.g. CC=clang-21 CXX=clang++-21.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT="$ROOT/Crash2Recomp"
CC="${CC:-clang}"
CXX="${CXX:-clang++}"

echo "clang     : $("$CC" --version | head -n 1)"
echo "cmake     : $(cmake --version | head -n 1)"

build_tree() {
  dir=$1 debug_tools=$2 label=$3
  printf '\n=== CONFIGURE [%s]  (PSX_DEBUG_TOOLS=%s) ===\n\n' "$label" "$debug_tools"
  cmake -S "$PROJECT" -B "$PROJECT/$dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DPSX_RECOMP_UI=OFF \
    "-DPSX_DEBUG_TOOLS=$debug_tools"
  printf '\n=== BUILD [%s] ===\n\n' "$label"
  cmake --build "$PROJECT/$dir" --parallel
  for exe in "$PROJECT/$dir"/*Recompiled; do
    if [ -f "$exe" ]; then
      echo "ARTIFACT [$label]: $exe"
    else
      echo "no *Recompiled binary in $PROJECT/$dir" >&2
      exit 1
    fi
  done
}

build_tree build-clang OFF release
build_tree build-debugtools ON debugtools
