#!/usr/bin/env sh
# Linux counterpart of build_recompiler.ps1: builds psxrecomp-game and the
# psxrecomp CLI from the VENDORED tree, so the codegen hash the emitter bakes
# matches the one the patched runtime stamps (see that script and NOTES.md).
#
# psxrecomp publishes no Linux CLI release, so build-cli also gets the helpers
# the Windows zip supplies (psxrecomp-game, psxrecomp-bios, psxrecomp-toml) and
# a framework/ link to the vendored tree: main_cli.cpp looks for both beside
# the executable.
#
# Set CC/CXX to pick a versioned compiler, e.g. CC=clang-21 CXX=clang++-21.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FRAMEWORK="$ROOT/Crash2Recomp/psxrecomp"
SRC="$FRAMEWORK/recompiler"
CC="${CC:-clang}"
CXX="${CXX:-clang++}"

# TRADEOFF: libstdc++ is linked dynamically; link it statically and check the
# imports, as build_recompiler.ps1 does, before these binaries ship to players.
build_targets() {
  dir=$1 chd=$2
  shift 2
  cmake -S "$SRC" -B "$dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release "-DPSXRECOMP_ENABLE_CHD=$chd" -DBUILD_TESTING=OFF \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX"
  cmake --build "$dir" --target "$@"
}

build_targets "$ROOT/build-recompiler" OFF psxrecomp-game
echo "codegen hash: $("$ROOT/build-recompiler/psxrecomp-game" --codegen-hash | head -n 1)"

build_targets "$ROOT/build-cli" ON psxrecomp psxrecomp-game psxrecomp-bios psxrecomp-toml
ln -sfn "$FRAMEWORK" "$ROOT/build-cli/framework"
echo "built: $ROOT/build-cli/psxrecomp"
